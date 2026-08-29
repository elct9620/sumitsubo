require "sumitsubo/glossary"
require "sumitsubo/contract"
require "sumitsubo/behavior"
require "sumitsubo/marker"
require "sumitsubo/scope"

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

      def verify(config, report, languages, parsers)
        path = Sumitsubo::Glossary.path_in(config.root)
        vocabulary = Sumitsubo::Glossary.load(path, parsers)
        # An include reaching nothing is not a difference: what the words were
        # to be checked against was never read.
        Sumitsubo::Glossary.barren(vocabulary, config.base, path, config.exclusion, parsers).each do |barren|
          report.failure(barren.path, barren.line, Scope.describe(barren))
        end
        scope = Sumitsubo::Glossary.scope(vocabulary, config.base, config.exclusion)
        findings = Sumitsubo::Glossary.uses(
          Sumitsubo::Glossary.check(scope, config.base, languages), vocabulary
        )
        Sumitsubo::Glossary.standing(findings, vocabulary).each do |finding|
          report.difference(
            Where.of(config.base / finding.path), finding.line,
            Sumitsubo::Glossary.describe(finding)
          )
        end
        # An ignore naming nothing is not a difference about the code: what it
        # was written against is gone, so there was nothing to compare.
        Sumitsubo::Glossary.unresolved(findings, vocabulary).each do |stale|
          report.failure(
            Where.of(path), stale.line, Sumitsubo::Glossary.describe_unresolved(stale)
          )
        end
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

      def verify(config, report, languages, parsers)
        definitions = Sumitsubo::Contract.load(
          Sumitsubo::Contract.path_in(config.root), languages, parsers
        )
        Sumitsubo::Contract.barren(definitions, config.base, config.exclusion, parsers).each do |barren|
          report.failure(barren.path, barren.line, Scope.describe(barren))
        end
        claimed = Sumitsubo::Contract.claimed(definitions)
        reach = Sumitsubo::Contract.reach(claimed, config.base, config.exclusion)
        claims = claims_in(reach, definitions, languages)
        # What the two readings below compare is the claims that can implement
        # what they name; the rest answer for themselves further down.
        witnessing = Sumitsubo::Contract.witnessing(definitions, claims, reach)

        Sumitsubo::Contract.unclaimed(definitions, witnessing).each do |finding|
          report.difference(finding.path, finding.line, Sumitsubo::Contract.describe_unclaimed(finding))
        end
        # A contract is the way in, so a second way in is a difference about
        # the code rather than a specification that could not be read.
        Sumitsubo::Contract.duplicated(definitions, witnessing).each do |pair|
          report.difference(pair[0].path, pair[0].line, Sumitsubo::Contract.describe_duplicated(pair))
        end
        # A claim the registering definition does not reach implements nothing,
        # and saying nothing about it would leave the interface reported as
        # claimed nowhere with the claim in plain sight.
        Sumitsubo::Contract.misplaced(definitions, claims, reach).each do |claim|
          report.failure(claim.path, claim.line, Sumitsubo::Contract.describe_misplaced(claim))
        end
        # A claim resolving to no contract is not a difference: there is
        # nothing on the specification side to compare it against.
        Sumitsubo::Contract.unresolved(definitions, claims).each do |claim|
          report.failure(claim.path, claim.line, Sumitsubo::Contract.describe_unresolved(claim))
        end
        # The other reading makes no claims, so what it compares is what the
        # source defines and the shape a caller would have to call it with.
        spelled = Sumitsubo::Contract.reach(
          Sumitsubo::Contract.defined(definitions), config.base, config.exclusion
        )
        declared = Sumitsubo::Contract.defining(
          definitions, names_in(spelled, definitions, languages), spelled
        )
        Sumitsubo::Contract.undefined(definitions, declared).each do |finding|
          report.difference(finding.path, finding.line, Sumitsubo::Contract.describe_undefined(finding))
        end
        # Two shapes under one name are two ways in, answered where they sit
        # rather than at the specification: what a reader compares is them.
        Sumitsubo::Contract.conflicting(definitions, declared).each do |pair|
          report.difference(pair[0].path, pair[0].line, Sumitsubo::Contract.describe_conflicting(pair))
        end
        Sumitsubo::Contract.mismatched(definitions, declared, languages).each do |mismatch|
          report.difference(mismatch.path, mismatch.line, Sumitsubo::Contract.describe_mismatched(mismatch))
        end
      end

      private

      # Every word every definition claims, read in one pass: parsing is the
      # cost, so a project registering several kinds still reads each file once.
      def claims_in(reach, definitions, languages)
        claims = []
        keywords = Sumitsubo::Contract.keywords(definitions)
        Sumitsubo::Contract.scope(reach).each do |path|
          Marker.claims_in(path, keywords, languages).each do |claim|
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
          languages.declarations_in(reading.path, Where.of(reading.path), reading.language).each do |name|
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

      def verify(config, report, languages, parsers)
        features = Sumitsubo::Behavior.load(Sumitsubo::Behavior.path_in(config.root), parsers)
        Sumitsubo::Behavior.barren(features, config.base, config.exclusion, parsers).each do |barren|
          report.failure(barren.path, barren.line, Scope.describe(barren))
        end
        reach = Sumitsubo::Behavior.reach(features, config.base, config.exclusion)
        claims = claims_in(reach, languages)
        # What the reading below compares is the claims that can witness; the
        # rest answer for themselves further down.
        witnessing = Sumitsubo::Behavior.witnessing(features, claims, reach)

        Sumitsubo::Behavior.uncovered(features, witnessing).each do |finding|
          report.difference(finding.path, finding.line, Sumitsubo::Behavior.describe_uncovered(finding))
        end
        # A claim the declaring feature does not reach witnesses nothing, and
        # saying nothing about it would leave the scenario reported as claimed
        # nowhere with the claim in plain sight.
        Sumitsubo::Behavior.misplaced(features, claims, reach).each do |claim|
          report.failure(claim.path, claim.line, Sumitsubo::Behavior.describe_misplaced(claim))
        end
        # A claim resolving to no scenario is not a difference: there is nothing
        # on the specification side to compare it against.
        Sumitsubo::Behavior.unresolved(features, claims).each do |claim|
          report.failure(claim.path, claim.line, Sumitsubo::Behavior.describe_unresolved(claim))
        end
      end

      private

      # Marker finds the word and hands back the rest of the line; splitting
      # that into ids is Behavior's, which is what lets Contract read the same
      # line as one name instead.
      def claims_in(reach, languages)
        claims = []
        keywords = [Sumitsubo::Behavior::MARKER]
        Sumitsubo::Behavior.scope(reach).each do |path|
          Marker.claims_in(path, keywords, languages).each do |claim|
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
