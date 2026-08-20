require "sumitsubo/glossary"
require "sumitsubo/behavior"
require "sumitsubo/marker"

module Sumitsubo
  # A mechanism is a specification paired with the reading of source it is
  # checked against, which is why Behavior meets Marker here and not in its own
  # file — see the Build section of CLAUDE.md for what that separation buys.
  #
  # A mechanism registers by being in the list: Spinel decides what an
  # executable carries when it is built, so there is no hook to register
  # through.
  module Mechanism
    # What a mechanism lays down to start a reference line from. A seed with no
    # content is a directory: a project keeps one specification per feature, so
    # there is a place rather than a file to create.
    Seed = Struct.new(:path, :content)

    class Glossary
      # The name .sumi.json knows this specification by.
      def specification
        "glossary"
      end

      def seed(root)
        Seed.new(Sumitsubo::Glossary.path_in(root), Sumitsubo::Glossary::EMPTY)
      end

      def verify(config, report)
        sections = Sumitsubo::Glossary.load(Sumitsubo::Glossary.path_in(config.root))
        scope = Sumitsubo::Glossary.scope(sections, config.base)
        Sumitsubo::Glossary.check(scope, config.base).each do |finding|
          report.difference(finding.path, finding.line, Sumitsubo::Glossary.describe(finding))
        end
      end
    end

    class Behavior
      def specification
        "behavior"
      end

      def seed(root)
        Seed.new(Sumitsubo::Behavior.path_in(root), nil)
      end

      def verify(config, report)
        features = Sumitsubo::Behavior.load(Sumitsubo::Behavior.path_in(config.root))
        claims = claims_in(features, config)

        Sumitsubo::Behavior.uncovered(features, claims).each do |finding|
          report.difference(finding.path, finding.line, Sumitsubo::Behavior.describe_uncovered(finding))
        end
        # A claim resolving to no scenario is not a difference: there is nothing
        # on the specification side to compare it against.
        Sumitsubo::Behavior.unresolved(features, claims).each do |claim|
          report.failure(claim.path, claim.line, Sumitsubo::Behavior.describe_unresolved(claim))
        end
      end

      private

      def claims_in(features, config)
        claims = []
        Sumitsubo::Behavior.scope(features, config.base).each do |path|
          claims.concat(Marker.claims_in(path, Sumitsubo::Behavior::MARKER))
        end
        claims
      end
    end

    # The order a run reaches them in, which is the order init lays them down.
    ALL = [Glossary.new, Behavior.new]
  end
end
