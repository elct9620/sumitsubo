require "pathname"
require "sumitsubo/error"
require "sumitsubo/place"
require "sumitsubo/finding"
require "sumitsubo/check"
require "sumitsubo/source/scope"
require "sumitsubo/source/repository"

module Sumitsubo
  # The structured specification the Behavior mechanism verifies against. What
  # it establishes is that a behavior was read and implemented, never that the
  # implementation is right — that is what licenses everything this mechanism
  # cannot check.
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
    # the key a claim names, and the title is what the scenario says.
    #
    # The steps are attributes, held under the words the specification spells
    # them with. `when` and `then` could not be members — one is a keyword and
    # the other is Kernel's — and as keys they need no second spelling.

    # A claim as this mechanism reads it. Marker hands back what follows the
    # keyword unread, so what counts as an id is this mechanism's to say.
    class Claim < Data.define(:path, :line, :id)
      def key
        id
      end

      def place
        Place.new(path: path, line: line)
      end

      def said
        id
      end
    end

    # The mechanism names its own directory; where the root sits is the tool's
    # to say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / DIRECTORY
    end

    # The files each feature reaches, held under the specification that wrote
    # them. An `include` is the boundary of what a feature answers for: a
    # scenario is witnessed by the files its own feature covers, and a claim
    # from anywhere else names it without being able to witness it. That
    # boundary is what lets one root hold several components, the way a
    # glossary subdomain does.
    def self.reach(features, base, exclusion)
      found = {}
      features.each { |feature| found[feature.path] = covered(feature, base, exclusion) }
      found
    end

    # One feature's files as a set: what is asked of a claim is whether it
    # sits in there, once per claim.
    def self.covered(feature, base, exclusion)
      found = {}
      globs = feature.includes.map { |one| one.key }
      Source::Scope.of(base, globs, exclusion).each { |path| found[Place.file(base / path)] = true }
      found
    end

    # Every file any feature reaches, which is what gets read. One file
    # answering for two features is read once and asked about twice.
    def self.scope(reach)
      found = []
      reach.keys.each { |spec| found.concat(reach[spec].keys) }
      found.uniq.sort
    end

    # What each feature's includes cover, each answering at the feature that
    # wrote them.
    def self.covers(features)
      features.map { |feature| Check::Covers.new(path: feature.path, includes: feature.includes) }
    end

    # The ids one marker line carries. A claim is data rather than prose, so a
    # trailing remark becomes an id resolving to nothing, which the run reports
    # rather than quietly accepting.
    def self.ids_in(text)
      text.split(" ")
    end

    # Every claim the marker leaves in the files in reach. Marker finds the
    # word and hands back the rest of the line; splitting that into ids is this
    # mechanism's, which is what lets Contract read the same line as one name.
    def self.claimed_in(reach, source)
      found = []
      source.claims(scope(reach), [MARKER]).each do |claim|
        ids_in(claim.text).each { |id| found.push(Claim.new(path: claim.path, line: claim.line, id: id)) }
      end
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
            said: "#{MARKER} #{scenario.key}"
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
    # answers for says the scenario was implemented.
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

    # A scenario nothing claims: the specification says a behavior should be
    # implemented and no claim that could witness it does, which is a
    # difference between the two sides.
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
