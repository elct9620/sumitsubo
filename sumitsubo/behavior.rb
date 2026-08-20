require "json"
require "pathname"
require "sumitsubo/error"

module Sumitsubo
  # The structured specification the Behavior mechanism verifies against. What
  # it establishes is that a behavior was read and implemented, never that the
  # implementation is right — that is what licenses everything this mechanism
  # cannot check.
  #
  # Nothing here names the grammar. That is what lets this file's test run
  # under CRuby — see the Build section of CLAUDE.md for what --regen cannot
  # reach.
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
    Feature = Struct.new(:name, :description, :includes, :scenarios)

    # The mechanism names its own directory; where the root sits is the tool's
    # to say, so it arrives as an argument.
    def self.path_in(root)
      (Pathname.new(root) / DIRECTORY).to_s
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

    # Interpolated to settle the element type, as Glossary's globbing is.
    def self.files_in(path)
      found = []
      path.glob("*.json").each { |file| found.push("#{file}") }
      found.sort
    end

    def self.feature_from(path)
      text = File.read(path)
      document = parse(path, text)
      lines = locations_in(text)

      scenarios = []
      (document["scenarios"] || []).each do |raw|
        id = raw["id"]
        # A scenario nothing can name is unreferenceable, which is the same
        # ambiguity a duplicate is rather than a difference to report.
        raise Error, "#{shown(path)} declares a scenario with no \"id\"" if id.nil?

        scenarios.push(scenario_from(path, raw, lines[id]))
      end

      Feature.new(
        document["name"],
        document["description"],
        document["include"] || [],
        scenarios
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

    # Where each id sits, so a finding about a scenario nothing declares can
    # answer at the specification — which is where a reader goes to choose
    # between writing the test and dropping the scenario.
    def self.locations_in(text)
      found = {}
      line = 0
      text.split("\n").each do |content|
        line += 1
        match = ID.match(content)
        next if match.nil?

        found[match[1]] = line if found[match[1]].nil?
      end
      found
    end

    # Two scenarios under one id leave a marker with nothing to resolve to,
    # which is a comparison that could not be made rather than a difference —
    # see the Output section of CLAUDE.md.
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
      raise Error, "#{shown(path)} is not readable JSON"
    end

    def self.at(scenario)
      "#{shown(scenario.path)}:#{scenario.line}"
    end

    # Answered the way a finding is, relative to where the run started, so a
    # reader can go straight to it — see the Output section of CLAUDE.md. The
    # root arrives absolute, which is why expanding comes first.
    def self.shown(path)
      "#{Pathname.new(path).expand_path.relative_path_from(Pathname.pwd)}"
    end
  end
end
