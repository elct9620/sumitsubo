require "sumitsubo/feature/declared"
require "sumitsubo/feature/kept"
require "sumitsubo/feature/compared"
require "sumitsubo/specification/builder/behavior"
require "sumitsubo/check/claim"
require "sumitsubo/check/reach"
require "sumitsubo/reach"
require "sumitsubo/finding"
require "sumitsubo/place"
require "sumitsubo/specification/rewrite"
require "sumitsubo/specification/arrange"
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
      UNARRANGED = "behavior/unarranged"
      ORDER = "order"
      ARRANGE = "arrange"

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

      # `order: false` leaves the scenarios where their author wrote them, and
      # `arrange: false` leaves each one's attributes where they were written.
      def switches
        [ORDER, ARRANGE]
      end

      def seed(root)
        Seed.new(Feature.path_in(root), nil)
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

      # A feature's scenarios in the order of their ids, each with its
      # attributes right above its steps, unless the project switched either
      # off. A scenario written before a lower id answers at its heading, and
      # attributes written elsewhere at their table; the lines moved with
      # either answer nothing.
      def rewrites(config, feature, lines)
        scenarios = feature.statements
        misplaced = config.switched?(specification, ARRANGE) ? Specification::Arrange.misplaced(scenarios, lines) : []
        ahead = config.switched?(specification, ORDER) ? Feature.ahead(scenarios) : []
        return [] if misplaced.empty? && ahead.empty?

        said = {}
        ahead.each { |pair| said[pair[0].line] = unordered(pair[0], pair[1]) }
        misplaced.each { |scenario| said[scenario.arrangement.from] = unarranged(scenario) }
        written = misplaced.empty? ? lines : Specification::Arrange.written(misplaced, lines)
        written = Feature.ordered(scenarios, written) unless ahead.empty?
        # Written out here and in the other mechanism rather than shared:
        # Spinel 2026.09.12 cannot build one module function both call
        # ("cannot box ... into a poly value"). Master a060aef1e can.
        found = []
        lines.each_index do |at|
          finding = said[at + 1]
          next if written[at] == lines[at] && finding.nil?

          found.push(Specification::Rewrite.new(finding, at + 1, written[at]))
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
        features = specifications.all(Feature.path_in(config.root), self)
        Feature.refuse_ambiguity(features)
        features
      end

      # Every scenario the specifications declare, which is what a statement
      # elsewhere names by its key.
      def statements(config, specifications)
        declared(config, specifications).map { |one| one.statements }.flatten
      end

      # The files every feature reaches.
      def reach(config, specifications, relations)
        Reach.keep(declared(config, specifications), config.base, config.exclusion, relations, config.here)
      end

      # What the source says about each scenario, kept for whoever asks after:
      # every claim the marker leaves in the files the features reach.
      def keep(config, specifications, source, relations)
        features = declared(config, specifications)
        Feature.keep(Reach.of(features, relations), source, relations, specification)
      end

      # The claims the run kept for this mechanism, as its checks compare them.
      def claims(relations)
        Feature.claimed_in(relations, specification)
      end

      # The markers the run kept for this mechanism with no code below them.
      def dangling(relations)
        Feature.dangling_in(relations, specification)
      end

      # Which feature declares each scenario.
      def declaring(features)
        Feature.declaring_in(features)
      end

      # Every scenario a claim could name, said the way a claim says it.
      def stated(features)
        Feature.stated_in(features)
      end

      # The statements a key written elsewhere names: every one declared under
      # it, so a key two of them answer to is not quietly taken as either.
      def find(key, writer, config, specifications, relations, named)
        named.select { |one| one.key == key }
      end

      def verify(config, findings, specifications, source, relations)
        features = declared(config, specifications)
        @barren.run(Reach.covers(features), config.base, config.exclusion)
               .each { |one| findings.add(one) }
        reach = Reach.of(features, relations)
        claimed = claims(relations)
        # Read through the module rather than `stated`: Spinel 2026.09.12
        # answers that call with nil from inside this method. Master c52df8a1
        # does not, so call `stated` once the pin moves past it.
        scenarios = Feature.stated_in(features)
        declared_by = declaring(features)
        # What the check below compares is the claims that can witness; the
        # rest answer for themselves further down.
        within = Check::Claim.within(claimed, declared_by, reach)

        @unclaimed.run(scenarios, within).each { |one| findings.add(one) }
        @stale.run(scenarios, within).each { |one| findings.add(one) }
        @misplaced.run(claimed, declared_by, reach).each { |one| findings.add(one) }
        @unresolved.run(Feature.named(claimed), scenarios).each { |one| findings.add(one) }
        @nameless.run(Feature.nameless(claimed)).each { |one| findings.add(one) }
        # A marker standing in front of nothing names a scenario without
        # witnessing one, so it is answered once, by itself, rather than through
        # the comparisons above.
        @dangling.run(dangling(relations)).each { |one| findings.add(one) }
      end

      private

      def unarranged(scenario)
        Finding.new(
          check: UNARRANGED, difference: true,
          place: Place.new(path: scenario.path, line: scenario.arrangement.from),
          message: "#{scenario.key} writes its attributes somewhere other than right above its steps"
        )
      end

      def unordered(scenario, lowest)
        Finding.new(
          check: UNORDERED, difference: true,
          place: Place.new(path: scenario.path, line: scenario.line),
          message: "#{scenario.key} is written before #{lowest.key}"
        )
      end
    end
  end
end
