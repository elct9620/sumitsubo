require "json"
require "pathname"
require "sumitsubo/error"
require "sumitsubo/locations"
require "sumitsubo/specification"
require "sumitsubo/where"

module Sumitsubo
  module Parser
    # A specification as JSON, read into the shapes every mechanism judges
    # against. What the document spells its keys with, and where a line number
    # has to be recovered from because JSON carries none, are this file's and
    # nowhere else's: a mechanism asks for a specification and is handed one.
    #
    # The three questions are answered here together rather than one file each
    # because what they share is the format. Glossary answers a list because a
    # vocabulary writes its subdomains in one file, and the other two answer
    # one specification per file.
    class Json
      # Where the specification spells the values a finding has to answer at.
      # A regular expression is enough because it is looking for a key this
      # format writes, not for the shape of what the key holds.
      ID = /"id"\s*:\s*"([^"]*)"/
      NAME = /"name"\s*:\s*"([^"]*)"/
      AT = /"at"\s*:\s*"([^"]*)"/

      # Every quoted value, since an include is written as one and this format
      # gives it no key of its own to follow. First wins, as it does for every
      # other reading here: a glob is distinctive enough that the line
      # carrying it is the line that wrote it.
      SPELLED = /"([^"]*)"/

      # What a vocabulary is called where it names no subdomain of its own.
      GLOBAL = "Global"

      # The extension is the whole of what says a file is written this way. A
      # specification is named by the project rather than found by its content,
      # so nothing here opens the file to decide.
      SUFFIX = ".json"

      def reads?(path)
        "#{path}".end_with?(SUFFIX)
      end

      def behavior(path)
        text = File.read(path)
        document = parse(path, text)
        lines = Locations.of(text, ID)

        scenarios = []
        (document["scenarios"] || []).each do |raw|
          id = raw["id"]
          # A scenario nothing can name is unreferenceable, which is the same
          # ambiguity a duplicate is rather than a difference to report.
          if id.nil?
            raise Unreadable, "#{Where.of(path)} declares a scenario with no \"id\"; " \
                              "sumi help behavior has the form"
          end

          scenarios.push(scenario_from(path, raw, lines[id]))
        end

        Specification.new(
          document["name"],
          document["description"],
          document["include"] || [],
          path,
          {},
          scenarios
        )
      end

      def contract(path, languages)
        text = File.read(path)
        document = parse(path, text)
        # `"name"` is a key this specification uses at three depths — the
        # kind's own, each contract's, and each parameter's — so a value is
        # taken in the order it was written rather than looked up. A contract
        # spelled the same as the kind, or as a parameter of a contract before
        # it, would otherwise answer at that one's line.
        cursor = Locations::Cursor.new(Locations.all_in(text, NAME))
        # The kind names itself first, so passing over it is what leaves the
        # contracts to be read from where they start.
        cursor.line_of(document["name"])

        # A definition naming no marker is read from the syntax tree, so there
        # is no word to look for and none is needed.
        marker = document["marker"]
        language = language_of(path, document, marker, languages)

        interfaces = []
        (document["contracts"] || []).each do |raw|
          interfaces.push(interface_from(path, raw, marker, language, languages, cursor))
        end

        reading = {}
        reading["marker"] = [marker] unless marker.nil?
        reading["language"] = [language] unless language.nil?
        Specification.new(
          document["name"],
          document["description"],
          document["include"] || [],
          path,
          reading,
          interfaces
        )
      end

      # The line each include is written on. Asked only once one of them turned
      # out to cover nothing, so a run whose includes all reach a file never
      # reads a specification a second time.
      def spelled_in(path)
        Locations.of(File.read(path), SPELLED)
      end

      def glossary(path)
        file = Pathname.new(path)
        where = Where.of(file)
        raise Unreadable, "no glossary at #{where}; sumi init lays one down" unless file.exist?

        text = file.read
        sections = parse(path, text)["glossary"]
        if sections.nil?
          raise Unreadable, "#{where} declares no \"glossary\"; " \
                            "sumi help glossary has the form"
        end

        # JSON carries no line numbers, and an ignore has to answer at the line
        # it was written on, so where each sits is read off the text here
        # rather than the file being opened a second time later.
        lines = Locations.of(text, AT)
        sections.map { |raw| section_from(raw, where, lines) }
      end

      private

      # A step nobody wrote is no step rather than an empty one, which is what
      # leaves a shape carrying one spelled no differently from one carrying
      # several.
      def scenario_from(path, raw, line)
        steps = { "given" => raw["given"] || [] }
        steps["when"] = [raw["when"]] unless raw["when"].nil?
        steps["then"] = [raw["then"]] unless raw["then"].nil?
        Statement.new(raw["id"], raw["title"], path, line, steps, [])
      end

      def interface_from(path, raw, marker, language, languages, cursor)
        name = raw["name"]
        if name.nil?
          raise Unreadable, "#{Where.of(path)} declares a contract with no \"name\"; " \
                            "sumi help contract has the form"
        end

        if marker.nil? && !languages.definable?(language, name)
          raise Unreadable, "#{Where.of(path)} names #{name}, which no #{language} definition " \
                            "can be spelled; sumi help contract has the two readings"
        end

        # Only the syntax tree answers what a definition takes. Parameters
        # registered under a marker would be a promise nobody holds, so the
        # specification is refused rather than carried unchecked.
        if !marker.nil? && !raw["params"].nil?
          raise Unreadable, "#{Where.of(path)} gives #{name} parameters, " \
                            "which a marker leaves nothing to compare them against; " \
                            "sumi help contract has the form"
        end

        line = cursor.line_of(name)
        params = params_from(raw["params"])
        # A parameter names itself too, and passing over those is what leaves a
        # contract spelled the same as one of them answering at its own line.
        params.each { |param| cursor.line_of(param.name) } unless params.nil?

        shape = {}
        shape["params"] = params unless params.nil?
        shape["internal"] = [] if raw["internal"] == true
        Statement.new(name, raw["description"], path, line, shape, [])
      end

      # The language the syntax tree reading is written in. `include` says
      # which files a reading reaches and never what they are written in — a
      # generated file may carry one language under an extension nobody knows —
      # so a definition read that way says which, and one read through a marker
      # has nothing to say it about.
      def language_of(path, document, marker, languages)
        named = document["language"]
        unless marker.nil?
          return nil if named.nil?

          raise Unreadable, "#{Where.of(path)} names both a marker and a language, " \
                            "and a claim is a claim in whatever the file is written in; " \
                            "sumi help contract has the two readings"
        end

        if named.nil?
          raise Unreadable, "#{Where.of(path)} names no marker and no language, " \
                            "so nothing says how to spell what it registers; " \
                            "sumi help contract has the two readings"
        end
        return named if languages.carries?(named)

        raise Unreadable, "#{Where.of(path)} names #{named}, which this sumi does not carry"
      end

      def params_from(raw)
        return nil if raw.nil?

        found = []
        raw.each do |param|
          kind = param["kind"]
          found.push(Param.new(param["name"], kind.nil? ? POSITIONAL : kind, param["optional"] == true))
        end
        found
      end

      def section_from(raw, where, lines)
        Specification.new(
          raw["name"] || GLOBAL,
          nil,
          raw["include"] || [],
          where,
          {},
          (raw["terms"] || []).map { |term| term_from(term, where, lines) }
        )
      end

      # A term and a rejected word answer no line. Where each is spelled is
      # read off the raw text when a finding needs it, and reading it twice to
      # carry it here would be the second read for nothing. An ignore is the
      # one that has to answer at its own line, so it is the one the line map
      # is built for.
      def term_from(raw, where, lines)
        Statement.new(
          raw["term"],
          raw["definition"],
          where,
          nil,
          {},
          (raw["not"] || []).map { |entry| disallowed_from(entry, where, lines) }
        )
      end

      def disallowed_from(raw, where, lines)
        Statement.new(
          raw["term"],
          raw["reason"],
          where,
          nil,
          {},
          (raw["ignore"] || []).map { |entry| ignore_from(entry, where, lines) }
        )
      end

      # Both halves are refused rather than carried empty: one with nowhere to
      # point matches nothing and reports itself, and one with no reason is the
      # exception that outlives whoever knew why.
      def ignore_from(raw, where, lines)
        at = raw["at"]
        if at.nil?
          raise Unreadable, "#{where} writes an ignore with no \"at\"; " \
                            "sumi help glossary has the form"
        end
        if raw["reason"].nil?
          raise Unreadable, "#{where} writes an ignore at #{at} with no \"reason\"; " \
                            "sumi help glossary has the form"
        end

        Statement.new("#{at}", raw["reason"], where, lines["#{at}"], {}, [])
      end

      def parse(path, text)
        JSON.parse(text)
      rescue JSON::ParserError
        # The parser's own wording is Spinel's rather than CRuby's, so it stays
        # out of a message a snapshot has to match on both.
        raise Unreadable, "#{Where.of(path)} is not readable JSON"
      end
    end
  end
end
