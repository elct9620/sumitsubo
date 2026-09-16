require "sumitsubo/behavior"
require "sumitsubo/specification/builder/behavior"
require "sumitsubo/check/claim"
require "sumitsubo/check/reach"
require "sumitsubo/finding"
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

      def initialize
        @barren = Check::Reach::Barren.new(BARREN)
        @unclaimed = Check::Claim::Unclaimed.new(UNCLAIMED)
        @misplaced = Check::Claim::Misplaced.new(MISPLACED)
        @unresolved = Check::Claim::Unresolved.new(UNRESOLVED, "scenario")
        @nameless = Check::Claim::Nameless.new(NAMELESS, "scenario")
        @dangling = Check::Claim::Dangling.new(DANGLING)
      end

      def specification
        "behavior"
      end

      def seed(root)
        Seed.new(Sumitsubo::Behavior.path_in(root), nil)
      end

      # Which kinds of block this form reads, asked before a document is
      # read so that a parser answers with those and no others.
      def kinds
        Specification::Builder::Behavior::KINDS
      end

      def read(blocks, path, source)
        Specification::Builder::Behavior.new(path).build(blocks)
      end

      # A document this form refused, worded as the finding a run answers
      # with. The check is worded here because it is this mechanism's, the way
      # every other check of its own is.
      def refused(refusal)
        Finding.refused(UNREADABLE, refusal)
      end

      # Nothing about how a feature is written is checked yet, so it is
      # written the one way it reads.
      def rewrites(feature, lines)
        []
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

      def verify(config, findings, specifications, source)
        features = declared(config, specifications)
        @barren.run(Sumitsubo::Behavior.covers(features), config.base, config.exclusion)
               .each { |one| findings.add(one) }
        reach = Sumitsubo::Behavior.reach(features, config.base, config.exclusion)
        claims = Sumitsubo::Behavior.claimed_in(reach, source)
        stated = Sumitsubo::Behavior.stated_in(features)
        declaring = Sumitsubo::Behavior.declaring_in(features)
        # A claim standing in front of nothing is answered once, by itself: it
        # names a scenario without witnessing one, so putting it through the
        # comparisons below would say the same thing a second way.
        in_front = Check::Claim.in_front_of_code(claims)
        # What the check below compares is the claims that can witness; the
        # rest answer for themselves further down.
        within = Check::Claim.within(in_front, declaring, reach)

        @unclaimed.run(stated, within).each { |one| findings.add(one) }
        @misplaced.run(in_front, declaring, reach).each { |one| findings.add(one) }
        @unresolved.run(Sumitsubo::Behavior.named(in_front), stated).each { |one| findings.add(one) }
        @nameless.run(Sumitsubo::Behavior.nameless(in_front)).each { |one| findings.add(one) }
        @dangling.run(Check::Claim.dangling(claims)).each { |one| findings.add(one) }
      end
    end
  end
end
