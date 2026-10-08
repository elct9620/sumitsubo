require "sumitsubo/place"
require "sumitsubo/command/run"
require "sumitsubo/behavior"
require "sumitsubo/related"

module Sumitsubo
  module Command
    # What one statement is related to, two relations out: what the
    # specifications say of one another, so a feature can be read whole from
    # any statement in it. A key of another mechanism opens with its name, the
    # way a specification writes it, and arrives quoted as one word.
    # @command relate
    class Relate
      # How far out from the statement asked about the answer reaches.
      DEPTH = 2

      # What an edge reads as from each of its ends. A relation says nothing
      # about which statement wrote it, so it reads the same from either; a
      # refinement reads the other way from the statement it narrows.
      OUTWARD = { Relation::RELATES => "relates", Relation::REFINES => "refines" }
      INWARD = { Relation::RELATES => "relates", Relation::REFINES => "refined by" }

      # A statement is read once in an answer, so one met again says so rather
      # than opening a second time.
      SEEN = "(above)"

      # One edge as it reads from the statement it leaves: the label, the
      # statement it leads to, and the one it was reached from.
      Edge = Data.define(:label, :node, :from)

      def run(config, languages, parsers, key)
        if key.nil?
          puts "relate takes the key of a statement, quoted where another mechanism keeps it"
          return 2
        end

        current = Run.new(config, languages, parsers)
        return 2 if current.rootless?

        current.relate
        return 2 if current.unread?

        current.declare(Mechanism::ALL)
        @current = current
        @names = Mechanism::ALL.map { |one| one.specification }
        written = Related.reference(key, "", @names)
        roots = rooted(written)
        if roots.empty?
          puts "nothing declares #{key}"
          # It may stand in a document that could not be read, which is then
          # said rather than left as the answer.
          searched(written).each { |mechanism| @current.statements_named(mechanism) if @current.refused?(mechanism) }
        end
        roots.each { |root| answered(root).each { |line| puts line } }
        # A switched-off mechanism is read for what the answer shows, so what
        # it could not read is said after it rather than before.
        current.unread? ? 2 : 0
      end

      private

      # Every statement the key names: the one under the mechanism it opens
      # with, or, written bare, the one under whichever mechanism declares it.
      def rooted(written)
        found = []
        searched(written).each do |mechanism|
          held = @current.statements_of(mechanism)
          next if held.nil? || held.none? { |one| one.key == written.key }

          found.push(Relation::Reference.new(mechanism: mechanism.specification, key: written.key))
        end
        found
      end

      # The mechanisms a key is looked for under.
      def searched(written)
        Mechanism::ALL.select { |one| written.mechanism.empty? || written.mechanism == one.specification }
      end

      def answered(root)
        @root = root.mechanism
        @shown = { spoken(root) => true }
        said = ["#{named(root)}#{about(root)}"]
        edges = edges_of(root, nil)
        beside = beside_of(root)
        last = edges.length + beside.length - 1
        edges.each_with_index do |edge, at|
          said.concat(branch(edge, "", at == last, 1))
        end
        beside.each_with_index do |one, at|
          said.push("#{at + edges.length == last ? "└─" : "├─"} #{one}")
        end
        said
      end

      # One edge and, while the answer may still reach further, the edges of
      # the statement it leads to, less the one it was reached by.
      def branch(edge, indent, closing, depth)
        node = edge.node
        seen = !@shown[spoken(node)].nil?
        @shown[spoken(node)] = true
        line = "#{indent}#{closing ? "└─" : "├─"} #{edge.label}  #{named(node)}#{seen ? "  #{SEEN}" : about(node)}"
        return [line] if seen || depth >= DEPTH

        said = [line]
        further = edges_of(node, edge.from)
        further.each_with_index do |one, at|
          said.concat(branch(one, "#{indent}#{closing ? "   " : "│  "}", at == further.length - 1, depth + 1))
        end
        said
      end

      # Every statement a relation joins this one to, as the label it reads
      # under from here, the statement, and this one for the far end to leave
      # out. One statement joined twice under one label is one edge.
      def edges_of(node, from)
        found = []
        taken = {}
        [Relation::RELATES, Relation::REFINES].each do |kind|
          @current.relations.of(kind).each do |relation|
            edge = edge_of(relation, node)
            next if edge.nil?

            far = spoken(edge.node)
            next if !from.nil? && far == from
            next unless taken["#{edge.label} #{far}"].nil?

            taken["#{edge.label} #{far}"] = true
            found.push(edge)
          end
        end
        found
      end

      def edge_of(relation, node)
        if same?(relation.subject, node)
          return Edge.new(label: OUTWARD[relation.kind], node: relation.object, from: spoken(node))
        end
        return Edge.new(label: INWARD[relation.kind], node: relation.subject, from: spoken(node)) if same?(relation.object, node)

        nil
      end

      def same?(one, other)
        one.mechanism == other.mechanism && one.key == other.key
      end

      # The scenarios claimed in the same comment as this one. The run reads
      # that off the source rather than off a specification, so it is said
      # apart from what the specifications declare.
      def beside_of(root)
        return [] unless root.mechanism == Mechanism::BEHAVIOR.specification

        claims = Sumitsubo::Behavior.claimed_in(@current.relations, root.mechanism)
        found = []
        taken = {}
        claims.each do |claim|
          next unless claim.key == root.key

          Sumitsubo::Behavior.beside(claim, claims).each do |key|
            next unless taken[key].nil?

            taken[key] = true
            other = Relation::Reference.new(mechanism: root.mechanism, key: key)
            found.push("claimed beside  #{named(other)}#{titled(other)}  " \
                       "#{Place.of(claim.path, claim.comment_line).spoken}  (derived)")
          end
        end
        found
      end

      # A statement written the way a specification under the asked one's
      # mechanism would write it.
      def named(reference)
        reference.mechanism == @root ? reference.key : "#{reference.mechanism} #{reference.key}"
      end

      def spoken(reference)
        "#{reference.mechanism} #{reference.key}"
      end

      # What a statement says and where it is declared, or that nothing
      # declares it. Where a document of its mechanism was refused, it may
      # stand in that one, and the refusal said after the answer is why.
      def about(reference)
        statement = declared(reference)
        return "  in a specification that could not be read" if statement.nil? && unread?(reference)
        return "  declared nowhere" if statement.nil?

        "#{titled(reference)}  #{Place.of(statement.path, statement.line).spoken}"
      end

      def unread?(reference)
        mechanism = Mechanism::ALL.find { |one| one.specification == reference.mechanism }
        !mechanism.nil? && @current.refused?(mechanism)
      end

      def titled(reference)
        statement = declared(reference)
        statement.nil? || statement.text.nil? ? "" : "  #{statement.text}"
      end

      def declared(reference)
        found = nil
        Mechanism::ALL.each do |mechanism|
          next unless mechanism.specification == reference.mechanism

          held = @current.statements_named(mechanism)
          found = held.find { |one| one.key == reference.key } unless held.nil?
        end
        found
      end
    end
  end
end
