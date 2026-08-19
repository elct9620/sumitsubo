require "json"

module Sumitsubo
  # The structured specification the Glossary mechanism verifies against.
  # Reading it can fail in a way that is not a difference between the
  # specification and the code: with no file, or an unreadable one, there is
  # no reference line to verify from at all.
  module Glossary
    DIR = ".spec"
    PATH = ".spec/glossary.json"
    GLOBAL = "Global"

    EMPTY = <<~JSON
      {
        "glossary": []
      }
    JSON

    class Error < StandardError; end

    # A designation the section rejects for the term it sits under. The
    # reason is what stops the same word being proposed again.
    Disallowed = Struct.new(:term, :reason)
    Term = Struct.new(:term, :definition, :disallowed)
    Section = Struct.new(:name, :includes, :terms)
    Finding = Struct.new(:path, :line, :column, :term, :used, :reason)

    def self.load(path = PATH)
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
    def self.scope(sections)
      effective = {}
      sections.each do |section|
        paths_for(section).each do |path|
          terms = effective[path] || {}
          section.terms.each { |term| terms[term.term] = term }
          effective[path] = terms
        end
      end
      effective
    end

    # Whole words, case sensitive, over the file as written — comments and
    # string bodies included. Narrowing that to identifiers needs an AST, and
    # what the wider read costs is a report the reader judges, which is the
    # side Sumitsubo is meant to err on.
    def self.check(scope)
      findings = []
      scope.keys.sort.each do |path|
        lines = File.readlines(path)
        terms = scope[path]
        terms.keys.sort.each do |name|
          terms[name].disallowed.each do |entry|
            findings.concat(findings_for(path, lines, name, entry))
          end
        end
      end
      # A key that leaves no ties: sorting on part of one would let Spinel and
      # CRuby order the rest differently, and the snapshot compares the two.
      findings.sort_by { |f| [f.path, f.line, f.column, f.term, f.used] }
    end

    # The pattern stays a local of this method and is never captured by a
    # block: Spinel builds no closure cell for a runtime Regexp.
    def self.findings_for(path, lines, name, entry)
      found = []
      pattern = Regexp.new("\\b" + Regexp.escape(entry.term) + "\\b")
      index = 0
      while index < lines.length
        columns_in(lines[index], pattern).each do |column|
          found.push(Finding.new(path, index + 1, column + 1, name, entry.term, entry.reason))
        end
        index += 1
      end
      found
    end

    # Walked with Regexp#match rather than String#index, which under Spinel
    # takes no Regexp argument.
    def self.columns_in(text, pattern)
      columns = []
      base = 0
      rest = text
      while true
        found = pattern.match(rest)
        break if found.nil?
        at = found.begin(0)
        columns.push(base + at)
        base = base + at + 1
        rest = rest[(at + 1), rest.length]
        break if rest.nil?
      end
      columns
    end

    def self.paths_for(section)
      found = []
      section.includes.each { |pattern| found.concat(Dir.glob(pattern)) }
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
