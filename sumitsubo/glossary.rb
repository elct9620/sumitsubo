require "json"
require "pathname"
require "sumitsubo/error"
require "sumitsubo/locations"
require "sumitsubo/scope"
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

    # Where it names a finding to set aside, so one naming a finding that is
    # no longer there answers at its own line.
    AT = /"at"\s*:\s*"([^"]*)"/

    EMPTY = <<~JSON
      {
        "glossary": []
      }
    JSON

    class Error < Sumitsubo::Error; end

    # One finding the rejection above it does not answer for, and why that
    # line is right to say what it says. The reason is required: an exception
    # nobody explained is the one nobody dares remove.
    Ignore = Struct.new(:at, :line, :reason)

    # A designation the term it sits under rejects, and the places it is
    # rejected wrongly. The reason is what stops the same word being proposed
    # again.
    Disallowed = Struct.new(:term, :reason, :ignores)
    Term = Struct.new(:term, :definition, :disallowed)
    # One vocabulary and the files it reaches. A name declares a subdomain,
    # and the entry carrying no name is Global's.
    Section = Struct.new(:name, :includes, :terms)
    Finding = Struct.new(:path, :line, :term, :used, :reason)

    # An ignore that no longer names anything, carried with what it takes to
    # say so where the specification wrote it.
    Stale = Struct.new(:line, :at, :term, :used)

    # The mechanism names its own file; where the root sits is the tool's to
    # say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / FILE
    end

    def self.load(path)
      file = Pathname.new(path)
      where = Where.of(file)
      raise Error, "no glossary at #{where}; sumi init lays one down" unless file.exist?

      text = file.read
      begin
        document = JSON.parse(text)
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

      # JSON carries no line numbers, and an ignore has to answer at the line
      # it was written on, so where each sits is read off the text here rather
      # than the file being opened a second time later.
      lines = Locations.of(text, AT)
      sections.map { |raw| section_from(raw, where, lines) }
    end

    # A file's effective vocabulary is Global's terms with every subdomain
    # covering it laid over them, in the order the specification lists them,
    # a later term replacing an earlier one of the same name outright — its
    # disallowed list included, since a term meaning something else here
    # rejects different words. Order is all that decides which way the laying
    # goes, so Global is written first.
    def self.scope(sections, base, exclusion)
      effective = {}
      sections.each do |section|
        paths_for(section, base, exclusion).each do |path|
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

    # Every finding the specification sets aside by hand, under the key that
    # finding answers at. An ignore names one line and no more: which term is
    # rejecting and which word it rejects come from where it sits, so neither
    # can be written wrong.
    def self.set_aside(sections)
      found = {}
      sections.each do |section|
        section.terms.each do |term|
          term.disallowed.each do |entry|
            entry.ignores.each do |ignore|
              found["#{term.term} #{entry.term} #{ignore.at}"] =
                Stale.new(ignore.line, ignore.at, term.term, entry.term)
            end
          end
        end
      end
      found
    end

    # The findings a run answers for. One the specification set aside is not
    # reported: which side is wrong is not the tool's to decide, and here the
    # project has decided.
    def self.standing(findings, sections)
      aside = set_aside(sections)
      found = []
      findings.each { |finding| found.push(finding) if aside[key_of(finding)].nil? }
      found
    end

    # What was set aside and no longer names anything — the line moved, or the
    # wording was fixed. Nothing else notices, so an exception left behind
    # outlives what it was for; the run refuses to certify rather than pass.
    def self.unresolved(findings, sections)
      met = {}
      findings.each { |finding| met[key_of(finding)] = true }
      aside = set_aside(sections)
      found = []
      aside.keys.sort.each { |key| found.push(aside[key]) if met[key].nil? }
      found
    end

    # What an ignore has to name to set a finding aside, which is a finding
    # without its reason: the reason is the specification's own.
    def self.key_of(finding)
      "#{finding.term} #{finding.used} #{finding.path}:#{finding.line}"
    end

    # The mechanism words its own finding; where it points is the tool's to
    # shape.
    def self.describe(finding)
      "#{finding.term} rejects #{finding.used}: #{finding.reason}"
    end

    def self.describe_unresolved(stale)
      "nothing at #{stale.at} has #{stale.term} rejecting #{stale.used}; " \
        "the line moved or the wording was fixed"
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

    # Every include the vocabulary writes that covers no file. One entry
    # reaching nothing takes its whole vocabulary out of the run, and the
    # words it carries are then checked nowhere.
    # Every entry's includes are asked about at once: they are written in one
    # file, and a pattern two entries share is one mistake rather than two.
    def self.barren(sections, base, path)
      patterns = []
      sections.each { |section| section.includes.each { |pattern| patterns.push(pattern) } }
      Scope.barren(base, patterns.uniq, path)
    end

    # A found path is a String relative to the base: these are the keys a
    # file's vocabulary is held under, and check composes each back onto the
    # base to read it.
    def self.paths_for(section, base, exclusion)
      Scope.of(base, section.includes, exclusion).map { |path| "#{path.relative_path_from(base)}" }.uniq.sort
    end

    def self.section_from(raw, where, lines)
      Section.new(
        raw["name"] || GLOBAL,
        raw["include"] || [],
        (raw["terms"] || []).map { |term| term_from(term, where, lines) }
      )
    end

    def self.term_from(raw, where, lines)
      Term.new(
        raw["term"],
        raw["definition"],
        (raw["not"] || []).map { |entry| disallowed_from(entry, where, lines) }
      )
    end

    def self.disallowed_from(raw, where, lines)
      Disallowed.new(
        raw["term"],
        raw["reason"],
        (raw["ignore"] || []).map { |entry| ignore_from(entry, where, lines) }
      )
    end

    # Both halves are refused rather than carried empty: one with nowhere to
    # point matches nothing and reports itself, and one with no reason is the
    # exception that outlives whoever knew why.
    def self.ignore_from(raw, where, lines)
      at = raw["at"]
      if at.nil?
        raise Error, "#{where} writes an ignore with no \"at\"; " \
                     "sumi help glossary has the form"
      end
      if raw["reason"].nil?
        raise Error, "#{where} writes an ignore at #{at} with no \"reason\"; " \
                     "sumi help glossary has the form"
      end

      Ignore.new("#{at}", lines["#{at}"], raw["reason"])
    end
  end
end
