require "pathname"
require "sumitsubo/error"
require "sumitsubo/parser"
require "sumitsubo/finding"
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
    STALE = "glossary/stale"

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
    # names the rejection it is written under, and a mention names the word and
    # the term together. A section's boundary is not pointed at by anything, so
    # it is an attribute of that section rather than a statement.

    # A rejected word standing on a line, before anything has decided whether
    # it is a use of the word or the specification spelling it, and before an
    # ignore has been given the chance to set it aside. Its path is relative to
    # the base, which is what an ignore names it by.
    Mention = Struct.new(:path, :line, :term, :used, :reason)

    # One line a rejection does not answer for, as the specification wrote it,
    # with what it takes to say so where it sits.
    Ignore = Struct.new(:line, :at, :term, :used)

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
      mentions = []
      scope.keys.sort.each do |path|
        file = base / path
        regions = languages.comments_in(file, Where.of(file))
        terms = scope[path]
        terms.keys.sort.each do |name|
          terms[name].statements.each do |entry|
            mentions.concat(mentions_of(path, regions, name, entry))
          end
        end
      end
      # A key that leaves no ties, so two runs report the same order.
      mentions.sort_by { |one| [one.path, one.line, one.term, one.used] }
    end

    # The mentions that are uses of a rejected word rather than the
    # specification spelling one. A word has to be spelled to be declared
    # rejected, so a glossary its own includes cover would report against
    # itself every rejection it declares.
    #
    # Which line declares is the reading's answer rather than a pattern's: the
    # specification says where each word was written, so nothing here opens the
    # file a second time or knows how a format spells a declaration.
    def self.uses(mentions, spec)
      spelled = declared_in(spec)
      found = []
      mentions.each do |mention|
        next if mention.path == spec.path && spelled["#{mention.line} #{mention.used}"]

        found.push(mention)
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

    # Every mention the specification sets aside by hand, under the key that
    # mention answers at. An ignore names one line and no more: which term is
    # rejecting and which word it rejects come from where it sits, so neither
    # can be written wrong.
    def self.set_aside(spec)
      found = {}
      spec.statements.each { |section| section.statements.each { |term| sets_aside(term, found) } }
      found
    end

    # Every line one term sets aside, under the key the mention it answers to
    # is held by.
    def self.sets_aside(term, found)
      term.statements.each do |entry|
        entry.statements.each do |ignore|
          found["#{term.key} #{entry.key} #{ignore.key}"] =
            Ignore.new(ignore.line, ignore.key, term.key, entry.key)
        end
      end
    end

    # The findings a run answers for. A mention the specification set aside is
    # not reported: which side is wrong is not the tool's to decide, and here
    # the project has decided.
    #
    # An ignore names a mention by its path under the base, and a finding
    # answers at the path a reader started the run from. This is where a
    # mention stops being a candidate, so this is where the two are told apart.
    def self.standing(mentions, spec, base)
      aside = set_aside(spec)
      found = []
      mentions.each do |mention|
        next unless aside[key_of(mention)].nil?

        found.push(Finding.new(
          rule: REJECTED, difference: true,
          path: Where.of(base / mention.path), line: mention.line,
          message: "#{mention.term} rejects #{mention.used}: #{mention.reason}"
        ))
      end
      found
    end

    # What was set aside and no longer names anything — the line moved, or the
    # wording was fixed. Nothing else notices, so an exception left behind
    # outlives what it was for; the run refuses to certify rather than pass.
    def self.stale(mentions, spec)
      met = {}
      mentions.each { |mention| met[key_of(mention)] = true }
      aside = set_aside(spec)
      found = []
      aside.keys.sort.each do |key|
        next unless met[key].nil?

        ignore = aside[key]
        found.push(Finding.new(
          rule: STALE, difference: false,
          path: Where.of(spec.path), line: ignore.line,
          message: "nothing at #{ignore.at} has #{ignore.term} rejecting " \
                   "#{ignore.used}; the line moved or the wording was fixed"
        ))
      end
      found
    end

    # What an ignore has to name to set a mention aside, which is a mention
    # without its reason: the reason is the specification's own.
    def self.key_of(mention)
      "#{mention.term} #{mention.used} #{mention.path}:#{mention.line}"
    end

    # One mention per line, however often the word appears on it: the line is
    # what a reader goes to, and what an exclusion would one day be written
    # against.
    def self.mentions_of(path, regions, name, entry)
      found = []
      pattern = Regexp.new("\\b" + Regexp.escape(entry.key) + "\\b")
      regions.each do |region|
        line = region.line
        region.text.split("\n").each do |text|
          found.push(Mention.new(path, line, name, entry.key, entry.text)) unless pattern.match(text).nil?
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
      empty.map { |pattern| Scope.barren_at(BARREN, where, pattern, spelled[pattern]) }
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
