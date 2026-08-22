require "sumitsubo/error"
require "sumitsubo/language/grammar"
require "sumitsubo/definitions"

module Sumitsubo
  module Language
    # Rust, read through the grammar this build links in.
    #
    # A name is the path a reader would write to reach it, which is the path
    # the file itself carries: `Charge::settle` for a method in an `impl`,
    # `audit::Entry` for a struct in a `mod`. What a crate is called and which
    # module a file becomes live in Cargo.toml and in the directory tree, so a
    # name written here stops where the file does — as the documentation
    # convention does, writing `Vec::push` rather than the whole path.
    #
    # Reached through `language.rb`, which holds the seam and the shapes a
    # reading answers with, so nothing here requires its way back up.
    class Rust
      # What Ruby spells with one node Rust splits into two, and a doc comment
      # is a line comment carrying a marker.
      COMMENTS = "[(line_comment) (block_comment)] @text"

      # A comment with something after it. A claim sits in front of the code
      # that implements it, so a comment nothing follows claims nothing.
      ATTACHED = "([(line_comment) (block_comment)] @text . (_))"

      # A path, written the way Rust writes one. There is no spelling that
      # tells a method from an associated function: both are reached through
      # the type, and which it is shows in whether it takes `self`.
      PATH = /\A[A-Za-z_][A-Za-z0-9_]*(::[A-Za-z_][A-Za-z0-9_]*)*\z/

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

      def named?(name)
        name == Grammar::RUST
      end

      def reads?(path)
        path.extname == ".rs"
      end

      # Every segment is an identifier and `::` is what joins them. A name a
      # reader would have to write generics or a lifetime into is one this
      # reading could not have found, so it is not a shape a contract offers.
      def definable?(name)
        !PATH.match(name).nil?
      end

      def comments_in(path, where)
        regions(captured(path, COMMENTS, where))
      end

      def attached_comments_in(path, where)
        regions(captured(path, ATTACHED, where))
      end

      def declarations_in(path, where)
        matches = Definitions.matches_in(captured(path, QUERY, where))
        nodes = sorted(Definitions.nodes_in(matches))
        taken = params_in(matches)

        holders = []
        nodes.each { |node| holders.push(node) if node.kind != ITEM }

        found = []
        nodes.each do |node|
          next if node.kind == HOLDER

          found.push(Name.new(
            where, node.first, qualified(holders, node), params_for(taken, node)
          ))
        end
        found
      end

      private

      def regions(captures)
        found = []
        captures.each { |capture| found.push(Region.new(capture.line, capture.text)) }
        found
      end

      def captured(path, query, where)
        TreeSitter.capture(Grammar::RUST, path.read, query, where)
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
        path = []
        Definitions.enclosing(holders, node).each { |holder| path.push(base(holder.text)) }
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
          holding.push(Param.new(name, kind, false))
        end
        found
      end

      # A scope takes no parameters at all, which is not the same as a
      # function that takes none.
      def params_for(taken, node)
        return nil unless node.kind == ITEM

        found = taken["#{node.first}\t#{node.text}"]
        found.nil? ? [] : found
      end

    end
  end
end
