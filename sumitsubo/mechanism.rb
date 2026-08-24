require "sumitsubo/glossary"
require "sumitsubo/contract"
require "sumitsubo/behavior"
require "sumitsubo/marker"
require "sumitsubo/scope"

module Sumitsubo
  # A mechanism is a specification paired with the reading of source it is
  # checked against, which is why Behavior meets Marker here and not in its own
  # file: keeping the specification side clear of the side that reads source is
  # what leaves each of those tests able to keep a snapshot.
  #
  # A mechanism registers by being in the list: Spinel decides what an
  # executable carries when it is built, so there is no hook to register
  # through.
  #
  # The languages are handed in rather than named here, the way the revision
  # is: which ones a build carries is decided when it is built, so the one file
  # a build has of its own is where it says so. Nothing in this graph reaches a
  # grammar, which is what leaves a snapshot of it one `--regen` can write.
  module Mechanism
    # What a mechanism lays down to start a reference line from. A seed with no
    # content is a directory: a project keeps one specification per feature, so
    # there is a place rather than a file to create.
    Seed = Struct.new(:path, :content)

    # What a mechanism has to say on a page. The command writes it, the way
    # Init writes a seed: where a document goes is the tool's to decide.
    Document = Struct.new(:path, :content)

    class Glossary
      # The name .sumi.json knows this specification by.
      def specification
        "glossary"
      end

      def seed(root)
        Seed.new(Sumitsubo::Glossary.path_in(root), Sumitsubo::Glossary::EMPTY)
      end

      # An absent reference line is nothing to write rather than a comparison
      # that could not be made: Render records where Verify certifies.
      def documents(config, languages)
        path = Sumitsubo::Glossary.path_in(config.root)
        return [] unless path.exist?

        content = Sumitsubo::Glossary.render(Sumitsubo::Glossary.load(path))
        [Document.new(config.docs / "glossary.md", content)]
      end

      def verify(config, report, languages)
        path = Sumitsubo::Glossary.path_in(config.root)
        sections = Sumitsubo::Glossary.load(path)
        # An include reaching nothing is not a difference: what the words were
        # to be checked against was never read.
        Sumitsubo::Glossary.barren(sections, config.base, path, config.exclusion).each do |barren|
          report.failure(barren.path, barren.line, Scope.describe(barren))
        end
        scope = Sumitsubo::Glossary.scope(sections, config.base, config.exclusion)
        findings = Sumitsubo::Glossary.uses(
          Sumitsubo::Glossary.check(scope, config.base, languages), path, config.base
        )
        Sumitsubo::Glossary.standing(findings, sections).each do |finding|
          report.difference(
            Where.of(config.base / finding.path), finding.line,
            Sumitsubo::Glossary.describe(finding)
          )
        end
        # An ignore naming nothing is not a difference about the code: what it
        # was written against is gone, so there was nothing to compare.
        Sumitsubo::Glossary.unresolved(findings, sections).each do |stale|
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

      # The documents mirror the specification: one file per kind there, one
      # here, named the same.
      def documents(config, languages)
        found = []
        Sumitsubo::Contract.load(Sumitsubo::Contract.path_in(config.root), languages).each do |definition|
          next unless Sumitsubo::Contract.published?(definition)

          name = Sumitsubo::Contract.document_name(definition)
          found.push(Document.new(
            config.docs / Sumitsubo::Contract::DIRECTORY / "#{name}.md",
            Sumitsubo::Contract.render(definition)
          ))
        end
        found
      end

      def verify(config, report, languages)
        definitions = Sumitsubo::Contract.load(Sumitsubo::Contract.path_in(config.root), languages)
        Sumitsubo::Contract.barren(definitions, config.base, config.exclusion).each do |barren|
          report.failure(barren.path, barren.line, Scope.describe(barren))
        end
        claims = claims_in(definitions, config, languages)

        Sumitsubo::Contract.unclaimed(definitions, claims).each do |finding|
          report.difference(finding.path, finding.line, Sumitsubo::Contract.describe_unclaimed(finding))
        end
        # A contract is the way in, so a second way in is a difference about
        # the code rather than a specification that could not be read.
        Sumitsubo::Contract.duplicated(definitions, claims).each do |pair|
          report.difference(pair[0].path, pair[0].line, Sumitsubo::Contract.describe_duplicated(pair))
        end
        # A claim resolving to no contract is not a difference: there is
        # nothing on the specification side to compare it against.
        Sumitsubo::Contract.unresolved(definitions, claims).each do |claim|
          report.failure(claim.path, claim.line, Sumitsubo::Contract.describe_unresolved(claim))
        end
        # The other reading makes no claims, so what it compares is what the
        # source defines and the shape a caller would have to call it with.
        names = names_in(definitions, config, languages)
        Sumitsubo::Contract.undefined(definitions, names).each do |finding|
          report.difference(finding.path, finding.line, Sumitsubo::Contract.describe_undefined(finding))
        end
        # Two shapes under one name are two ways in, answered where they sit
        # rather than at the specification: what a reader compares is them.
        Sumitsubo::Contract.conflicting(definitions, names).each do |pair|
          report.difference(pair[0].path, pair[0].line, Sumitsubo::Contract.describe_conflicting(pair))
        end
        Sumitsubo::Contract.mismatched(definitions, names).each do |mismatch|
          report.difference(mismatch.path, mismatch.line, Sumitsubo::Contract.describe_mismatched(mismatch))
        end
      end

      private

      # Every word every definition claims, read in one pass: parsing is the
      # cost, so a project registering several kinds still reads each file once.
      def claims_in(definitions, config, languages)
        claims = []
        claimed = Sumitsubo::Contract.claimed(definitions)
        keywords = Sumitsubo::Contract.keywords(claimed)
        Sumitsubo::Contract.scope(claimed, config.base, config.exclusion).each do |path|
          Marker.claims_in(path, keywords, languages).each do |claim|
            claims.push(Sumitsubo::Contract::Claim.new(
              claim.path, claim.line, claim.keyword, claim.text
            ))
          end
        end
        claims
      end

      # What the source in scope defines, for the definitions read that way.
      # Each is read as the language it named, so a definition scanned for two
      # of them is scanned once per language rather than once.
      def names_in(definitions, config, languages)
        names = []
        Sumitsubo::Contract.defined(definitions).each do |definition|
          Sumitsubo::Contract.scope([definition], config.base, config.exclusion).each do |path|
            languages.declarations_in(path, Where.of(path), definition.language).each do |name|
              names.push(name)
            end
          end
        end
        names
      end
    end

    class Behavior
      def specification
        "behavior"
      end

      def seed(root)
        Seed.new(Sumitsubo::Behavior.path_in(root), nil)
      end

      # The documents mirror the specification: one file per feature there,
      # one here, named the same.
      def documents(config, languages)
        found = []
        Sumitsubo::Behavior.load(Sumitsubo::Behavior.path_in(config.root)).each do |feature|
          name = Sumitsubo::Behavior.document_name(feature)
          found.push(Document.new(
            config.docs / Sumitsubo::Behavior::DIRECTORY / "#{name}.md",
            Sumitsubo::Behavior.render(feature)
          ))
        end
        found
      end

      def verify(config, report, languages)
        features = Sumitsubo::Behavior.load(Sumitsubo::Behavior.path_in(config.root))
        Sumitsubo::Behavior.barren(features, config.base, config.exclusion).each do |barren|
          report.failure(barren.path, barren.line, Scope.describe(barren))
        end
        reach = Sumitsubo::Behavior.reach(features, config.base, config.exclusion)
        claims = claims_in(reach, languages)

        Sumitsubo::Behavior.uncovered(features, claims, reach).each do |finding|
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
