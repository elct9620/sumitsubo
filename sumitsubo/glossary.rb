require "json"
require "pathname"
require "sumitsubo/error"
require "sumitsubo/grammar"

module Sumitsubo
  # The structured specification the Glossary mechanism verifies against.
  # Reading it can fail in a way that is not a difference between the
  # specification and the code: with no file, or an unreadable one, there is
  # no reference line to verify from at all.
  module Glossary
    FILE = "glossary.json"
    GLOBAL = "Global"

    EMPTY = <<~JSON
      {
        "glossary": []
      }
    JSON

    class Error < Sumitsubo::Error; end

    # A designation the section rejects for the term it sits under. The
    # reason is what stops the same word being proposed again.
    Disallowed = Struct.new(:term, :reason)
    Term = Struct.new(:term, :definition, :disallowed)
    Section = Struct.new(:name, :includes, :terms)
    # A stretch of a file the vocabulary is checked against, and where it starts.
    Region = Struct.new(:line, :text)
    Finding = Struct.new(:path, :line, :term, :used, :reason)

    # The mechanism names its own file; where the root sits is the tool's to
    # say, so it arrives as an argument.
    def self.path_in(root)
      (Pathname.new(root) / FILE).to_s
    end

    def self.load(path)
      raise Error, "no glossary at #{path}" unless File.exist?(path)

      begin
        document = JSON.parse(File.read(path))
      rescue JSON::ParserError
        # The parser's own wording is Spinel's, not CRuby's, so it stays out
        # of the message the snapshot has to match on both.
        raise Error, "#{path} is not readable JSON"
      end

      sections = document["glossary"]
      raise Error, "#{path} declares no \"glossary\"" if sections.nil?

      sections.map { |raw| section_from(raw) }
    end

    # A file's effective vocabulary is every matching section applied in the
    # order the specification lists them, a later term replacing an earlier
    # one of the same name outright — its disallowed list included, since a
    # term meaning something else here rejects different words.
    def self.scope(sections, base)
      effective = {}
      sections.each do |section|
        paths_for(section, base).each do |path|
          terms = effective[path] || {}
          section.terms.each { |term| terms[term.term] = term }
          effective[path] = terms
        end
      end
      effective
    end

    # Whole words, case sensitive, over the regions the vocabulary reaches.
    def self.check(scope, base)
      findings = []
      scope.keys.sort.each do |path|
        file = base / path
        # Answered the way the Output section of CLAUDE.md asks for: relative
        # to where the run started, so a reader can go straight to it.
        shown = "#{file.relative_path_from(Pathname.pwd)}"
        regions = regions_in(file.to_s, shown)
        terms = scope[path]
        terms.keys.sort.each do |name|
          terms[name].disallowed.each do |entry|
            findings.concat(findings_for(shown, regions, name, entry))
          end
        end
      end
      # A key that leaves no ties, so two runs report the same order.
      findings.sort_by { |f| [f.path, f.line, f.term, f.used] }
    end

    # Source code contributes its comments and nothing else: an identifier is a
    # spelling of a concept rather than the concept's name, and counting it
    # would flag every legitimate class in the tree. Anything else is prose,
    # which is a comment for its whole length.
    def self.regions_in(path, shown)
      return prose_in(path) unless path.end_with?(".rb")

      comments_in(path, shown)
    end

    def self.comments_in(path, shown)
      TreeSitter.capture(Grammar::RUBY, File.read(path), Grammar::COMMENTS, shown)
                .map { |capture| Region.new(capture.line, capture.text) }
    rescue TreeSitter::ParseError => e
      # Source the grammar cannot read is not a difference between the two
      # sides either: half a file yields captures the rest of it never made.
      raise Error, e.message
    end

    def self.prose_in(path)
      regions = []
      lines = File.readlines(path)
      index = 0
      while index < lines.length
        regions.push(Region.new(index + 1, lines[index]))
        index += 1
      end
      regions
    end

    # One finding per line, however often the word appears on it: the line is
    # what a reader goes to, and what an exclusion would one day be written
    # against.
    #
    # The pattern stays a local of this method and is never captured by a
    # block: Spinel builds no closure cell for a runtime Regexp.
    def self.findings_for(path, regions, name, entry)
      found = []
      pattern = Regexp.new("\\b" + Regexp.escape(entry.term) + "\\b")
      regions.each do |region|
        line = region.line
        region.text.split("\n").each do |text|
          found.push(Finding.new(path, line, name, entry.term, entry.reason)) unless pattern.match(text).nil?
          line += 1
        end
      end
      found
    end

    # Globs are answered against the base, which is where the configuration
    # was found, so a run from a subdirectory reaches the same files.
    def self.paths_for(section, base)
      found = []
      section.includes.each do |pattern|
        # Interpolated to settle the element type, as the binding's decoder is.
        base.glob(pattern).each { |path| found.push("#{path.relative_path_from(base)}") }
      end
      found.uniq.sort
    end

    def self.section_from(raw)
      Section.new(
        raw["name"] || GLOBAL,
        raw["include"] || [],
        (raw["terms"] || []).map { |term| term_from(term) }
      )
    end

    def self.term_from(raw)
      Term.new(
        raw["term"],
        raw["definition"],
        (raw["not"] || []).map { |entry| Disallowed.new(entry["term"], entry["reason"]) }
      )
    end
  end
end
