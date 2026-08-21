require "json"
require "pathname"
require "sumitsubo/error"
require "sumitsubo/where"
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
      Pathname.new(root) / FILE
    end

    def self.load(path)
      file = Pathname.new(path)
      where = Where.of(file)
      raise Error, "no glossary at #{where}" unless file.exist?

      begin
        document = JSON.parse(file.read)
      rescue JSON::ParserError
        # The parser's own wording is Spinel's, not CRuby's, so it stays out
        # of the message the snapshot has to match on both.
        raise Error, "#{where} is not readable JSON"
      end

      sections = document["glossary"]
      raise Error, "#{where} declares no \"glossary\"" if sections.nil?

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
        where = Where.of(file)
        regions = regions_in(file, where)
        terms = scope[path]
        terms.keys.sort.each do |name|
          terms[name].disallowed.each do |entry|
            findings.concat(findings_for(where, regions, name, entry))
          end
        end
      end
      # A key that leaves no ties, so two runs report the same order.
      findings.sort_by { |f| [f.path, f.line, f.term, f.used] }
    end

    # The mechanism words its own finding; where it points is the tool's to
    # shape. See the Output section of CLAUDE.md.
    def self.describe(finding)
      "#{finding.term} rejects #{finding.used}: #{finding.reason}"
    end

    # The mechanism words its own document, as it words its own findings. Only
    # the terms are rendered: what a section rejects is a record of where this
    # project drifted rather than vocabulary, and the tool hands it to a reader
    # at the line it was tripped on.
    def self.render(sections)
      lines = ["# Glossary", ""]
      sections.each do |section|
        lines.push("## #{section.name}", "") unless section.name == GLOBAL
        lines.push("| Term | Definition |", "| --- | --- |")
        section.terms.each { |term| lines.push("| #{cell(term.term)} | #{cell(term.definition)} |") }
        lines.push("")
      end
      lines.join("\n")
    end

    # A bar would end the cell it sits in, so it is spelled rather than left to
    # split the table.
    def self.cell(text)
      "#{text}".split("|").join("\\|")
    end

    # Source code contributes its comments and nothing else: an identifier is a
    # spelling of a concept rather than the concept's name, and counting it
    # would flag every legitimate class in the tree. Anything else is prose,
    # which is a comment for its whole length.
    def self.regions_in(path, where)
      return prose_in(path) unless path.extname == ".rb"

      comments_in(path, where)
    end

    def self.comments_in(path, where)
      TreeSitter.capture(Grammar::RUBY, path.read, Grammar::COMMENTS, where)
                .map { |capture| Region.new(capture.line, capture.text) }
    rescue TreeSitter::ParseError => e
      # Source the grammar cannot read is not a difference between the two
      # sides either: half a file yields captures the rest of it never made.
      raise Error, e.message
    end

    def self.prose_in(path)
      regions = []
      lines = path.readlines
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
