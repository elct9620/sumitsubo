require "sumitsubo/source"

module Sumitsubo
  module Source
    class Language
      # What a syntax tree hands back, made into what a reading answers with —
      # the part of that work no language owns.
      #
      # Nothing here reaches a grammar: a reading captures what its own query
      # asked for and brings the captures here, which is what keeps this file, and
      # every test of it, on the side a snapshot can be regenerated from.
      #
      # Two conventions are all a reading has to keep. A capture named `name` is
      # what the node is called; any other capture on the same match is what kind
      # of node it was. Everything else — which kinds carry a name of their own,
      # how a path is spelled, what a parameter may be left out of — belongs to the
      # reading, because two languages answer those differently.
      module Nodes
        # The capture that names a node, as against the one that says what it is.
        NAME = "name"

        # The captures a reading writes to say where its comments sit: one
        # pattern finding every comment, and a second pairing one with the node
        # beside it — which matches only where such a node is there.
        FOUND = "any"
        BEFORE = "text"
        BESIDE = "next"

        # One match of a reading's query: what kind of node it was, what it is
        # called, and the lines it spans.
        Node = Struct.new(:kind, :text, :first, :last)

        # The captures of each match, grouped and left in the order the parser met
        # them: they arrive in node position rather than pattern order, which is
        # why the name each carries is what tells them apart.
        def self.matches_in(captures)
          grouped = {}
          order = []
          captures.each do |capture|
            holding = grouped[capture.match]
            if holding.nil?
              holding = []
              grouped[capture.match] = holding
              order.push(capture.match)
            end
            holding.push(capture)
          end

          order.map { |key| grouped[key] }
        end

        # What each comment sits in front of, under the byte it starts at. A
        # query has no way to ask what a node is not, so whether the neighbour is
        # itself a comment is answered by the set of comments the same query
        # found — which is why the pairing is asked for in a second pattern
        # rather than read off the first.
        def self.following(matches)
          found = {}
          matches.each do |captures|
            at = byte_of(captures, FOUND)
            found[at] = Source::Region::NOTHING unless at.nil?
          end

          matches.each do |captures|
            beside = byte_of(captures, BESIDE)
            next if beside.nil?

            found[byte_of(captures, BEFORE)] =
              found[beside].nil? ? Source::Region::CODE : Source::Region::COMMENT
          end
          found
        end

        # Where one of a match's captures begins, or nothing where the match
        # carries no such capture.
        def self.byte_of(captures, name)
          found = nil
          captures.each { |capture| found = capture.start if capture.name == name }
          found
        end

        # The nodes those matches declare. A match that declares nothing answers
        # nothing: a parameter names the method it belongs to rather than a name of
        # its own, so it is passed over here and read by whoever asked for it.
        def self.nodes_in(matches)
          found = []
          matches.each do |captures|
            node = node_from(captures)
            found.push(node) unless node.nil?
          end
          found
        end

        # The nodes holding this one, outermost first — which is also earliest
        # first, since one scope inside another opens after it.
        #
        # A pattern reaches only its direct children and tree-sitter has no
        # operator for a deeper one, so nesting is recovered from where the nodes
        # sit. Two nodes spanning the same lines hold each other or are the same
        # node, and neither can be told from the other at this resolution:
        # answering with none loses a prefix where a one-line `class A; class B;
        # end; end` nests, and answering with both would invent one.
        def self.enclosing(scopes, node)
          holding = []
          scopes.each do |scope|
            next if scope.first == node.first && scope.last == node.last

            holding.push(scope) if scope.first <= node.first && node.last <= scope.last
          end
          holding.sort_by { |scope| scope.first }
        end

        # The whole node is what a reading captures alongside the name, and the
        # lines it spans are the capture's own: the tree measured them, so
        # nothing here counts them back out of the text.
        def self.node_from(captures)
          kind = nil
          text = nil
          first = 0
          last = 0
          captures.each do |capture|
            if capture.name == NAME
              text = capture.text
            else
              kind = capture.name
              first = capture.line
              last = capture.last
            end
          end
          return nil if kind.nil? || text.nil?

          Node.new(kind, text, first, last)
        end
      end
    end
  end
end
