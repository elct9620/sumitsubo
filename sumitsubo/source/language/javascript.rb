require "sumitsubo/error"
require "sumitsubo/source"
require "sumitsubo/source/language/nodes"

module Sumitsubo
  module Source
    class Language
      # JavaScript, read through the grammar this build links in.
      #
      # A name is the JSDoc namepath: `Charge#settle` for a method reached
      # through a value, `Charge.open` for one reached through the class, and
      # the bare name for whatever the module declares directly. The grammar
      # says which of the two a method is — `static` is a node a query can ask
      # for — and the mark that writes it down comes from the convention.
      #
      # The grammar is handed in rather than reached for: what a build carries is
      # decided at its edge, and a reading that named one would be a second
      # place saying so.
      #
      # A caller reaches this through the seam rather than by name, so nothing
      # here requires its way back up to it — only a build, saying what it
      # carries, writes the name.
      class Javascript
        # What the binding knows this grammar by. It travels with the queries,
        # since they are written against its node names and no two grammars
        # spell a node alike.
        GRAMMAR = "javascript"

        # What Ruby spells with one node this splits into two, and a JSDoc
        # comment is a block comment carrying a marker. The block one is asked
        # for its closing delimiter as well: where a person stopped writing is
        # the tree's to answer here, unlike in Go.
        COMMENTS = <<~COMMENTS
          (comment) @#{Nodes::FOUND}
          ((comment) @#{Nodes::BEFORE} . (_) @#{Nodes::BESIDE})
        COMMENTS

        # A block comment ends with the delimiter the language required rather
        # than with something a person wrote. JavaScript spells both kinds with
        # one node, as Go does, so the delimiter comes off the text and taking
        # it off a line comment is a no-op.
        CLOSE = "*/"

        SCOPE = "scope"
        MEMBER = "member"

        # Which of the two marks a member takes. `static` is a node of the
        # method rather than something about its name, so it is asked for in a
        # pattern of its own — one match carrying both would leave what kind of
        # node it was to whichever capture the parser met last.
        ON = "on"

        # The function a parameter belongs to, and the captures that qualify
        # one: the name where the parameter carries it in a node of its own,
        # and the default that makes it optional.
        OF = "of"
        NAMED = "named"
        DEFAULT = "default"

        # Kinds a caller may always leave out: a rest parameter gathers
        # whatever is there.
        OMISSIBLE = ["rest"]

        PARAMETERS = <<~PARAMETERS
          [(identifier) @positional
           (assignment_pattern left: (_) @named right: (_) @default) @positional
           (rest_pattern (_) @named) @rest
           (object_pattern) @destructured
           (array_pattern) @destructured]*
        PARAMETERS

        # A function reaches a name four ways, and only the first two carry one
        # of their own. `const f = () => {}` is how a module writes most of its
        # functions, so the name it is assigned to is the name it declares —
        # which is also what keeps a callback out: an arrow nobody assigned
        # matches none of these.
        QUERY = <<~QUERY
          (class_declaration name: (_) @name) @scope
          (function_declaration name: (_) @name) @item
          (class_body (method_definition name: (_) @name) @member)
          (class_body (method_definition "static" name: (_) @on))
          (variable_declarator name: (identifier) @name
            value: [(arrow_function) (function_expression)]) @item

          (function_declaration name: (_) @of
            parameters: (formal_parameters #{PARAMETERS}))
          (class_body (method_definition name: (_) @of
            parameters: (formal_parameters #{PARAMETERS})))
          (variable_declarator name: (identifier) @of
            value: [(arrow_function parameters: (formal_parameters #{PARAMETERS}))
                    (function_expression parameters: (formal_parameters #{PARAMETERS}))])
          (variable_declarator name: (identifier) @of
            value: (arrow_function parameter: (identifier) @positional))
        QUERY

        def initialize(grammar)
          @grammar = grammar
        end

        def named?(name)
          name == GRAMMAR
        end

        def reads?(path)
          [".js", ".jsx", ".mjs", ".cjs"].include?(path.extname)
        end

        def comments_in(path, where)
          captures = captured(path.read, COMMENTS, where)
          following = Nodes.following(Nodes.matches_in(captures))
          found = []
          captures.each do |capture|
            next unless capture.name == Nodes::FOUND

            found.push(Source::Region.new(
              capture.line, capture.text.delete_suffix(CLOSE), following[capture.start]
            ))
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
          statics = Nodes.grouped_by(matches, ON)

          scopes = []
          nodes.each { |node| scopes.push(node) if node.kind == SCOPE }

          found = []
          nodes.each do |node|
            found.push(Source::Declaration.new(
              where, node.first, qualified(scopes, statics, node), shape_for(taken, node)
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
        # built from what encloses one, so the classes have to be in file order.
        def sorted(nodes)
          nodes.sort_by { |node| node.first }
        end

        # The name a contract would have to write to reach this declaration.
        # A member takes the mark JSDoc gives it — `.` where the class holds it
        # and `#` where a value does — and everything else answers under the
        # scopes holding it.
        def qualified(scopes, statics, node)
          path = Nodes.enclosing(scopes, node).map { |scope| scope.text }
          return node.text if path.empty?
          return "#{path.join(".")}#{mark(statics, node)}#{node.text}" if node.kind == MEMBER

          path.push(node.text)
          path.join(".")
        end

        def mark(statics, node)
          statics[Nodes.owner_of(node.first, node.text)].nil? ? "#" : "."
        end

        def params_in(matches)
          found = {}
          groups = Nodes.grouped_by(matches, OF)
          groups.keys.each { |key| found[key] = params_from(groups[key]) }
          found
        end

        # The parameters one function takes. A match that qualifies it without
        # naming a parameter — an empty list is written that way — contributes
        # nothing, which is not the same as the function taking none.
        def params_from(group)
          found = []
          group.each do |captures|
            param = param_from(captures)
            found.push(param) unless param.nil?
          end
          found
        end

        # What a caller has to write for this parameter. A plain one is its own
        # name; a default and a rest each wrap it, and a destructured one takes
        # its parts apart without giving the whole a name.
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
