require "sumitsubo/error"
require "sumitsubo/source"
require "sumitsubo/source/language/nodes"

module Sumitsubo
  module Source
    class Language
      # TypeScript with JSX, read through the second grammar that repository
      # ships. A `.tsx` file is not the language the one beside it parses:
      # `<Charge />` is a comparison there, so which of the two reads a file is
      # decided by its name and cannot be guessed from what it holds.
      #
      # What it declares is spelled as TypeScript spells it, since it is
      # TypeScript — the same TypeDoc reference, `Charge#settle` through a
      # value and `Charge.open` through the class. What differs is the grammar
      # underneath, which is why this is a reading of its own rather than an
      # extension the one beside it claims.
      #
      # The grammar is handed in rather than reached for: what a build carries is
      # decided at its edge, and a reading that named one would be a second
      # place saying so.
      #
      # A caller reaches this through the seam rather than by name, so nothing
      # here requires its way back up to it — only a build, saying what it
      # carries, writes the name.
      class Tsx
        # What the binding knows this grammar by. It travels with the queries,
        # since they are written against its node names and no two grammars
        # spell a node alike.
        GRAMMAR = "tsx"

        COMMENTS = <<~COMMENTS
          (comment) @#{Nodes::FOUND}
          ((comment) @#{Nodes::BEFORE} . (_) @#{Nodes::BESIDE})
        COMMENTS

        # A block comment ends with the delimiter the language required rather
        # than with something a person wrote. TypeScript spells both kinds with
        # one node, so the delimiter comes off the text and taking it off a
        # line comment is a no-op.
        CLOSE = "*/"

        SCOPE = "scope"
        MEMBER = "member"
        ON = "on"

        OF = "of"
        NAMED = "named"
        DEFAULT = "default"

        # A rest parameter gathers whatever is there, and a `?` says outright
        # that a caller may leave one out — the only language here that writes
        # optionality on the parameter rather than leaving it to a default.
        OMISSIBLE = ["rest"]
        OPTIONAL = "optional"

        # A rest parameter is a required parameter holding a rest pattern, so
        # the two are asked for separately: one pattern reaching both would
        # answer the same parameter twice, once under each name.
        PARAMETERS = <<~PARAMETERS
          [(required_parameter pattern: (identifier) @named) @positional
           (required_parameter pattern: (identifier) @named value: (_) @default) @positional
           (required_parameter pattern: (rest_pattern (identifier) @named)) @rest
           (required_parameter pattern: [(object_pattern) (array_pattern)]) @destructured
           (optional_parameter pattern: (identifier) @named) @optional]*
        PARAMETERS

        # An abstract class is a node of its own rather than a class carrying a
        # word, so a query asking only for `class_declaration` passes one over
        # without saying it did.
        QUERY = <<~QUERY
          (class_declaration name: (_) @name) @scope
          (abstract_class_declaration name: (_) @name) @scope
          (interface_declaration name: (_) @name) @scope
          (enum_declaration name: (_) @name) @scope
          (internal_module name: (_) @name) @scope
          (type_alias_declaration name: (_) @name) @item
          (function_declaration name: (_) @name) @item
          (function_signature name: (_) @name) @item
          (class_body (method_definition name: (_) @name) @member)
          (class_body (method_definition "static" name: (_) @on))
          (method_signature name: (_) @name) @member
          (abstract_method_signature name: (_) @name) @member
          (variable_declarator name: (identifier) @name
            value: [(arrow_function) (function_expression)]) @item

          (function_declaration name: (_) @of
            parameters: (formal_parameters #{PARAMETERS}))
          (function_signature name: (_) @of
            parameters: (formal_parameters #{PARAMETERS}))
          (method_definition name: (_) @of
            parameters: (formal_parameters #{PARAMETERS}))
          (method_signature name: (_) @of
            parameters: (formal_parameters #{PARAMETERS}))
          (abstract_method_signature name: (_) @of
            parameters: (formal_parameters #{PARAMETERS}))
          (variable_declarator name: (identifier) @of
            value: [(arrow_function parameters: (formal_parameters #{PARAMETERS}))
                    (function_expression parameters: (formal_parameters #{PARAMETERS}))])
        QUERY

        def initialize(grammar)
          @grammar = grammar
        end

        def named?(name)
          name == GRAMMAR
        end

        def reads?(path)
          path.extname == ".tsx"
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
        # built from what encloses one, so the scopes have to be in file order.
        def sorted(nodes)
          nodes.sort_by { |node| node.first }
        end

        # The name a contract would have to write to reach this declaration.
        # A member takes the mark TypeDoc gives it — `.` where the class holds
        # it and `#` where a value does — and everything else answers under the
        # scopes holding it, which is how a namespace puts its name in front.
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

        # The parameters one declaration takes. A match that qualifies it
        # without naming a parameter — an empty list is written that way —
        # contributes nothing, which is not the same as taking none.
        def params_from(group)
          found = []
          group.each do |captures|
            param = param_from(captures)
            found.push(param) unless param.nil?
          end
          found
        end

        # What a caller has to write for this parameter. A `?` is the kind the
        # grammar answers with, and what it says is about the call rather than
        # about the parameter's shape, so it answers as a plain one a caller
        # may leave out.
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
            end
          end
          return nil if kind.nil?
          return Source::Param.new(name, Source::Param::POSITIONAL, true) if kind == OPTIONAL

          Source::Param.new(name, kind, defaulted || OMISSIBLE.include?(kind))
        end

        # A scope takes no parameters at all, which is not the same as a
        # declaration that takes none.
        def shape_for(taken, node)
          return nil if node.kind == SCOPE

          found = taken[Nodes.owner_of(node.first, node.text)]
          Source::Shape.new(params: found.nil? ? [] : found)
        end
      end
    end
  end
end
