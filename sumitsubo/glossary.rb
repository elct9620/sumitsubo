require "pathname"
require "sumitsubo/error"
require "sumitsubo/parser"
require "sumitsubo/scope"
require "sumitsubo/specification"
require "sumitsubo/where"

module Sumitsubo
  # The structured specification the Glossary mechanism verifies against.
  # Reading it can fail in a way that is not a difference between the
  # specification and the code: with no file, or an unreadable one, there is
  # no reference line to verify from at all.
  module Glossary
    FILE = "glossary.md"

    # The checks this specification answers for, so a finding is told apart by
    # which one found it rather than by its wording.
    BARREN = "glossary/barren"
    REJECTED = "glossary/rejected"
    UNRESOLVED = "glossary/unresolved"

    # What a project starts a vocabulary from. A title and nothing else is a
    # vocabulary that checks nothing, which is what a root nobody has written
    # words for should say.
    SEED = <<~MARKDOWN
      # Glossary

      The words this project keeps, and the ones it turns down in their place.
    MARKDOWN

    class Error < Sumitsubo::Error; end

    # A vocabulary is one Specification and everything under it a Statement:
    # a section holds the terms it declares, a term's text is its definition, a
    # rejected word sits under the term rejecting it with the reason as its
    # text, and a line set aside sits under that word.
    #
    # Each of them earns a statement of its own by being pointed at — an ignore
    # names the rejection it is written under, and a finding names the word and
    # the term together. A section's boundary is not pointed at by anything, so
    # it is an attribute of that section rather than a statement.
    Finding = Struct.new(:path, :line, :term, :used, :reason)

    # An ignore that no longer names anything, carried with what it takes to
    # say so where the specification wrote it.
    Stale = Struct.new(:line, :at, :term, :used)

    # The mechanism names its own file; where the root sits is the tool's to
    # say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / FILE
    end

    # The parsers are handed in the way the languages are: which formats a
    # build carries is decided when it is built, so nothing here names one.
    # What a mechanism could not read is its own to report, so the parser's
    # refusal is answered under this mechanism's name.
    def self.load(path, parsers)
      Parser.of(path, parsers).glossary(path)
    rescue Sumitsubo::Unreadable => e
      raise Error, e.message
    end

    # A file's effective vocabulary is every section covering it laid over the
    # ones before it, in the order the specification lists them, a later term
    # replacing an earlier one of the same name outright — the words it rejects
    # included, since a term meaning something else here rejects different
    # words. Order is all that decides which way the laying goes, which is why
    # the sections share one specification: the order is written in it.
    def self.scope(spec, base, exclusion)
      effective = {}
      spec.statements.each do |section|
        paths_for(section, base, exclusion).each do |path|
          effective[path] = laid_over(effective[path], section.statements)
        end
      end
      effective
    end

    # One section's terms laid over what a path already had, a later term of
    # the same name replacing an earlier one outright.
    def self.laid_over(terms, statements)
      laid = terms.nil? ? {} : terms
      statements.each { |term| laid[term.key] = term }
      laid
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
          terms[name].statements.each do |entry|
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
    # Which line declares is the reading's answer rather than a pattern's: the
    # specification says where each word was written, so nothing here opens the
    # file a second time or knows how a format spells a declaration.
    def self.uses(findings, spec)
      spelled = declared_in(spec)
      found = []
      findings.each do |finding|
        next if finding.path == spec.path && spelled["#{finding.line} #{finding.used}"]

        found.push(finding)
      end
      found
    end

    # Every line the specification spells a word on, whether as a term or as
    # one a term rejects. Both spellings declare, and neither uses.
    def self.declared_in(spec)
      spelled = {}
      spec.statements.each { |section| section.statements.each { |term| spells(term, spelled) } }
      spelled
    end

    # The lines one term spells a word on: its own, and each word it rejects.
    def self.spells(term, spelled)
      spelled["#{term.line} #{term.key}"] = true
      term.statements.each { |word| spelled["#{word.line} #{word.key}"] = true }
    end

    # Every finding the specification sets aside by hand, under the key that
    # finding answers at. An ignore names one line and no more: which term is
    # rejecting and which word it rejects come from where it sits, so neither
    # can be written wrong.
    def self.set_aside(spec)
      found = {}
      spec.statements.each { |section| section.statements.each { |term| sets_aside(term, found) } }
      found
    end

    # Every line one term sets aside, under the key the finding it answers to
    # is held by.
    def self.sets_aside(term, found)
      term.statements.each do |entry|
        entry.statements.each do |ignore|
          found["#{term.key} #{entry.key} #{ignore.key}"] =
            Stale.new(ignore.line, ignore.key, term.key, entry.key)
        end
      end
    end

    # The findings a run answers for. One the specification set aside is not
    # reported: which side is wrong is not the tool's to decide, and here the
    # project has decided.
    def self.standing(findings, spec)
      aside = set_aside(spec)
      found = []
      findings.each { |finding| found.push(finding) if aside[key_of(finding)].nil? }
      found
    end

    # What was set aside and no longer names anything — the line moved, or the
    # wording was fixed. Nothing else notices, so an exception left behind
    # outlives what it was for; the run refuses to certify rather than pass.
    def self.unresolved(findings, spec)
      met = {}
      findings.each { |finding| met[key_of(finding)] = true }
      aside = set_aside(spec)
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

    # One finding per line, however often the word appears on it: the line is
    # what a reader goes to, and what an exclusion would one day be written
    # against.
    def self.findings_for(path, regions, name, entry)
      found = []
      pattern = Regexp.new("\\b" + Regexp.escape(entry.key) + "\\b")
      regions.each do |region|
        line = region.line
        region.text.split("\n").each do |text|
          found.push(Finding.new(path, line, name, entry.key, entry.text)) unless pattern.match(text).nil?
          line += 1
        end
      end
      found
    end

    # Every include the vocabulary writes that covers no file. One section
    # reaching nothing takes its whole vocabulary out of the run, and the
    # words it carries are then checked nowhere.
    # Every section's includes are asked about at once: they are written in one
    # file, and a pattern two sections share is one mistake rather than two.
    #
    # Where an include was written is asked of the parser that read the
    # specification, since only that one knows how its format spells a glob.
    def self.barren(spec, base, path, exclusion, parsers)
      patterns = []
      spec.statements.each { |section| patterns.concat(section.attributes[INCLUDE]) }
      empty = Scope.barren(base, patterns.uniq, exclusion)
      return [] if empty.empty?

      spelled = Parser.of(path, parsers).spelled_in(path)
      where = Where.of(path)
      empty.map { |pattern| Scope::Barren.new(where, pattern, spelled[pattern]) }
    end

    # A found path is a String relative to the base: these are the keys a
    # file's vocabulary is held under, and check composes each back onto the
    # base to read it.
    #
    # A section's boundary is an attribute rather than a member, because the
    # container is what carries one and nothing points at a single glob.
    def self.paths_for(section, base, exclusion)
      Scope.of(base, section.attributes[INCLUDE], exclusion).uniq.sort
    end
  end
end
