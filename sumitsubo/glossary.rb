require "pathname"
require "sumitsubo/error"
require "sumitsubo/finding"
require "sumitsubo/check"
require "sumitsubo/source/scope"
require "sumitsubo/source/repository"
require "sumitsubo/specification"
require "sumitsubo/place"

module Sumitsubo
  # The structured specification the Glossary mechanism verifies against.
  # Reading it can fail in a way that is not a difference between the
  # specification and the code: with no file, or an unreadable one, there is
  # no reference line to verify from at all.
  module Glossary
    FILE = "glossary.md"

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
    class Mention < Data.define(:path, :line, :term, :used, :reason)
      # What an ignore has to name to set this aside, which is a mention
      # without its reason: the reason is the specification's own.
      def key
        "#{term} #{used} #{path}:#{line}"
      end
    end

    # One line a rejection does not answer for, as the specification wrote it,
    # with what it takes to say so where it sits.
    Ignore = Data.define(:line, :at, :term, :used)

    # The mechanism names its own file; where the root sits is the tool's to
    # say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / FILE
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
    def self.check(scope, base, source)
      mentions = []
      scope.keys.sort.each do |path|
        file = base / path
        regions = source.comments(file)
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
            Ignore.new(line: ignore.line, at: ignore.key, term: term.key, used: entry.key)
        end
      end
    end

    # One mention per line, however often the word appears on it: the line is
    # what a reader goes to, and what an exclusion would one day be written
    # against.
    def self.mentions_of(path, regions, name, entry)
      found = []
      pattern = Regexp.new("\\b" + Regexp.escape(entry.key) + "\\b")
      regions.each do |region|
        region.lines.each do |one|
          found.push(Mention.new(path: path, line: one.line, term: name, used: entry.key, reason: entry.text)) unless pattern.match(one.text).nil?
        end
      end
      found
    end

    # Every include the vocabulary writes, asked about at once: they are
    # written in one file, and a pattern two sections share is one mistake
    # rather than two. One section reaching nothing takes its whole vocabulary
    # out of the run, and the words it carries are then checked nowhere.
    def self.covers(spec, path)
      patterns = []
      spec.statements.each { |section| patterns.concat(section.attributes[INCLUDE]) }
      [Check::Covers.new(path: path, patterns: patterns.uniq)]
    end

    # A found path is a String relative to the base: these are the keys a
    # file's vocabulary is held under, and check composes each back onto the
    # base to read it.
    #
    # A section's boundary is an attribute rather than a member, because the
    # container is what carries one and nothing points at a single glob.
    def self.paths_for(section, base, exclusion)
      Source::Scope.of(base, section.attributes[INCLUDE], exclusion).uniq.sort
    end
  end
end
