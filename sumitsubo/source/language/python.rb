require "sumitsubo/error"
require "sumitsubo/source"
require "sumitsubo/source/language/nodes"

module Sumitsubo
  module Source
    class Language
      # Python, read through the grammar this build links in.
      #
      # A name is the dotted path the scopes holding it spell, `Charge.settle`
      # for a method and `Outer.Inner.deep` for a class inside a class, which is
      # what Sphinx writes. Nothing marks a method as belonging to the class
      # rather than to an instance of it: Python spells neither, and a sigil
      # invented here would be this reading deciding for the language.
      #
      # The grammar is handed in rather than reached for: what a build carries is
      # decided at its edge, and a reading that named one would be a second
      # place saying so.
      #
      # A caller reaches this through the seam rather than by name, so nothing
      # here requires its way back up to it — only a build, saying what it
      # carries, writes the name.
      class Python
        # What the binding knows this grammar by. It travels with the queries,
        # since they are written against its node names and no two grammars
        # spell a node alike.
        GRAMMAR = "python"

        # Python writes a comment one way and has no block form, so nothing has
        # to be trimmed off the end. A docstring is a string the language
        # evaluates rather than a comment, and this reading does not answer it.
        COMMENTS = <<~COMMENTS
          (comment) @#{Nodes::FOUND}
          ((comment) @#{Nodes::BEFORE} . (_) @#{Nodes::BESIDE})
        COMMENTS

        SCOPE = "scope"

        # The function a parameter belongs to, and the captures that qualify
        # one: the name where the parameter carries it in a node of its own,
        # and the default that makes it optional.
        OF = "of"
        NAMED = "named"
        DEFAULT = "default"

        # The two separators. They name no parameter of their own — what they
        # say is about the parameters around them — so they are read as marks
        # rather than built into anything.
        BEFORE = "before"
        AFTER = "after"

        # Kinds a caller may always leave out: a splat gathers whatever is
        # there and a double splat whatever is named. A keyword parameter with
        # no default still has to arrive, as in Ruby.
        OMISSIBLE = ["splat", "hash_splat"]

        SPLAT = "splat"
        KEYWORD = "keyword"
        POSITIONAL_ONLY = "positional_only"

        # An annotation and a default each wrap the parameter in a node of its
        # own, so the four spellings of a plain parameter are asked for
        # separately and answer under one kind.
        PARAMETERS = <<~PARAMETERS
          [(identifier) @positional
           (default_parameter name: (_) @named value: (_) @default) @positional
           (typed_parameter (identifier) @named) @positional
           (typed_default_parameter name: (_) @named value: (_) @default) @positional
           (list_splat_pattern (identifier) @named) @splat
           (dictionary_splat_pattern (identifier) @named) @hash_splat
           (keyword_separator) @after
           (positional_separator) @before]*
        PARAMETERS

        QUERY = <<~QUERY
          (class_definition name: (_) @name) @scope
          (function_definition name: (_) @name) @item
          (function_definition name: (_) @of parameters: (parameters #{PARAMETERS}))
        QUERY

        def initialize(grammar)
          @grammar = grammar
        end

        def named?(name)
          name == GRAMMAR
        end

        def reads?(path)
          path.extname == ".py"
        end

        def comments_in(path, where)
          captures = captured(path.read, COMMENTS, where)
          following = Nodes.following(Nodes.matches_in(captures))
          found = []
          captures.each do |capture|
            next unless capture.name == Nodes::FOUND

            found.push(Source::Region.new(capture.line, capture.text, following[capture.start]))
          end
          found
        end

        def declarations_in(path, where)
          declarations_of(path.read, where)
        end

        # The same reading of a piece of text that was never a file, which is what
        # a specification registering a contract writes its declaration in.
        def declarations_of(source, where)
          matches = Nodes.matches_in(captured(source, QUERY, where))
          nodes = sorted(Nodes.nodes_in(matches))
          taken = params_in(matches)

          scopes = []
          nodes.each { |node| scopes.push(node) if node.kind == SCOPE }

          found = []
          nodes.each do |node|
            found.push(Source::Declaration.new(
              where, node.first, qualified(scopes, node), shape_for(taken, node)
            ))
          end
          found
        end

        private

        def captured(source, query, where)
          @grammar.captures_of(GRAMMAR, source, query, where)
        rescue TreeSitter::ParseError => e
          # Source the grammar cannot read is not a difference between the two
          # sides either: half a file yields regions the rest of it never made.
          raise Error, e.message
        end

        # A reading answers in the order the parser met the nodes; a path is
        # built from what encloses one, so the scopes have to be in file order.
        def sorted(nodes)
          nodes.sort_by { |node| node.first }
        end

        # The name a contract would have to write to reach this declaration:
        # the scopes holding it, dotted, and its own name last.
        def qualified(scopes, node)
          path = Nodes.enclosing(scopes, node).map { |scope| scope.text }
          path.push(node.text)
          path.join(".")
        end

        def params_in(matches)
          found = {}
          groups = Nodes.grouped_by(matches, OF)
          groups.keys.each { |key| found[key] = params_from(groups[key]) }
          found
        end

        # The parameters one function takes. Python's separators say what the
        # parameters around them are rather than naming one of their own —
        # everything before a `/` may only be passed by position, everything
        # after a `*` only by keyword — so which one a parameter is cannot be
        # read off the parameter, and the group is walked in the order the
        # source wrote it. A splat closes the same door a bare `*` does.
        def params_from(group)
          found = []
          keyword = false
          group.each do |captures|
            kind = kind_of(captures)
            next if kind.nil?

            if kind == BEFORE
              found = only_positional(found)
            elsif kind == AFTER
              keyword = true
            else
              found.push(param_from(captures, kind, keyword))
              keyword = true if kind == SPLAT
            end
          end
          found
        end

        # What kind of node the parameter was, which is whichever capture is
        # not one of the three that qualify it.
        def kind_of(captures)
          found = nil
          captures.each do |capture|
            next if capture.name == OF || capture.name == NAMED || capture.name == DEFAULT

            found = capture.name
          end
          found
        end

        # What a caller has to write for this parameter. A plain one is its own
        # name; every other spelling wraps it, and carries the name in a capture
        # of its own.
        def param_from(captures, kind, keyword)
          named = Nodes.capture_of(captures, NAMED)
          name = named.nil? ? Nodes.capture_of(captures, kind).text : named.text
          defaulted = !Nodes.capture_of(captures, DEFAULT).nil?
          said = keyword && kind == Source::Param::POSITIONAL ? KEYWORD : kind
          Source::Param.new(name, said, defaulted || OMISSIBLE.include?(kind))
        end

        # What a `/` says about everything written before it. It is answered by
        # rebuilding rather than by holding the kind open, so a parameter is
        # built once and the mark is what revises it.
        def only_positional(taken)
          found = []
          taken.each do |param|
            found.push(Source::Param.new(param.name, POSITIONAL_ONLY, param.optional))
          end
          found
        end

        # A class takes no parameters at all, which is not the same as a
        # function that takes none.
        def shape_for(taken, node)
          return nil if node.kind == SCOPE

          found = taken[Nodes.owner_of(node.first, node.text)]
          Source::Shape.new(params: found.nil? ? [] : found)
        end
      end
    end
  end
end
