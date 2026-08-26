require "pathname"
require "sumitsubo/error"
require "sumitsubo/where"
require "sumitsubo/parser"
require "sumitsubo/scope"

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

    # A scenario nothing claims. It answers at the specification that declares
    # it, which is also where the include that bounded the search is written,
    # so the finding names neither.
    Finding = Struct.new(:path, :line, :id)
    # A claim as this mechanism reads it. Marker hands back what follows the
    # keyword unread, so what counts as an id is this mechanism's to say.
    Claim = Struct.new(:path, :line, :id)
    # A claim naming a scenario that is really there, from a file the feature
    # declaring it does not include. What it carries is that feature rather
    # than its includes: the fix is written there, and a feature reaching
    # dozens of files would otherwise spell all of them at the reader.
    Misplaced = Struct.new(:path, :line, :id, :spec)

    # The mechanism names its own directory; where the root sits is the tool's
    # to say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / DIRECTORY
    end

    # Every feature the directory holds. A directory nobody wrote declares no
    # scenarios, and a project that has said nothing is not misconfigured, so
    # that answers empty rather than failing.
    #
    # The parsers are handed in the way the languages are: which formats a
    # build carries is decided when it is built, so nothing here names one.
    def self.load(directory, parsers)
      path = Pathname.new(directory)
      return [] unless path.directory?

      features = files_in(path).map { |file| feature_from(file, parsers) }
      refuse_ambiguity(features)
      features
    end

    # A found path is a String: it is what a feature answers with, and what a
    # finding about one of its scenarios points at.
    def self.files_in(path)
      path.glob("*.json").map { |file| "#{file}" }.sort
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
      Scope.of(base, feature.includes, exclusion).each { |path| found[Where.of(base / path)] = true }
      found
    end

    # Every file any feature reaches, which is what gets read. One file
    # answering for two features is read once and asked about twice.
    def self.scope(reach)
      found = []
      reach.keys.each { |spec| found.concat(reach[spec].keys) }
      found.uniq.sort
    end

    # Every include a feature writes that covers no file. Its scenarios are
    # then compared against nothing, which answers as though every one of them
    # were claimed.
    def self.barren(features, base, exclusion)
      found = []
      features.each do |feature|
        Scope.barren(base, feature.includes, feature.path, exclusion).each { |one| found.push(one) }
      end
      found
    end

    # The ids one marker line carries. A claim is data rather than prose, so a
    # trailing remark becomes an id resolving to nothing, which the run reports
    # rather than quietly accepting.
    def self.ids_in(text)
      text.split(" ")
    end

    # The claims that can witness: each sitting among the files the feature
    # declaring its scenario answers for. Filtering once is what leaves the
    # reading below unchanged — a scenario is claimed by the claims that count.
    def self.witnessing(features, claims, reach)
      declaring = declaring_in(features)
      found = []
      claims.each do |claim|
        spec = declaring[claim.id]
        next if spec.nil?
        next if reach[spec][claim.path].nil?

        found.push(claim)
      end
      found
    end

    # A claim naming a scenario the feature declaring it does not reach. The
    # id resolves, so neither side is wrong about the behavior; what could not
    # be made is the comparison, since nothing among the files that feature
    # answers for says the scenario was implemented.
    def self.misplaced(features, claims, reach)
      declaring = declaring_in(features)
      found = []
      claims.each do |claim|
        spec = declaring[claim.id]
        next if spec.nil?
        next unless reach[spec][claim.path].nil?

        found.push(Misplaced.new(claim.path, claim.line, claim.id, Where.of(spec)))
      end
      found
    end

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
    def self.uncovered(features, claims)
      claimed = {}
      claims.each { |claim| claimed[claim.id] = true }

      found = []
      features.each do |feature|
        feature.statements.each do |scenario|
          next unless claimed[scenario.key].nil?

          found.push(Finding.new(Where.of(scenario.path), scenario.line, scenario.key))
        end
      end
      found
    end

    # A claim resolving to no scenario. Nothing on the specification side can
    # confirm it — either the specification is not there to confirm against, or
    # the behavior was removed and this claim should have gone with it. Both
    # are comparisons that could not be made rather than differences.
    def self.unresolved(features, claims)
      declared = {}
      features.each do |feature|
        feature.statements.each { |scenario| declared[scenario.key] = true }
      end

      found = []
      claims.each { |claim| found.push(claim) if declared[claim.id].nil? }
      found
    end

    # The mechanism words its own findings; where each points is the tool's to
    # shape.
    def self.describe_uncovered(finding)
      "#{MARKER} #{finding.id} is claimed nowhere this specification includes"
    end

    def self.describe_unresolved(claim)
      "#{claim.id} resolves to no scenario"
    end

    def self.describe_misplaced(claim)
      "#{claim.id} is claimed outside what #{claim.spec} includes"
    end

    # What a mechanism could not read is its own to report, so the parser's
    # refusal is answered here under this mechanism's own name.
    def self.feature_from(path, parsers)
      Parser.of(path, parsers).behavior(path)
    rescue Sumitsubo::Unreadable => e
      raise Error, e.message
    end

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
      "#{Where.of(scenario.path)}:#{scenario.line}"
    end
  end
end
