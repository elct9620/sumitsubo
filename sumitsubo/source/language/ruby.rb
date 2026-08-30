require "sumitsubo/error"
require "sumitsubo/source"
require "sumitsubo/grammar"
require "sumitsubo/source/language/nodes"

module Sumitsubo
  module Source
    module Language
      # Ruby, read through the grammar this build links in. The queries live here
      # rather than beside the registration because they are written against one
      # grammar's node names: another language answers with its own.
      #
      # Reached through `language.rb`, which holds the seam and the shapes a
      # reading answers with, so nothing here requires its way back up.
      class Ruby
        # Comments are the part of a source file a person wrote for another
        # person, which is where a concept is called by name rather than spelled
        # as an identifier.
        COMMENTS = "(comment) @text"

        # A comment with something after it. A behavior is claimed in front of
        # the code that implements it, so a comment nothing follows claims
        # nothing. The anchor only excludes that orphan: a comment followed by
        # another comment is still a match, which is as far as this needs to
        # reach.
        ATTACHED = "((comment) @text . (_))"

        SCOPE = "scope"
        SINGLETON = "singleton"
        # `class << self` holds methods that belong to the class rather than to
        # an instance of it. It contributes no name of its own — what it changes
        # is how the methods inside it are spelled.
        REOPENED = "reopened"

        # The method a parameter belongs to, and the two captures that qualify
        # one: the name where Ruby gave it one, and the default that makes it
        # optional.
        OF = "of"
        NAMED = "named"
        DEFAULT = "default"

        # Kinds a caller may always leave out: a splat gathers whatever is there,
        # a block is passed or not, and forwarding says nothing about what has to
        # arrive. Optionality is a fact about the call rather than about how Ruby
        # spells the definition, which is why these carry it without a default.
        OMISSIBLE = ["splat", "hash_splat", "block", "forward"]

        # `**nil` declares that no keyword argument is accepted rather than
        # naming a parameter, so nothing below reaches it and a method carrying
        # one answers only the parameters it takes.
        PARAMETERS = <<~PARAMETERS
          [(identifier) @positional
           (optional_parameter name: (_) @named value: (_) @default) @positional
           (keyword_parameter name: (_) @named value: (_)? @default) @keyword
           (splat_parameter name: (_)? @named) @splat
           (hash_splat_parameter name: (_)? @named) @hash_splat
           (block_parameter name: (_)? @named) @block
           (destructured_parameter) @destructured
           (forward_parameter) @forward]*
        PARAMETERS

        # A constant assigned a call that carries a block is a scope of its own:
        # `Data.define` and `Struct.new` write a class body that way, and what
        # sits inside it belongs to the constant rather than to the module
        # around it. Which call it is goes unasked, since a rule naming three of
        # them would miss the fourth.
        #
        # The quantifier sits on the alternation while its branches carry none,
        # so tree-sitter answers one match per parameter rather than one match
        # whose captures vary in number. Each names the method it belongs to.
        QUERY = <<~QUERY
          (module name: (_) @name) @scope
          (class name: (_) @name) @scope
          (assignment left: [(constant) @name (scope_resolution) @name]
            right: (call block: (_))) @scope
          (method name: (_) @name) @instance
          (singleton_method object: (self) name: (_) @name) @singleton
          (singleton_class value: (self) @name) @reopened
          (method name: (_) @of parameters: (method_parameters #{PARAMETERS}))
          (singleton_method object: (self) name: (_) @of
            parameters: (method_parameters #{PARAMETERS}))
        QUERY

        # What a specification calls this language when it names one.
        def named?(name)
          name == Grammar::RUBY
        end

        def reads?(path)
          path.extname == ".rb"
        end

        # What a person wrote for another person is the comments and nothing
        # else. An identifier is a spelling of a concept rather than the
        # concept's name, so counting one would answer for every legitimate
        # class in the tree.
        def comments_in(path, where)
          captured(path.read, COMMENTS, where).map do |capture|
            Source::Region.new(capture.line, capture.text)
          end
        end

        # The comments with code after them. A claim sits in front of what
        # implements it, so a comment nothing follows claims nothing.
        def attached_comments_in(path, where)
          captured(path.read, ATTACHED, where).map do |capture|
            Source::Region.new(capture.line, capture.text)
          end
        end

        # The names this file declares and the shape each is reached by, spelled
        # the way Ruby spells them: `Sumitsubo::Place.of` for a singleton method,
        # `#` for an instance one, the bare path for a class or module.
        def declarations_in(path, where)
          declarations_of(path.read, where)
        end

        # The same reading of a piece of text that was never a file. A
        # specification registering a contract writes the declaration it means,
        # and what it registers is then whatever this answers — so the names a
        # specification can spell are exactly the names this can find.
        def declarations_of(source, where)
          matches = Nodes.matches_in(captured(source, QUERY, where))
          nodes = Nodes.nodes_in(matches)
          taken = params_in(matches)

          scopes = []
          reopened = []
          nodes.each do |node|
            scopes.push(node) if node.kind == SCOPE
            reopened.push(node) if node.kind == REOPENED
          end

          found = []
          nodes.each do |node|
            next if node.kind == REOPENED

            found.push(Source::Declaration.new(
              where, node.first, qualified(scopes, reopened, node), shape_for(taken, node)
            ))
          end
          found
        end

        private

        def captured(source, query, where)
          Grammar.captures_of(Grammar::RUBY, source, query, where)
        rescue TreeSitter::ParseError => e
          # Source the grammar cannot read is not a difference between the two
          # sides either: half a file yields regions the rest of it never made.
          raise Error, e.message
        end

        # The name a contract would have to use to reach this node, its enclosing
        # scopes included.
        def qualified(scopes, reopened, node)
          holding = Nodes.enclosing(scopes, node).map { |scope| scope.text }
          return holding.push(node.text).join("::") if node.kind == SCOPE
          # A definition outside every scope is reached by its bare name: there
          # is no path to put in front of it.
          return node.text if holding.empty?

          "#{holding.join("::")}#{singleton?(reopened, node) ? "." : "#"}#{node.text}"
        end

        # Whether the method belongs to the class rather than to an instance of
        # it, by how it was written or by sitting inside a `class << self`.
        def singleton?(reopened, node)
          return true if node.kind == SINGLETON

          inside = false
          reopened.each do |scope|
            inside = true if scope.first <= node.first && node.last <= scope.last
          end
          inside
        end

        # The parameters each method takes, in the order the source wrote them,
        # kept under the method they belong to.
        def params_in(matches)
          found = {}
          matches.each do |captures|
            of = named(captures, OF)
            next if of.nil?

            key = owner(of.line, of.text)
            holding = found[key]
            if holding.nil?
              holding = []
              found[key] = holding
            end
            param = param_from(captures)
            holding.push(param) unless param.nil?
          end
          found
        end

        # What a caller has to write for this parameter. A plain one is its own
        # name; every other kind carries the name in a capture of its own, or
        # goes unnamed where Ruby allows it.
        #
        # The guard on that fallback is what makes it hold either way round: a
        # parameter with a default is captured both as a kind and by name, and
        # the two arrive in node position rather than in the order they are
        # written above.
        def param_from(captures)
          kind = nil
          name = nil
          defaulted = false
          captures.each do |capture|
            next if capture.name == OF

            if capture.name == NAMED
              name = capture.text
            elsif capture.name == DEFAULT
              defaulted = true
            else
              kind = capture.name
              name = capture.text if capture.name == Source::Param::POSITIONAL && name.nil?
            end
          end
          return nil if kind.nil?

          Source::Param.new(name, kind, defaulted || OMISSIBLE.include?(kind))
        end

        # What a declaration answers for its parameters: none at all for a scope,
        # and the list for a method, which is empty where it takes nothing.
        def shape_for(taken, node)
          return nil if node.kind == SCOPE

          found = taken[owner(node.first, node.text)]
          Source::Shape.new(params: found.nil? ? [] : found)
        end

        # A method's name sits on the same line as `def`, so the line and the
        # name together are what tell two methods apart at the resolution the
        # captures carry. One line holding two of a name is below that
        # resolution, and their parameters merge — the one place this reading
        # invents rather than loses.
        def owner(line, name)
          "#{line}\t#{name}"
        end

        def named(captures, name)
          found = nil
          captures.each { |capture| found = capture if capture.name == name }
          found
        end
      end
    end
  end
end
