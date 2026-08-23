require "json"
require "pathname"
require "sumitsubo/error"
require "sumitsubo/locations"
require "sumitsubo/where"

module Sumitsubo
  # The structured specification the Glossary mechanism verifies against.
  # Reading it can fail in a way that is not a difference between the
  # specification and the code: with no file, or an unreadable one, there is
  # no reference line to verify from at all.
  module Glossary
    FILE = "glossary.json"
    GLOBAL = "Global"

    # Where the specification spells a word, whether as a term or as one a
    # term rejects. Both spellings declare, and neither uses.
    TERM = /"term"\s*:\s*"([^"]*)"/

    EMPTY = <<~JSON
      {
        "glossary": []
      }
    JSON

    class Error < Sumitsubo::Error; end

    # A designation the term it sits under rejects. The reason is what stops
    # the same word being proposed again.
    Disallowed = Struct.new(:term, :reason)
    Term = Struct.new(:term, :definition, :disallowed)
    # One vocabulary and the files it reaches. A name declares a subdomain,
    # and the entry carrying no name is Global's.
    Section = Struct.new(:name, :includes, :terms)
    Finding = Struct.new(:path, :line, :term, :used, :reason)

    # The mechanism names its own file; where the root sits is the tool's to
    # say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / FILE
    end

    def self.load(path)
      file = Pathname.new(path)
      where = Where.of(file)
      raise Error, "no glossary at #{where}; sumi init lays one down" unless file.exist?

      begin
        document = JSON.parse(file.read)
      rescue JSON::ParserError
        # The parser's own wording is Spinel's, not CRuby's, so it stays out
        # of the message the snapshot has to match on both.
        raise Error, "#{where} is not readable JSON"
      end

      sections = document["glossary"]
      if sections.nil?
        raise Error, "#{where} declares no \"glossary\"; " \
                     "sumi help glossary has the form"
      end

      sections.map { |raw| section_from(raw) }
    end

    # A file's effective vocabulary is Global's terms with every subdomain
    # covering it laid over them, in the order the specification lists them,
    # a later term replacing an earlier one of the same name outright — its
    # disallowed list included, since a term meaning something else here
    # rejects different words. Order is all that decides which way the laying
    # goes, so Global is written first.
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
    #
    # A finding answers at the path the vocabulary is scoped by, which is the
    # one the specification writes its includes in; rendering it for a reader
    # is the tool's, and happens once at the edge. What a person wrote is read
    # by the language answering for the file, and that arrives from outside:
    # this mechanism checks a vocabulary and names no language, which is what
    # leaves a second one to be carried without it being touched.
    def self.check(scope, base, languages)
      findings = []
      scope.keys.sort.each do |path|
        file = base / path
        regions = languages.comments_in(file, Where.of(file))
        terms = scope[path]
        terms.keys.sort.each do |name|
          terms[name].disallowed.each do |entry|
            findings.concat(findings_for(path, regions, name, entry))
          end
        end
      end
      # A key that leaves no ties, so two runs report the same order.
      findings.sort_by { |f| [f.path, f.line, f.term, f.used] }
    end

    # The findings that are uses of a rejected word rather than the
    # specification spelling one. A word has to be spelled to be declared
    # rejected, so a glossary its own includes cover would report against
    # itself every rejection it declares.
    #
    # JSON carries no line numbers, so where each word is spelled is read off
    # the raw text, which is what Locations is for.
    def self.uses(findings, path, base)
      # Composed against the base whether the caller named the glossary from
      # there or from the root it already holds: an absolute one answers
      # itself, so a caller is not made to say where it is twice.
      file = base / path
      where = "#{file.relative_path_from(base)}"
      spelled = {}
      Locations.all_in(file.read, TERM).each { |at| spelled["#{at.line} #{at.text}"] = true }

      found = []
      findings.each do |finding|
        next if finding.path == where && spelled["#{finding.line} #{finding.used}"]

        found.push(finding)
      end
      found
    end

    # The mechanism words its own finding; where it points is the tool's to
    # shape.
    def self.describe(finding)
      "#{finding.term} rejects #{finding.used}: #{finding.reason}"
    end

    # The mechanism words its own document, as it words its own findings. Only
    # the terms are rendered: what a term rejects is a record of where this
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

    # One finding per line, however often the word appears on it: the line is
    # what a reader goes to, and what an exclusion would one day be written
    # against.
    def self.findings_for(path, regions, name, entry)
      found = []
      # Spelled rather than passed on: both arrive as keys of a hash, which
      # reaches the compiler carrying no type, and a Finding built from one
      # gets integer members where it should hold text. Spinel 2026-08-22;
      # drop the spelling once a key arrives knowing what it is.
      where = "#{path}"
      term = "#{name}"
      pattern = Regexp.new("\\b" + Regexp.escape(entry.term) + "\\b")
      regions.each do |region|
        line = region.line
        region.text.split("\n").each do |text|
          found.push(Finding.new(where, line, term, entry.term, entry.reason)) unless pattern.match(text).nil?
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
        # A found path is a String: these are the keys a file's vocabulary is
        # held under, and check composes each back onto the base to read it.
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
