require "sumitsubo/check/reach"
require "sumitsubo/check/region"
require "sumitsubo/glossary"
require "sumitsubo/specification/builder/glossary"
require "sumitsubo/mechanism/seed"

module Sumitsubo
  module Mechanism
    # The words a project keeps, checked against every word a person wrote.
    class Glossary
      BARREN = "glossary/barren"
      UNREADABLE = "glossary/unreadable"
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

      # Which kinds of block this form is written in, asked before a document is
      # read so that a parser answers with those and no others.
      def kinds
        Specification::Builder::Glossary::KINDS
      end

      def read(blocks, path, source)
        Specification::Builder::Glossary.new(path).build(blocks)
      end

      # The rule a document this form refused answers under.
      def unreadable
        UNREADABLE
      end

      # The one specification this mechanism keeps. A vocabulary is a single
      # document, so a name standing for two things is refused as it is read
      # and there is nothing left to say across documents.
      #
      # `fmt` asks for this and nothing else, and `verify` asks for it first,
      # so the two commands say the same thing about a reference line.
      def declared(config, specifications)
        specifications.one(Sumitsubo::Glossary.at(Sumitsubo::Glossary.path_in(config.root)), self)
      end

      def verify(config, findings, specifications, source)
        path = Sumitsubo::Glossary.at(Sumitsubo::Glossary.path_in(config.root))
        vocabulary = declared(config, specifications)
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
