require "sumitsubo/place"
require "sumitsubo/finding/report"
require "sumitsubo/command/run"
require "sumitsubo/behavior"
require "sumitsubo/check"
require "sumitsubo/check/claim"

module Sumitsubo
  module Command
    # How each behavior specification is witnessed: the scenarios it declares,
    # the places claiming them, and the most any one place claims. One place
    # standing for many scenarios is what a reader is shown, not told off for.
    #
    # It compares nothing, so it never answers 1. What it could not read it
    # says, and answers 2, since a count missing a specification is not one.
    # @command stats
    class Stats
      # One specification's line. `at` is where the busiest place's first
      # claim sits, and empty where nothing claims a scenario at all.
      Row = Data.define(:path, :statements, :claims, :most, :at)

      def run(config, languages, parsers)
        current = Run.new(config, languages, parsers)
        return 2 if current.rootless?

        features = []
        current.each_mechanism do |mechanism|
          mechanism.relate(config, current.specifications, current.source, current.relations)
          features.concat(mechanism.declared(config, current.specifications)) if mechanism == Mechanism::BEHAVIOR
        end
        unless current.findings.code == 0
          Finding::Report.new(current.findings).said.each { |line| puts line }
          return 2
        end
        return 0 unless config.verify?(Mechanism::BEHAVIOR.specification)

        tallied(features, current.relations, Mechanism::BEHAVIOR.specification).each { |line| puts line }
        0
      end

      private

      # The claims counted are the ones verify counts: standing in front of code
      # and among the files the specification declaring their scenario reaches.
      def tallied(features, relations, mechanism)
        reach = Sumitsubo::Behavior.reach_in(features, relations)
        declaring = Sumitsubo::Behavior.declaring_in(features)
        claims = Sumitsubo::Behavior.claimed_in(relations, mechanism)
        within = Check::Claim.within(Check::Claim.in_front_of_code(claims), declaring, reach)

        rows = []
        features.each { |feature| rows.push(row(feature, within, declaring)) }
        rows = rows.sort_by { |one| [-one.most, one.path] }
        width = widest(rows, mechanism)

        said = ["#{padded(mechanism, width + 4)}statements  claims  most"]
        rows.each { |one| said.push(spoken(one, width)) }
        said.push("  #{totals(features, within)}")
        said.concat(unclaimed_files(reach, claims))
        said
      end

      # Claims in one comment are one place, however many scenarios it names.
      def row(feature, within, declaring)
        places = {}
        first = {}
        within.each do |claim|
          next unless declaring[claim.key] == feature.path

          place = "#{claim.path}:#{claim.comment_line}"
          if places[place].nil?
            places[place] = {}
            first[place] = "#{claim.path}:#{claim.line}"
          end
          places[place][claim.key] = true
        end

        most = 0
        at = ""
        places.keys.each do |place|
          next unless places[place].length > most

          most = places[place].length
          at = first[place]
        end
        Row.new(
          path: Place.file(feature.path), statements: feature.statements.length,
          claims: places.length, most: most, at: at
        )
      end

      def spoken(one, width)
        "  #{padded(one.path, width)}  #{aligned(one.statements, 10)}  #{aligned(one.claims, 6)}  " \
          "#{aligned(one.most, 4)}#{one.at.empty? ? "" : "  #{one.at}"}"
      end

      def totals(features, within)
        statements = 0
        unverifiable = 0
        deprecated = 0
        features.each do |feature|
          feature.statements.each do |scenario|
            statements += 1
            unverifiable += 1 unless Check.unverifiable(scenario.attributes).nil?
            deprecated += 1 unless scenario.attributes["deprecated"].nil?
          end
        end
        unclaimed = Check::Claim::Unclaimed.new(Mechanism::Behavior::UNCLAIMED)
                                         .run(Sumitsubo::Behavior.stated_in(features), within).length
        "#{counted(features.length, "specification")}, #{counted(statements, "statement")}, " \
          "#{unclaimed} unclaimed, #{unverifiable} unverifiable, #{deprecated} deprecated"
      end

      # The files a specification reaches that claim nothing at all, which is
      # where a project adopting its specification a piece at a time stands.
      def unclaimed_files(reach, claims)
        claimed = {}
        claims.each { |claim| claimed[claim.path] = true }
        files = Sumitsubo::Behavior.scope(reach).select { |file| claimed[file].nil? }
        return [] if files.empty?

        said = ["  reached, nothing claimed"]
        files.each { |file| said.push("    #{file}") }
        said
      end

      def widest(rows, mechanism)
        width = mechanism.length
        rows.each { |one| width = one.path.length if one.path.length > width }
        width
      end

      def padded(text, width)
        text + (" " * (width - text.length))
      end

      def aligned(count, width)
        said = count.to_s
        (" " * (width - said.length)) + said
      end

      def counted(count, noun)
        "#{count} #{noun}#{count == 1 ? "" : "s"}"
      end
    end
  end
end
