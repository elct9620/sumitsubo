require "pathname"
require "sumitsubo/error"
require "sumitsubo/place"

module Sumitsubo
  # What a feature declares, and how it is read.
  #
  # A module beside Mechanism::Behavior rather than its class methods: Spinel
  # 2026.09.12 cannot type a class method's parameter where another shares its
  # name. Master 7232a802 can, so fold these in once the pin moves past it.
  module Feature
    DIRECTORY = "behavior"

    class Error < Sumitsubo::Error; end

    # The mechanism names its own directory; where the root sits is the tool's
    # to say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / DIRECTORY
    end

    # Each scenario written before one with a lower id, with the lowest of
    # those it comes before: that one is what says where it belongs.
    def self.ahead(scenarios)
      found = []
      scenarios.each_with_index do |scenario, at|
        later = scenarios[at + 1, scenarios.length - at - 1]
        lowest = later.min { |left, right| precedence(left.key, right.key) }
        next if lowest.nil? || precedence(lowest.key, scenario.key) >= 0

        found.push([scenario, lowest])
      end
      found
    end

    # A feature's lines with its scenarios in the order of their ids. A
    # scenario carries every line up to the next one, and the blank lines
    # between two stay where they were, so the document keeps its length and
    # what precedes the first scenario is left alone.
    def self.ordered(scenarios, lines)
      starts = scenarios.map { |one| one.line - 1 }
      bodies = []
      gaps = []
      starts.each_with_index do |start, at|
        finish = at + 1 < starts.length ? starts[at + 1] : lines.length
        block = lines[start, finish - start]
        kept = block.length
        kept -= 1 while kept > 1 && block[kept - 1].strip.empty?
        bodies.push(block[0, kept])
        gaps.push(block[kept, block.length - kept])
      end
      order = (0...scenarios.length).to_a.sort { |left, right| precedence(scenarios[left].key, scenarios[right].key) }
      written = lines[0, starts[0]]
      order.each_with_index do |index, slot|
        written.concat(bodies[index])
        written.concat(gaps[slot])
      end
      written
    end

    # How two ids compare, a run of digits by its value: `F-9` comes before
    # `F-10`, which a comparison of the letters alone would put the other way.
    # Two ids of one value, `F-01` and `F-1`, fall back to their letters, since
    # a sort leaves the order of two it finds equal undecided.
    def self.precedence(left, right)
      ours = runs(left)
      theirs = runs(right)
      at = 0
      while at < ours.length && at < theirs.length
        compared = run_precedence(ours[at], theirs[at])
        return compared unless compared == 0

        at += 1
      end
      compared = ours.length <=> theirs.length
      compared == 0 ? left <=> right : compared
    end

    def self.run_precedence(left, right)
      return left.to_i <=> right.to_i if digit?(left[0]) && digit?(right[0])

      left <=> right
    end

    # An id cut wherever it turns between digits and anything else.
    def self.runs(key)
      found = []
      key.each_char do |char|
        if found.empty? || digit?(found[found.length - 1][0]) != digit?(char)
          found.push(char)
        else
          found[found.length - 1] = found[found.length - 1] + char
        end
      end
      found
    end

    def self.digit?(char)
      char >= "0" && char <= "9"
    end

    # A scenario nothing claims: the specification declares a behavior and no
    # claim that could witness it does, which is a difference between the two
    # sides.
    # A claim resolving to no scenario. Nothing on the specification side can
    # confirm it — either the specification is not there to confirm against, or
    # the behavior was removed and this claim should have gone with it. Both
    # are comparisons that could not be made rather than differences.
    # What a mechanism could not read is its own to report, so the parser's
    # refusal is answered here under this mechanism's own name.
    # Two scenarios under one id leave a marker with nothing to resolve to,
    # which is a comparison that could not be made rather than a difference.
    def self.refuse_ambiguity(features)
      seen = {}
      features.each do |feature|
        feature.statements.each do |scenario|
          where = seen[scenario.key]
          unless where.nil?
            raise Error, "#{scenario.key} is declared twice, at #{where} and #{at(scenario)}"
          end

          seen[scenario.key] = at(scenario)
        end
      end
    end

    def self.at(scenario)
      Place.of(scenario.path, scenario.line).spoken
    end
  end
end
