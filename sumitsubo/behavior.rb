require "json"
require "pathname"
require "sumitsubo/error"
require "sumitsubo/where"
require "sumitsubo/locations"
require "sumitsubo/note"

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

    # A scenario's id as it sits in the raw text. JSON carries no line numbers,
    # and a scenario nothing declares has no source line to answer with.
    ID = /"id"\s*:\s*"([^"]*)"/

    class Error < Sumitsubo::Error; end

    # `when` and `then` are how the specification spells these, but `then` is
    # already Kernel's and `when` is a keyword. An identifier is a spelling of
    # the concept rather than its name, so the members take the safe spelling.
    Scenario = Struct.new(:id, :title, :given, :action, :outcome, :path, :line)
    # The path is what names the document Render writes: one file per feature
    # on the specification side, one on the document side.
    #
    # Notes hang from the feature and not from a scenario. A scenario names
    # the observable difference and stops, its reason carried by the title;
    # somewhere legitimate to write that reason instead is what would let it
    # stop being carried there.
    Feature = Struct.new(:name, :description, :includes, :scenarios, :path, :notes)
    # A scenario nothing claims. The scope is carried so the finding can say
    # where it looked rather than claiming no test exists anywhere.
    Finding = Struct.new(:path, :line, :id, :scope)
    # A claim as this mechanism reads it. Marker hands back what follows the
    # keyword unread, so what counts as an id is this mechanism's to say.
    Claim = Struct.new(:path, :line, :id)

    # The mechanism names its own directory; where the root sits is the tool's
    # to say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / DIRECTORY
    end

    # Every feature the directory holds. A directory nobody wrote declares no
    # scenarios, and a project that has said nothing is not misconfigured, so
    # that answers empty rather than failing.
    def self.load(directory)
      path = Pathname.new(directory)
      return [] unless path.directory?

      features = []
      files_in(path).each { |file| features.push(feature_from(file)) }
      refuse_ambiguity(features)
      features
    end

    # A found path is a String: it is what a feature answers with, and what a
    # finding about one of its scenarios points at.
    def self.files_in(path)
      found = []
      path.glob("*.json").each { |file| found.push("#{file}") }
      found.sort
    end

    # Every file any feature reaches. Globs are answered against the base,
    # which is where the configuration was found, so a run from a subdirectory
    # reaches the same files. The union is what gets scanned: `include` narrows
    # the search rather than tying a scenario to one place.
    def self.scope(features, base)
      found = []
      features.each do |feature|
        feature.includes.each do |pattern|
          base.glob(pattern).each { |path| found.push(Where.of(path)) }
        end
      end
      found.uniq.sort
    end

    # The ids one marker line carries. A claim is data rather than prose, so a
    # trailing remark becomes an id resolving to nothing, which the run reports
    # rather than quietly accepting.
    def self.ids_in(text)
      text.split(" ")
    end

    # A scenario nothing claims: the specification says a behavior should be
    # implemented and no source in scope claims it, which is a difference
    # between the two sides.
    def self.uncovered(features, claims)
      claimed = {}
      claims.each { |claim| claimed[claim.id] = true }

      found = []
      features.each do |feature|
        feature.scenarios.each do |scenario|
          next unless claimed[scenario.id].nil?

          found.push(Finding.new(Where.of(scenario.path), scenario.line, scenario.id, feature.includes))
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
        feature.scenarios.each { |scenario| declared[scenario.id] = true }
      end

      found = []
      claims.each { |claim| found.push(claim) if declared[claim.id].nil? }
      found
    end

    # The mechanism words its own findings; where each points is the tool's to
    # shape.
    def self.describe_uncovered(finding)
      "#{MARKER} #{finding.id} is claimed nowhere in #{finding.scope.join(", ")}"
    end

    def self.describe_unresolved(claim)
      "#{claim.id} resolves to no scenario"
    end

    # The mechanism words its own document, as it words its own findings. A
    # scenario is sentences rather than fields, so the table carries one step
    # per row instead of one scenario per row.
    def self.render(feature)
      lines = ["# #{feature.name || document_name(feature)}", ""]
      lines.push(feature.description, "") unless feature.description.nil?
      Note.spell(feature.notes, 1).each { |line| lines.push(line) }

      feature.scenarios.each do |scenario|
        lines.push("## #{scenario.id} — #{scenario.title}", "")
        lines.push("| Step | Statement |", "| --- | --- |")
        scenario.given.each { |given| lines.push("| Given | #{cell(given)} |") }
        lines.push("| When | #{cell(scenario.action)} |")
        lines.push("| Then | #{cell(scenario.outcome)} |")
        lines.push("")
      end
      lines.join("\n")
    end

    # What a feature is called on the document side: the file declaring it,
    # since one file there is one document here. It stands in for a feature
    # that named itself nothing.
    def self.document_name(feature)
      "#{Pathname.new(feature.path).basename(".json")}"
    end

    # A bar would end the cell it sits in, so it is spelled rather than left to
    # split the table.
    def self.cell(text)
      "#{text}".split("|").join("\\|")
    end

    def self.feature_from(path)
      text = File.read(path)
      document = parse(path, text)
      lines = Locations.of(text, ID)

      scenarios = []
      (document["scenarios"] || []).each do |raw|
        id = raw["id"]
        # A scenario nothing can name is unreferenceable, which is the same
        # ambiguity a duplicate is rather than a difference to report.
        if id.nil?
          raise Error, "#{Where.of(path)} declares a scenario with no \"id\"; " \
                       "sumi help behavior has the form"
        end

        scenarios.push(scenario_from(path, raw, lines[id]))
      end

      Feature.new(
        document["name"],
        document["description"],
        document["include"] || [],
        scenarios,
        path,
        Note.all_in(path, document["notes"], "behavior")
      )
    end

    def self.scenario_from(path, raw, line)
      Scenario.new(
        raw["id"],
        raw["title"],
        raw["given"] || [],
        raw["when"],
        raw["then"],
        path,
        line
      )
    end

    # Two scenarios under one id leave a marker with nothing to resolve to,
    # which is a comparison that could not be made rather than a difference.
    def self.refuse_ambiguity(features)
      seen = {}
      features.each do |feature|
        feature.scenarios.each do |scenario|
          where = seen[scenario.id]
          unless where.nil?
            raise Error, "#{scenario.id} is declared twice, at #{where} and #{at(scenario)}"
          end

          seen[scenario.id] = at(scenario)
        end
      end
    end

    def self.parse(path, text)
      JSON.parse(text)
    rescue JSON::ParserError
      # The parser's own wording is Spinel's rather than CRuby's, so it stays
      # out of a message a snapshot has to match on both.
      raise Error, "#{Where.of(path)} is not readable JSON"
    end

    def self.at(scenario)
      "#{Where.of(scenario.path)}:#{scenario.line}"
    end
  end
end
