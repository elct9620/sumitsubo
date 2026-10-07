require "sumitsubo/place"
require "sumitsubo/command/run"
require "sumitsubo/behavior"

module Sumitsubo
  module Command
    # Everything a run relates to one scenario: where it is declared and what
    # it says, and every place claiming it with how many others that place
    # claims beside it. A count from `stats` raises the question; this answers
    # it from the other end.
    # @command inspect
    class Inspect
      def run(config, languages, parsers, key)
        if key.nil?
          puts "inspect takes the id of a scenario"
          return 2
        end

        current = Run.new(config, languages, parsers)
        return 2 if current.rootless?

        current.relate
        return 2 if current.unread?

        return 0 unless config.verify?(Mechanism::BEHAVIOR.specification)

        features = Mechanism::BEHAVIOR.declared(config, current.specifications)
        claims = Sumitsubo::Behavior.claimed_in(current.relations, Mechanism::BEHAVIOR.specification)
        about(key, features, claims).each { |line| puts line }
        0
      end

      private

      def about(key, features, claims)
        said = []
        features.each do |feature|
          feature.statements.each do |scenario|
            next unless scenario.key == key

            said.push("#{key}  #{scenario.text}")
            said.push("  declared  #{Place.of(scenario.path, scenario.line).spoken}")
          end
        end
        claiming = claims.select { |claim| claim.key == key }
        return ["nothing declares or claims #{key}"] if said.empty? && claiming.empty?

        said.push("  declared nowhere") if said.empty?
        said.push("  claimed nowhere") if claiming.empty?
        claiming.each { |claim| said.push("  claimed   #{claim.place.spoken}#{beside(claim, claims)}") }
        said
      end

      # How many other scenarios the comment holding this claim names, and
      # whether it stands in front of anything at all.
      def beside(claim, claims)
        others = {}
        claims.each do |one|
          next unless one.path == claim.path && one.comment_line == claim.comment_line
          next if one.key == claim.key

          others[one.key] = true
        end
        said = ""
        said += "  with #{others.length} #{others.length == 1 ? "other" : "others"}" unless others.empty?
        said += "  in front of nothing" unless claim.in_front_of_code
        said
      end
    end
  end
end
