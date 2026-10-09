require "pathname"
require "sumitsubo/place"
require "sumitsubo/command/run"
require "sumitsubo/mechanism/behavior"

module Sumitsubo
  module Command
    # Everything a run relates to one scenario, or to one place in source. A
    # scenario answers where it is declared and every place claiming it; a
    # place answers every scenario its comment claims. A count from `stats`
    # raises the question, and this answers it from either end.
    # @command inspect
    class Inspect
      # The line a place is asked at, after the path and a colon.
      LINE = /:(\d+)\z/

      def run(config, languages, parsers, key)
        if key.nil?
          puts "inspect takes the id of a scenario, or a path with an optional line"
          return 2
        end

        current = Run.new(config, languages, parsers)
        return 2 if current.rootless?

        current.keep([Mechanism::BEHAVIOR])
        return 2 if current.unread?

        return 0 unless config.verify?(Mechanism::BEHAVIOR.specification)

        features = Mechanism::BEHAVIOR.declared(config, current.specifications)
        @relations = current.relations
        dangling = Mechanism::BEHAVIOR.dangling(@relations)
        claims = Mechanism::BEHAVIOR.claims(@relations) + dangling
        said = place?(key) ? at(key, features, claims) : about(key, features, claims, dangling)
        said.each { |line| puts line }
        0
      end

      private

      # A key naming a file, with or without a line after it, is a place.
      # An id is never a file, so the filesystem settles which was meant.
      def place?(key)
        Pathname.new(path_of(key)).file?
      end

      def path_of(key)
        found = LINE.match(key)
        found.nil? ? key : key[0, key.length - found[0].length]
      end

      # Zero where only the path was given, which asks for every comment.
      def line_of(key)
        found = LINE.match(key)
        found.nil? ? 0 : found[1].to_i
      end

      # Every comment in the file claiming a scenario, or the one holding the
      # line asked for: from where it begins to its last claim.
      def at(key, features, claims)
        path = Place.file(path_of(key))
        line = line_of(key)
        starts = []
        last = {}
        claims.each do |claim|
          next unless claim.path == path

          starts.push(claim.comment_line) if last[claim.comment_line].nil?
          last[claim.comment_line] = claim.line
        end

        said = []
        starts.each do |start|
          next unless line == 0 || (line >= start && line <= last[start])

          said.concat(comment(path, start, features, claims))
        end
        said.empty? ? ["nothing claimed at #{key}"] : said
      end

      # One comment's claims, each with where its scenario is declared.
      def comment(path, start, features, claims)
        ids = []
        first = 0
        claims.each do |claim|
          next unless claim.path == path && claim.comment_line == start

          first = claim.line if first == 0
          ids.push(claim.key) unless ids.include?(claim.key)
        end

        said = ["#{path}:#{first}  claims #{ids.length}"]
        ids.each { |id| said.push("  #{id}  #{declared(id, features)}") }
        said
      end

      # Assigned rather than returned from inside the loop: on Spinel 2026.09.12
      # and on master at e527d205d, a return from these nested blocks compiles
      # the blocks of `about` to procs answering an integer, and C refuses them.
      def declared(id, features)
        found = "declared nowhere"
        features.each do |feature|
          feature.statements.each do |scenario|
            found = "#{Place.of(scenario.path, scenario.line).spoken}  #{scenario.text}" if scenario.key == id
          end
        end
        found
      end

      def about(key, features, claims, dangling)
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
        claiming.each { |claim| said.push("  claimed   #{claim.place.spoken}#{beside(claim, dangling)}") }
        said
      end

      # How many other scenarios the comment holding this claim names, and
      # whether it stands in front of anything at all.
      def beside(claim, dangling)
        kinds = [Relation::CLAIM, Relation::DANGLING]
        mechanism = Mechanism::BEHAVIOR.specification
        others = @relations.named_in(kinds, mechanism, claim.path, claim.comment_line).reject { |one| one == claim.key }
        said = ""
        said += "  with #{others.length} #{others.length == 1 ? "other" : "others"}" unless others.empty?
        said += "  in front of nothing" if dangling.any? { |one| one.place.spoken == claim.place.spoken }
        said
      end
    end
  end
end
