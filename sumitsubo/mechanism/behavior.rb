require "sumitsubo/behavior"
require "sumitsubo/specification/builder/behavior"
require "sumitsubo/check/claim"
require "sumitsubo/check/reach"
require "sumitsubo/reach"
require "sumitsubo/finding"
require "sumitsubo/place"
require "sumitsubo/specification/rewrite"
require "sumitsubo/mechanism/seed"

module Sumitsubo
  module Mechanism
    # The scenarios a project declares, checked against the tests claiming
    # them. What it establishes is that a behavior was read and a test
    # witnesses it, never that the implementation is right.
    class Behavior
      BARREN = "behavior/barren"
      UNREADABLE = "behavior/unreadable"
      UNCLAIMED = "behavior/unclaimed"
      MISPLACED = "behavior/misplaced"
      UNRESOLVED = "behavior/unresolved"
      NAMELESS = "behavior/nameless"
      DANGLING = "behavior/dangling"
      STALE = "behavior/stale"
      UNORDERED = "behavior/unordered"
      ORDER = "order"

      def initialize
        @barren = Check::Reach::Barren.new(BARREN)
        @unclaimed = Check::Claim::Unclaimed.new(UNCLAIMED)
        @misplaced = Check::Claim::Misplaced.new(MISPLACED)
        @unresolved = Check::Claim::Unresolved.new(UNRESOLVED, "scenario")
        @nameless = Check::Claim::Nameless.new(NAMELESS, "scenario")
        @dangling = Check::Claim::Dangling.new(DANGLING)
        @stale = Check::Claim::Stale.new(STALE)
      end

      def specification
        "behavior"
      end

      # `order: false` leaves the scenarios where their author wrote them.
      def switches
        [ORDER]
      end

      def seed(root)
        Seed.new(Sumitsubo::Behavior.path_in(root), nil)
      end

      # Which kinds of block this form reads, asked before a document is
      # read so that a parser answers with those and no others.
      def kinds
        Specification::Builder::Behavior::KINDS
      end

      def read(blocks, path, languages)
        Specification::Builder::Behavior.new(path).build(blocks)
      end

      # A document this form refused, worded as the finding a run answers
      # with. The check is worded here because it is this mechanism's, the way
      # every other check of its own is.
      def refused(refusal)
        Finding.refused(UNREADABLE, refusal)
      end

      # A feature's scenarios in the order of their ids, unless the project
      # switched `order` off. Each scenario written before a lower id answers
      # once, at its heading; the lines moved with it answer nothing.
      def rewrites(config, feature, lines)
        return [] unless config.switched?(specification, ORDER)

        ahead = Sumitsubo::Behavior.ahead(feature.statements)
        return [] if ahead.empty?

        written = Sumitsubo::Behavior.ordered(feature.statements, lines)
        found = []
        lines.each_index do |at|
          next if written[at] == lines[at]

          pair = ahead.find { |one| one[0].line == at + 1 }
          found.push(Specification::Rewrite.new(pair.nil? ? nil : unordered(pair[0], pair[1]), at + 1, written[at]))
        end
        found
      end

      # Every specification this mechanism keeps, and everything that can be
      # said about them before a line of source is read: one id standing for
      # two scenarios is refused here, because no document answers for it by
      # itself. What a form refused is already kept as the documents were read.
      #
      # `fmt` asks for this and nothing else, and `verify` asks for it first,
      # so the two commands say the same thing about a reference line.
      def declared(config, specifications)
        features = specifications.all(Sumitsubo::Behavior.path_in(config.root), self)
        Sumitsubo::Behavior.refuse_ambiguity(features)
        features
      end

      # Every scenario the specifications declare, which is what a statement
      # elsewhere names by its key.
      def statements(config, specifications)
        declared(config, specifications).map { |one| one.statements }.flatten
      end

      # The files every feature reaches.
      def reach(config, specifications, relations)
        Reach.keep(declared(config, specifications), config.base, config.exclusion, relations)
      end

      # What the source says about each scenario, kept for whoever asks after:
      # every claim the marker leaves in the files the features reach.
      def relate(config, specifications, source, relations)
        features = declared(config, specifications)
        Sumitsubo::Behavior.relate(Reach.of(features, relations), source, relations, specification)
      end

      def verify(config, findings, specifications, source, relations)
        features = declared(config, specifications)
        @barren.run(Reach.covers(features), config.base, config.exclusion)
               .each { |one| findings.add(one) }
        reach = Reach.of(features, relations)
        claims = Sumitsubo::Behavior.claimed_in(relations, specification)
        stated = Sumitsubo::Behavior.stated_in(features)
        declaring = Sumitsubo::Behavior.declaring_in(features)
        # What the check below compares is the claims that can witness; the
        # rest answer for themselves further down.
        within = Check::Claim.within(claims, declaring, reach)

        @unclaimed.run(stated, within).each { |one| findings.add(one) }
        @stale.run(stated, within).each { |one| findings.add(one) }
        @misplaced.run(claims, declaring, reach).each { |one| findings.add(one) }
        @unresolved.run(Sumitsubo::Behavior.named(claims), stated).each { |one| findings.add(one) }
        @nameless.run(Sumitsubo::Behavior.nameless(claims)).each { |one| findings.add(one) }
        # A marker standing in front of nothing names a scenario without
        # witnessing one, so it is answered once, by itself, rather than through
        # the comparisons above.
        @dangling.run(Sumitsubo::Behavior.dangling_in(relations, specification)).each { |one| findings.add(one) }
      end

      private

      def unordered(scenario, lowest)
        Finding.new(
          check: UNORDERED, difference: true,
          place: Place.of(scenario.path, scenario.line),
          message: "#{scenario.key} is written before #{lowest.key}"
        )
      end
    end
  end
end
