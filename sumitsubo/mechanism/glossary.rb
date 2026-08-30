require "sumitsubo/check/reach"
require "sumitsubo/check/region"
require "sumitsubo/glossary"
require "sumitsubo/mechanism/seed"

module Sumitsubo
  module Mechanism
    # The words a project keeps, checked against every word a person wrote.
    class Glossary
      BARREN = "glossary/barren"
      REJECTED = "glossary/rejected"
      STALE = "glossary/stale"

      def initialize
        @barren = Check::Reach::Barren.new(BARREN)
        @rejected = Check::Region::Rejected.new(REJECTED)
        @stale = Check::Region::Stale.new(STALE)
      end

      # The name .sumi.json knows this specification by.
      def specification
        "glossary"
      end

      def seed(root)
        Seed.new(Sumitsubo::Glossary.path_in(root), Sumitsubo::Glossary::SEED)
      end

      # What a mechanism could not read is its own to report, so the parser's
      # refusal is answered under this mechanism's name.
      def read(parser, path, source)
        parser.glossary(path)
      rescue Sumitsubo::Unreadable => e
        raise Sumitsubo::Glossary::Error, e.message
      end

      def verify(config, findings, specifications, source)
        path = Sumitsubo::Glossary.path_in(config.root)
        vocabulary = specifications.one(path, self)
        @barren.run(Sumitsubo::Glossary.covers(vocabulary, path), config.base, config.exclusion)
               .each { |one| findings.add(one) }
        scope = Sumitsubo::Glossary.scope(vocabulary, config.base, config.exclusion)
        mentions = Sumitsubo::Glossary.uses(
          Sumitsubo::Glossary.check(scope, config.base, source), vocabulary
        )
        aside = Sumitsubo::Glossary.set_aside(vocabulary)
        @rejected.run(mentions, aside, config.base).each { |one| findings.add(one) }
        @stale.run(mentions, aside, path).each { |one| findings.add(one) }
      end
    end
  end
end
