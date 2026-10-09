require "pathname"
require "sumitsubo/error"
require "sumitsubo/place"
require "sumitsubo/finding"
require "sumitsubo/check"
require "sumitsubo/reach"
require "sumitsubo/source/repository"
require "sumitsubo/relation"

module Sumitsubo
  # The structured specification the Behavior mechanism verifies against. What
  # it establishes is that a behavior was read and a test witnesses it, never
  # that the implementation is right — that is what licenses everything this
  # mechanism cannot check.
  #
  # Nothing here names the grammar, which is what keeps this file's test on the
  # side that --regen can still write a snapshot for.
  module Behavior
    DIRECTORY = "behavior"

    # The mechanism names its own marker, as it names its own directory. A
    # later mechanism claims its own word rather than sharing this one.
    MARKER = "@behavior"

    class Error < Sumitsubo::Error; end

    # A feature is a Specification and its scenarios are Statements: an id is
    # the key a claim names, and the title is what the scenario says. Its steps
    # are Statements under it, each keyed by the word it is spelled with.

    # A claim as this mechanism reads it. Marker hands back what follows the
    # keyword unread, so what counts as an id is this mechanism's to say.
    class Claim < Data.define(:path, :line, :comment_line, :id)
      def key
        id
      end

      def place
        Place.new(path: path, line: line)
      end

      # A claim with no id says the marker instead: what a reader has to be
      # told is that the word was written with nothing behind it.
      def said
        id.empty? ? MARKER : id
      end
    end

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

    # The ids one marker line carries. A claim is data rather than prose, so a
    # trailing remark becomes an id resolving to nothing, which the run reports
    # rather than quietly accepting.
    def self.ids_in(text)
      text.split(" ")
    end

    # Every marker left in the files the features reach, kept as relations
    # under the mechanism's name: a claim where code stands below it, dangling
    # where nothing does. Marker finds the word and hands back the rest of the
    # line; splitting that into ids is this mechanism's, which is what lets
    # Contract read the same line as one name.
    def self.relate(reach, source, relations, mechanism)
      marked = source.marked(Reach.files(reach), [MARKER])
      marked.claims.each do |claim|
        referred(claim, mechanism).each { |one| relations.add(Relation.claim(claim, one)) }
      end
      marked.dangling.each do |claim|
        referred(claim, mechanism).each { |one| relations.add(Relation.dangling(claim, one)) }
      end
    end

    # The statements one marker names, one for each id.
    def self.referred(claim, mechanism)
      named_in(claim).map { |id| Relation::Reference.new(mechanism: mechanism, key: id) }
    end

    # The claims the run kept for this mechanism, read back as it compares them.
    def self.claimed_in(relations, mechanism)
      read(relations.naming(Relation::CLAIM, mechanism))
    end

    # The markers the run kept for this mechanism with no code below them.
    def self.dangling_in(relations, mechanism)
      read(relations.naming(Relation::DANGLING, mechanism))
    end

    def self.read(relations)
      found = []
      relations.each do |one|
        found.push(Claim.new(
          path: one.subject.path, line: one.subject.line, comment_line: one.subject.comment_line, id: one.object.key
        ))
      end
      found
    end

    # The ids one claim carries, or the empty one where it carries none. A
    # marker written with nothing behind it still claims: dropping it would be
    # this mechanism deciding nobody meant to write the word.
    def self.named_in(claim)
      found = ids_in(claim.text)
      found.empty? ? [""] : found
    end

    # A claim carrying nothing after the marker names no scenario at all, which
    # is a different thing to say than an id that resolves to none, so the two
    # are answered apart.
    def self.nameless(claims)
      found = []
      claims.each do |claim|
        next unless claim.id.empty?

        found.push(Check::Made.new(key: claim.key, place: claim.place, said: claim.said))
      end
      found
    end

    def self.named(claims)
      found = []
      claims.each { |claim| found.push(claim) unless claim.id.empty? }
      found
    end

    # Every scenario a claim could name, said the way a claim says it.
    def self.stated_in(features)
      found = []
      features.each do |feature|
        feature.statements.each do |scenario|
          found.push(Check::Stated.new(
            key: scenario.key,
            place: Place.of(scenario.path, scenario.line),
            said: "#{MARKER} #{scenario.key}",
            unverifiable: Check.unverifiable(scenario.attributes)
          ))
        end
      end
      found
    end

    # The claims that can witness: each sitting among the files the feature
    # declaring its scenario answers for. Filtering once is what leaves the
    # reading below unchanged — a scenario is claimed by the claims that count.
    # A claim naming a scenario the feature declaring it does not reach. The
    # id resolves, so neither side is wrong about the behavior; what could not
    # be made is the comparison, since nothing among the files that feature
    # answers for witnesses the scenario.
    #
    # Saying nothing about it would leave the scenario reported as claimed
    # nowhere with the claim in plain sight.
    # Which specification declares each scenario, so a claim can be asked
    # whether it sits where that specification can see it. One id belongs to
    # one feature, which is what refuse_ambiguity guarantees.
    def self.declaring_in(features)
      found = {}
      features.each do |feature|
        feature.statements.each { |scenario| found[scenario.key] = feature.path }
      end
      found
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
