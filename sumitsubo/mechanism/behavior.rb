require "sumitsubo/behavior"
require "sumitsubo/check/claim"
require "sumitsubo/check/reach"
require "sumitsubo/mechanism/seed"

module Sumitsubo
  module Mechanism
    # The scenarios a project declares, checked against the tests claiming
    # them. What it establishes is that a behavior was read and implemented,
    # never that the implementation is right.
    class Behavior
      BARREN = "behavior/barren"
      UNCLAIMED = "behavior/unclaimed"
      MISPLACED = "behavior/misplaced"
      UNRESOLVED = "behavior/unresolved"

      def initialize
        @barren = Check::Reach::Barren.new(BARREN)
        @unclaimed = Check::Claim::Unclaimed.new(UNCLAIMED)
        @misplaced = Check::Claim::Misplaced.new(MISPLACED)
        @unresolved = Check::Claim::Unresolved.new(UNRESOLVED, "scenario")
      end

      def specification
        "behavior"
      end

      def seed(root)
        Seed.new(Sumitsubo::Behavior.path_in(root), nil)
      end

      def read(parser, path, source)
        parser.behavior(path)
      rescue Sumitsubo::Unreadable => e
        raise Sumitsubo::Behavior::Error, e.message
      end

      def verify(config, findings, specifications, source)
        features = specifications.all(Sumitsubo::Behavior.path_in(config.root), self)
        Sumitsubo::Behavior.refuse_ambiguity(features)
        @barren.run(Sumitsubo::Behavior.covers(features), config.base, config.exclusion)
               .each { |one| findings.add(one) }
        reach = Sumitsubo::Behavior.reach(features, config.base, config.exclusion)
        claims = Sumitsubo::Behavior.claimed_in(reach, source)
        stated = Sumitsubo::Behavior.stated_in(features)
        declaring = Sumitsubo::Behavior.declaring_in(features)
        # What the check below compares is the claims that can witness; the
        # rest answer for themselves further down.
        witnessing = Check::Claim.witnessing(claims, declaring, reach)

        @unclaimed.run(stated, witnessing).each { |one| findings.add(one) }
        @misplaced.run(claims, declaring, reach).each { |one| findings.add(one) }
        @unresolved.run(claims, stated).each { |one| findings.add(one) }
      end
    end
  end
end
