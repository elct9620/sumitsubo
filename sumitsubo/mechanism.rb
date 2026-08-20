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

    # What a mechanism has to say on a page. The command writes it, the way
    # Init writes a seed: where a document goes is the tool's to decide.
    #
    # A Pathname belongs in the path and does not survive in one: held in a
    # Struct member under Spinel it answers whichever Pathname was allocated
    # most recently, so a document is written wherever the last one pointed —
    # once over the reference line it was derived from. Whether it trips at all
    # turns on the build and the working directory, which is what lets it read
    # as fixed. The String is what that costs, and goes back to a Pathname once
    # the compiler keeps one.
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
      def documents(config)
        path = Sumitsubo::Glossary.path_in(config.root)
        return [] unless File.exist?(path)

        content = Sumitsubo::Glossary.render(Sumitsubo::Glossary.load(path))
        [Document.new((config.docs / "glossary.md").to_s, content)]
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

      # The documents mirror the specification: one file per feature there,
      # one here, named the same.
      def documents(config)
        found = []
        Sumitsubo::Behavior.load(Sumitsubo::Behavior.path_in(config.root)).each do |feature|
          name = Sumitsubo::Behavior.document_name(feature)
          found.push(Document.new(
            (config.docs / Sumitsubo::Behavior::DIRECTORY / "#{name}.md").to_s,
            Sumitsubo::Behavior.render(feature)
          ))
        end
        found
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

      # Marker finds the word and hands back the rest of the line; splitting
      # that into ids is Behavior's, which is what lets Contract read the same
      # line as one name instead.
      def claims_in(features, config)
        claims = []
        keywords = [Sumitsubo::Behavior::MARKER]
        Sumitsubo::Behavior.scope(features, config.base).each do |path|
          Marker.claims_in(path, keywords).each do |claim|
            Sumitsubo::Behavior.ids_in(claim.text).each do |id|
              claims.push(Sumitsubo::Behavior::Claim.new(claim.path, claim.line, id))
            end
          end
        end
        claims
      end
    end

    # The order a run reaches them in, which is the order init lays them down.
    ALL = [Glossary.new, Behavior.new]
  end
end
