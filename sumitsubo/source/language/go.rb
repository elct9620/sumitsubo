require "sumitsubo/error"
require "sumitsubo/source"
require "sumitsubo/source/language/nodes"

module Sumitsubo
  module Source
    class Language
      # Go, read through the grammar this build links in.
      #
      # A method is reached through the type it hangs on, so `Charge.Settle` is
      # the name — which go doc links spell the same way, and which drops the
      # pointer, because `*Charge` and `Charge` reach one declaration. What the
      # package is called lives in the directory rather than the file, so a
      # name written here stops where the file does.
      #
      # The grammar is handed in rather than reached for: what a build carries is
      # decided at its edge, and a reading that named one would be a second
      # place saying so.
      #
      # A caller reaches this through the seam rather than by name, so nothing
      # here requires its way back up to it — only a build, saying what it
      # carries, writes the name.
      class Go
        # What the binding knows this grammar by. It travels with the queries,
        # since they are written against its node names and no two grammars
        # spell a node alike.
        GRAMMAR = "go"

        # Go spells `//` and `/* */` with one node, the way Ruby does. The
        # second pattern says what each comment stands next to, and matches
        # only where something does.
        COMMENTS = <<~COMMENTS
          (comment) @#{Nodes::FOUND}
          ((comment) @#{Nodes::BEFORE} . (_) @#{Nodes::BESIDE})
        COMMENTS

        # A block comment ends with the delimiter Go required rather than with
        # something a person wrote, and the tree offers no node to ask for: the
        # comment is one token with no children. So it comes off the text — the
        # one place this reading counts back over what the tree measured.
        # Taking it off a line comment is a no-op, which is what lets both
        # spellings share the one node they are given.
        CLOSE = "*/"

        # The type a method hangs on, captured beside the method's own name so
        # the two arrive together. A receiver is not a scope the method sits
        # in, so what enclosing recovers for other languages is read off a
        # sibling here.
        HOLDER = "holder"
        ON = "on"

        # A type declares a name and, where it is an interface, encloses the
        # methods written inside it. Those two put a path in front of a name by
        # different means, and a Go file uses both.
        SCOPE = "scope"

        # The function a parameter belongs to, and the two kinds Go hands a
        # caller. A variadic one gathers whatever is there, so a caller may
        # always leave it out.
        OF = "of"
        NAMED = "named"
        VARIADIC = "variadic"

        # `func Unnamed(uint32)` declares a parameter and gives it no name, so
        # the name is asked for rather than required — a parameter a caller
        # still has to satisfy is not one to pass over.
        PARAMETERS = <<~PARAMETERS
          [(parameter_declaration name: (_)? @named) @positional
           (variadic_parameter_declaration name: (_)? @named) @variadic]*
        PARAMETERS

        # A receiver is written as a parameter list of its own, so the type is
        # reached through it. Pointer and value spell one type, which is why
        # both branches answer under one capture.
        RECEIVER = <<~RECEIVER
          receiver: (parameter_list
            (parameter_declaration type: [(pointer_type (type_identifier) @holder)
                                          (type_identifier) @holder]))
        RECEIVER

        # A method is asked for twice: once for the name it declares, and once
        # for the type it hangs on. One match carrying both would leave what
        # kind of node it was to whichever capture the parser met last.
        QUERY = <<~QUERY
          (type_spec name: (_) @name) @scope
          (method_elem name: (_) @name) @item
          (const_spec name: (_) @name) @item
          (var_spec name: (_) @name) @item
          (function_declaration name: (_) @name) @item
          (method_declaration name: (_) @name) @item
          (method_declaration #{RECEIVER} name: (_) @on)
          (function_declaration name: (_) @of parameters: (parameter_list #{PARAMETERS}))
          (method_declaration name: (_) @of parameters: (parameter_list #{PARAMETERS}))
          (method_elem name: (_) @of parameters: (parameter_list #{PARAMETERS}))
        QUERY

        def initialize(grammar)
          @grammar = grammar
        end

        def named?(name)
          name == GRAMMAR
        end

        def reads?(path)
          path.extname == ".go"
        end

        def comments_in(path, where)
          regions(captured(path.read, COMMENTS, where))
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
          holders = holders_in(matches)

          scopes = []
          nodes.each { |node| scopes.push(node) if node.kind == SCOPE }

          found = []
          nodes.each do |node|
            found.push(Source::Declaration.new(
              where, node.first, qualified(scopes, holders, node), shape_for(taken, node)
            ))
          end
          found
        end

        private

        def regions(captures)
          matches = Nodes.matches_in(captures)
          following = Nodes.following(matches)
          found = []
          captures.each do |capture|
            next unless capture.name == Nodes::FOUND

            found.push(Source::Region.new(
              capture.line, capture.text.delete_suffix(CLOSE), following[capture.start]
            ))
          end
          found
        end

        def captured(source, query, where)
          @grammar.captures_of(GRAMMAR, source, query, where)
        rescue TreeSitter::ParseError => e
          # Source the grammar cannot read is not a difference between the two
          # sides either: half a file yields regions the rest of it never made.
          raise Error, e.message
        end

        # The type each method hangs on, kept under the method it belongs to.
        # The path in front of a name comes from a capture beside it rather than
        # from what encloses it, which is where this reading parts from the ones
        # whose languages nest.
        def holders_in(matches)
          found = {}
          groups = Nodes.grouped_by(matches, ON)
          groups.keys.each { |key| found[key] = holder_from(groups[key]) }
          found
        end

        def holder_from(group)
          found = nil
          group.each { |captures| found = Nodes.capture_of(captures, HOLDER) }
          found.nil? ? nil : found.text
        end

        # A reading answers in the order the parser met the nodes; a path is
        # built from what encloses one, so the types have to be in file order.
        def sorted(nodes)
          nodes.sort_by { |node| node.first }
        end

        # The name a contract would have to write to reach this declaration.
        # A method hangs on the type its receiver names; a method written
        # inside an interface hangs on the one enclosing it; everything else
        # the package declares directly answers by its bare name.
        def qualified(scopes, holders, node)
          holder = holders[Nodes.owner_of(node.first, node.text)]
          return "#{holder}.#{node.text}" unless holder.nil?

          path = Nodes.enclosing(scopes, node).map { |scope| scope.text }
          path.push(node.text)
          path.join(".")
        end

        # The parameters each function takes, kept under the function they
        # belong to.
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

        # What a caller has to write for this parameter. Go lets a declaration
        # give one no name, and lets a caller leave a variadic one out.
        def param_from(captures)
          kind = nil
          name = nil
          captures.each do |capture|
            next if capture.name == OF

            if capture.name == NAMED
              name = capture.text
            else
              kind = capture.name
            end
          end
          return nil if kind.nil?

          Source::Param.new(name, kind, kind == VARIADIC)
        end

        # What a declaration answers for its parameters: the list for a
        # function, empty where it takes none, and nothing at all for a type or
        # a constant, which are not reached by calling them.
        def shape_for(taken, node)
          found = taken[Nodes.owner_of(node.first, node.text)]
          found.nil? ? nil : Source::Shape.new(params: found)
        end
      end
    end
  end
end
