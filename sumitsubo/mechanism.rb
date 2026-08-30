require "sumitsubo/glossary"
require "sumitsubo/contract"
require "sumitsubo/behavior"
require "sumitsubo/source/marker"
require "sumitsubo/source/scope"
require "sumitsubo/finding"
require "sumitsubo/specification/repository"

module Sumitsubo
  # A mechanism is a specification paired with the reading of source it is
  # checked against, which is why Behavior meets Marker here and not in its own
  # file: keeping the specification side clear of the side that reads source is
  # what leaves `require "sumitsubo"` reaching no grammar, and the tests that
  # ask for nothing more able to keep a snapshot `--regen` can write.
  #
  # A mechanism registers by being in the list: Spinel decides what an
  # executable carries when it is built, so there is no hook to register
  # through.
  #
  # The languages and the parsers are handed in rather than named here, the
  # way the revision is: which ones a build carries is decided when it is
  # built, so the one file a build has of its own is where it says so. Nothing
  # in this graph reaches a grammar or names a format, which is what leaves a
  # snapshot of it one `--regen` can write.
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
        Seed.new(Sumitsubo::Glossary.path_in(root), Sumitsubo::Glossary::SEED)
      end

      # What a mechanism could not read is its own to report, so the parser's
      # refusal is answered under this mechanism's name.
      def read(parser, path, languages)
        parser.glossary(path)
      rescue Sumitsubo::Unreadable => e
        raise Sumitsubo::Glossary::Error, e.message
      end

      def verify(config, findings, specifications, languages)
        path = Sumitsubo::Glossary.path_in(config.root)
        vocabulary = specifications.one(path, self)
        Sumitsubo::Glossary.barren(vocabulary, config.base, path, config.exclusion, specifications).each { |one| findings.add(one) }
        scope = Sumitsubo::Glossary.scope(vocabulary, config.base, config.exclusion)
        mentions = Sumitsubo::Glossary.uses(
          Sumitsubo::Glossary.check(scope, config.base, languages), vocabulary
        )
        Sumitsubo::Glossary.standing(mentions, vocabulary, config.base).each { |one| findings.add(one) }
        Sumitsubo::Glossary.stale(mentions, vocabulary).each { |one| findings.add(one) }
      end
    end

    class Contract
      def specification
        "contract"
      end

      # A seed with no content is a directory: a project registers one kind of
      # contract per file, so there is a place rather than a file to create.
      def seed(root)
        Seed.new(Sumitsubo::Contract.path_in(root), nil)
      end

      # The languages arrive with the parser because a contract's signature is
      # read by the very reading that reads the source it describes.
      def read(parser, path, languages)
        parser.contract(path, languages)
      rescue Sumitsubo::Unreadable => e
        raise Sumitsubo::Contract::Error, e.message
      end

      def verify(config, findings, specifications, languages)
        definitions = specifications.all(Sumitsubo::Contract.path_in(config.root), self)
        Sumitsubo::Contract.refuse_ambiguity(definitions)
        Sumitsubo::Contract.barren(definitions, config.base, config.exclusion, specifications).each { |one| findings.add(one) }
        claimed = Sumitsubo::Contract.claimed(definitions)
        reach = Sumitsubo::Contract.reach(claimed, config.base, config.exclusion)
        claims = claims_in(reach, definitions, languages)
        # What the two readings below compare is the claims that can implement
        # what they name; the rest answer for themselves further down.
        witnessing = Sumitsubo::Contract.witnessing(definitions, claims, reach)

        Sumitsubo::Contract.unclaimed(definitions, witnessing).each { |one| findings.add(one) }
        Sumitsubo::Contract.duplicated(definitions, witnessing).each { |one| findings.add(one) }
        Sumitsubo::Contract.misplaced(definitions, claims, reach).each { |one| findings.add(one) }
        Sumitsubo::Contract.unresolved(definitions, claims).each { |one| findings.add(one) }
        # The other reading makes no claims, so what it compares is what the
        # source defines and the shape a caller would have to call it with.
        spelled = Sumitsubo::Contract.reach(
          Sumitsubo::Contract.defined(definitions), config.base, config.exclusion
        )
        declared = Sumitsubo::Contract.defining(
          definitions, names_in(spelled, definitions, languages), spelled
        )
        Sumitsubo::Contract.undefined(definitions, declared).each { |one| findings.add(one) }
        Sumitsubo::Contract.conflicting(definitions, declared).each { |one| findings.add(one) }
        Sumitsubo::Contract.mismatched(definitions, declared, languages).each { |one| findings.add(one) }
      end

      private

      # Every word every definition claims, read in one pass: parsing is the
      # cost, so a project registering several kinds still reads each file once.
      def claims_in(reach, definitions, languages)
        claims = []
        keywords = Sumitsubo::Contract.keywords(definitions)
        Sumitsubo::Contract.scope(reach).each do |path|
          Source::Marker.claims_in(path, keywords, languages).each do |claim|
            claims.push(Sumitsubo::Contract::Claim.new(
              claim.path, claim.line,
              Sumitsubo::Contract::Name.new(claim.keyword, claim.text)
            ))
          end
        end
        claims
      end

      # What the source in scope defines, for the definitions read that way,
      # held under the language it was read as. A definition registering
      # contracts in two languages has its files read once per language, and
      # one file read twice answers twice: which reading each came back from
      # is what tells the two apart, so it is the answers that are held apart
      # rather than each answer that says which.
      def names_in(reach, definitions, languages)
        found = {}
        Sumitsubo::Contract.readings_in(definitions, reach).each do |reading|
          holding = found[reading.language]
          if holding.nil?
            holding = []
            found[reading.language] = holding
          end
          languages.declarations_in(reading.path, Place.file(reading.path), reading.language).each do |name|
            holding.push(name)
          end
        end
        found
      end
    end

    class Behavior
      def specification
        "behavior"
      end

      def seed(root)
        Seed.new(Sumitsubo::Behavior.path_in(root), nil)
      end

      def read(parser, path, languages)
        parser.behavior(path)
      rescue Sumitsubo::Unreadable => e
        raise Sumitsubo::Behavior::Error, e.message
      end

      def verify(config, findings, specifications, languages)
        features = specifications.all(Sumitsubo::Behavior.path_in(config.root), self)
        Sumitsubo::Behavior.refuse_ambiguity(features)
        Sumitsubo::Behavior.barren(features, config.base, config.exclusion, specifications).each { |one| findings.add(one) }
        reach = Sumitsubo::Behavior.reach(features, config.base, config.exclusion)
        claims = claims_in(reach, languages)
        # What the reading below compares is the claims that can witness; the
        # rest answer for themselves further down.
        witnessing = Sumitsubo::Behavior.witnessing(features, claims, reach)

        Sumitsubo::Behavior.uncovered(features, witnessing).each { |one| findings.add(one) }
        Sumitsubo::Behavior.misplaced(features, claims, reach).each { |one| findings.add(one) }
        Sumitsubo::Behavior.unresolved(features, claims).each { |one| findings.add(one) }
      end

      private

      # Marker finds the word and hands back the rest of the line; splitting
      # that into ids is Behavior's, which is what lets Contract read the same
      # line as one name instead.
      def claims_in(reach, languages)
        claims = []
        keywords = [Sumitsubo::Behavior::MARKER]
        Sumitsubo::Behavior.scope(reach).each do |path|
          Source::Marker.claims_in(path, keywords, languages).each do |claim|
            Sumitsubo::Behavior.ids_in(claim.text).each do |id|
              claims.push(Sumitsubo::Behavior::Claim.new(claim.path, claim.line, id))
            end
          end
        end
        claims
      end
    end

    # The order a run reaches them in, which is the order init lays them down,
    # and the order the README sets them out in.
    ALL = [Glossary.new, Contract.new, Behavior.new]
  end
end
