require "sumitsubo/error"
require "sumitsubo/source"
require "sumitsubo/source/language/nodes"

module Sumitsubo
  module Source
    class Language
      # Rust, read through the grammar this build links in.
      #
      # A name is the path a reader would write to reach it, which is the path
      # the file itself carries: `Charge::settle` for a method in an `impl`,
      # `audit::Entry` for a struct in a `mod`. What a crate is called and which
      # module a file becomes live in Cargo.toml and in the directory tree, so a
      # name written here stops where the file does — as the documentation
      # convention does, writing `Vec::push` rather than the whole path.
      #
      # The grammar is handed in rather than reached for: what a build carries is
      # decided at its edge, and a reading that named one would be a second
      # place saying so.
      #
      # A caller reaches this through the seam rather than by name, so nothing
      # here requires its way back up to it — only a build, saying what it
      # carries, writes the name.
      class Rust
        # What the binding knows this grammar by. It travels with the queries,
        # since they are written against its node names and no two grammars
        # spell a node alike.
        GRAMMAR = "rust"

        # What Ruby spells with one node Rust splits into two, and a doc comment
        # is a line comment carrying a marker. A block comment is asked for its
        # closing delimiter as well: where a person stopped writing is the
        # tree's to answer, not something to look for in the text afterwards.
        #
        # The last two patterns say what each comment stands next to, and match
        # only where something does. They ask for no delimiter: what they are
        # read for is the pairing, and the region is built from the comment the
        # patterns above found.
        COMMENTS = <<~COMMENTS
          (line_comment) @#{Nodes::FOUND}
          ((block_comment "*/" @close) @#{Nodes::FOUND})
          ((line_comment) @#{Nodes::BEFORE} . (_) @#{Nodes::BESIDE})
          ((block_comment) @#{Nodes::BEFORE} . (_) @#{Nodes::BESIDE})
        COMMENTS

        # The capture that says where the comment's own syntax resumes.
        CLOSE = "close"

        # What holds a name, what carries one of its own, and what does both.
        # An `impl` block is the first: it says how the functions inside it are
        # reached without declaring the type, which `struct` did.
        HOLDER = "holder"
        SCOPE = "scope"
        ITEM = "item"

        # The function a parameter belongs to, and the two kinds Rust hands a
        # caller. A receiver is the parameter that decides whether a function is
        # called through a value or through the type.
        OF = "of"
        NAMED = "named"

        PARAMETERS = <<~PARAMETERS
          [(self_parameter) @self
           (parameter pattern: (_) @named) @positional]*
        PARAMETERS

        QUERY = <<~QUERY
          (mod_item name: (_) @name) @scope
          (trait_item name: (_) @name) @scope
          (impl_item type: (_) @name) @holder
          (struct_item name: (_) @name) @item
          (enum_item name: (_) @name) @item
          (const_item name: (_) @name) @item
          (static_item name: (_) @name) @item
          (function_item name: (_) @name) @item
          (function_signature_item name: (_) @name) @item
          (function_item name: (_) @of parameters: (parameters #{PARAMETERS}))
          (function_signature_item name: (_) @of parameters: (parameters #{PARAMETERS}))
        QUERY


        def initialize(grammar)
          @grammar = grammar
        end

        def named?(name)
          name == GRAMMAR
        end

        def reads?(path)
          path.extname == ".rs"
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

          holders = []
          nodes.each { |node| holders.push(node) if node.kind != ITEM }

          found = []
          nodes.each do |node|
            next if node.kind == HOLDER

            found.push(Source::Declaration.new(
              where, node.first, qualified(holders, node), shape_for(taken, node)
            ))
          end
          found
        end

        private

        def regions(captures)
          matches = Nodes.matches_in(captures)
          following = Nodes.following(matches)
          found = []
          matches.each do |match|
            region = region_from(match, following)
            found.push(region) unless region.nil?
          end
          found
        end

        # What a person wrote in one comment, and what it stands next to. A line
        # comment is the whole node; a block one stops where the delimiter Rust
        # required begins, since a region carrying `*/` hands whoever reads that
        # line a word nobody wrote. The delimiter is taken off the end rather
        # than counted back from it.
        #
        # A match pairing a comment with its neighbour carries no comment of its
        # own to answer with: it was asked for the pairing, which `following`
        # has already read out of it.
        def region_from(captures, following)
          text = nil
          close = nil
          captures.each do |capture|
            close = capture if capture.name == CLOSE
            text = capture if capture.name == Nodes::FOUND
          end
          return nil if text.nil?

          said = close.nil? ? text.text : text.text.delete_suffix(close.text)
          Source::Region.new(text.line, said, following[text.start])
        end

        def captured(source, query, where)
          @grammar.captures_of(GRAMMAR, source, query, where)
        rescue TreeSitter::ParseError => e
          # Source the grammar cannot read is not a difference between the two
          # sides either: half a file yields regions the rest of it never made.
          raise Error, e.message
        end

        # A reading answers in the order the parser met the nodes; a path is
        # built from what encloses one, so the blocks have to be in file order.
        def sorted(nodes)
          nodes.sort_by { |node| node.first }
        end

        # The path a contract would have to write to reach this node, the blocks
        # holding it in front of it.
        def qualified(holders, node)
          path = Nodes.enclosing(holders, node).map { |holder| base(holder.text) }
          path.push(base(node.text))
          path.join("::")
        end

        # `impl Charge<T>` reaches the same type `struct Charge<T>` declared, so
        # the parameters it was written with are not part of the name.
        def base(text)
          at = text.index("<")
          at.nil? ? text : "#{text[0, at]}"
        end

        # The parameters each function takes, kept under the function they
        # belong to. Rust lets a caller leave none of them out.
        def params_in(matches)
          found = {}
          matches.each do |captures|
            of = nil
            kind = nil
            name = nil
            captures.each do |capture|
              if capture.name == OF
                of = capture
              elsif capture.name == NAMED
                name = capture.text
              else
                kind = capture.name
              end
            end
            next if of.nil? || kind.nil?

            key = "#{of.line}\t#{of.text}"
            holding = found[key]
            if holding.nil?
              holding = []
              found[key] = holding
            end
            holding.push(Source::Param.new(name, kind, false))
          end
          found
        end

        # A scope takes no parameters at all, which is not the same as a
        # function that takes none.
        def shape_for(taken, node)
          return nil unless node.kind == ITEM

          found = taken["#{node.first}\t#{node.text}"]
          Source::Shape.new(params: found.nil? ? [] : found)
        end

      end
    end
  end
end
