require "sumitsubo/check/reach"
require "sumitsubo/check/region"
require "sumitsubo/glossary"
require "sumitsubo/specification/builder/glossary"
require "sumitsubo/finding"
require "sumitsubo/place"
require "sumitsubo/specification/rewrite"
require "sumitsubo/mechanism/seed"

module Sumitsubo
  module Mechanism
    # The words a project keeps, checked against every word a person wrote.
    class Glossary
      BARREN = "glossary/barren"
      UNREADABLE = "glossary/unreadable"
      MISWRITTEN = "glossary/miswritten"
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

      # A document this form refused, worded as the finding a run answers
      # with. The rule is worded here because it is this mechanism's, the way
      # every other rule of its own is.
      def refused(refusal)
        Finding.refused(UNREADABLE, refusal)
      end

      # The one specification this mechanism keeps, answered as the several
      # the others keep, so a command over a reference line asks every
      # mechanism the same thing. A vocabulary is a single document, so a name
      # standing for two things is refused as it is read and there is nothing
      # left to say across documents.
      #
      # `fmt` asks for this and nothing else, and `verify` asks for it first,
      # so the two commands say the same thing about a reference line.
      def declared(config, specifications)
        [specifications.one(Sumitsubo::Glossary.at(Sumitsubo::Glossary.path_in(config.root)), self)]
      end

      # Every line this vocabulary writes otherwise than a reference line is
      # written. Only what it declares something on is looked at, and only
      # directly after the word taken letter for letter: a dash in the prose
      # beside it is prose, and rewriting one would change what a person wrote
      # rather than how they wrote it.
      def rewrites(vocabulary, lines)
        found = []
        set_off(vocabulary).each { |statement| dashed(found, statement, lines) }
        found
      end

      def verify(config, findings, specifications, source)
        path = Sumitsubo::Glossary.at(Sumitsubo::Glossary.path_in(config.root))
        vocabulary = declared(config, specifications)[0]
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

      private

      # Every statement a vocabulary sets off from the reason it carries: a
      # word a term turns down, and each line set aside under one. A section
      # and a term carry a definition rather than a reason, and neither is set
      # off from it.
      #
      # Taken a level at a time rather than walked, so no step of the descent
      # holds a variable another step is filling.
      def set_off(vocabulary)
        vocabulary.statements.map { |section| section.statements }.flatten
                  .map { |term| term.statements }.flatten
                  .map { |rejected| [rejected] + rejected.statements }.flatten
      end

      # The line as a reference line writes it, where it is written otherwise.
      # The word is taken letter for letter, so where it sits in the line is
      # what says which dash is the one setting it off.
      def dashed(found, statement, lines)
        said = lines[statement.line - 1]
        return if said.nil?

        at = set_off_at(said, statement.key)
        return if at.nil?

        found.push(Specification::Rewrite.new(
          Finding.new(
            rule: MISWRITTEN, difference: true,
            place: Place.of(statement.path, statement.line),
            message: "#{statement.key} is set off with a wide dash where a plain one is written"
          ),
          statement.line,
          "#{said[0, at]}#{Specification::Builder::Glossary::DASH}#{said[at + 1, said.length - at - 1]}"
        ))
      end

      # Where the wide dash sits in the line, or nothing where the line already
      # writes the plain one.
      def set_off_at(said, key)
        opened = said.index("`#{key}`")
        return nil if opened.nil?

        at = opened + key.length + 2
        at += 1 while said[at] == " "
        return nil unless said[at] == Specification::Builder::Glossary::WIDE

        at
      end
    end
  end
end
