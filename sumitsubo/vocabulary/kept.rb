require "pathname"
require "sumitsubo/error"
require "sumitsubo/finding"
require "sumitsubo/check"
require "sumitsubo/source/scope"
require "sumitsubo/source/repository"
require "sumitsubo/specification"
require "sumitsubo/place"
require "sumitsubo/relation"
require "sumitsubo/source"

module Sumitsubo
  # What the Glossary mechanism keeps from the source for a vocabulary, and reads back.
  module Vocabulary
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
            mentions.concat(mentions_of(path, regions, name, entry, terms.keys))
          end
        end
      end
      # A key that leaves no ties, so two runs report the same order.
      mentions.sort_by { |one| [one.path, one.line, one.term, one.used] }
    end

    # Every rejected word in the files the vocabulary reaches, kept under the
    # term rejecting it there. The word is kept as it was written, at the path
    # a relation names a file by.
    def self.keep(scope, base, source, relations, mechanism)
      check(scope, base, source).each do |one|
        found = Source::Mention.new(path: Place.file(base / one.path), line: one.line, used: one.used)
        relations.add(Relation.mentions(found, Relation::Reference.new(mechanism: mechanism, key: one.term)))
      end
    end

    # The mentions the run kept, read back as the checks compare them: under
    # the base the way an ignore names one, with the reason the vocabulary
    # holding in that file gives for turning the word down.
    def self.mentioned(relations, scope, base)
      found = []
      relations.each do |one|
        path = from_base(one.subject.path, base)
        term = one.object.key
        entry = scope[path][term].statements.find { |rejected| rejected.key == one.subject.used }
        found.push(Mention.new(path: path, line: one.subject.line, term: term, used: one.subject.used, reason: entry.text))
      end
      found
    end

    # The mentions that are uses of a rejected word rather than the
    # specification spelling one. A word has to be spelled to be declared
    # rejected, so a glossary its own includes cover would report against
    # itself every rejection it declares.
    #
    # Which line declares is the reading's answer rather than a pattern's: the
    # specification says where each word was written, so nothing here opens the
    # file a second time or knows how a format spells a declaration.
    def self.uses(mentions, spec, base)
      spelled = declared_in(spec)
      own = from_base(spec.path, base)
      found = []
      mentions.each do |mention|
        next if mention.path == own && spelled["#{mention.line} #{mention.used}"]

        found.push(mention)
      end
      found
    end

    # One mention per line, however often the word appears on it: the line is
    # what a reader goes to, and what an exclusion would one day be written
    # against.
    #
    # A term whose name spells the word inside a longer one is a use of that
    # term, not of the word: rejecting `Component` is how a file under two
    # subdomains is made to say `UI Component` or `Backend Component`.
    def self.mentions_of(path, regions, name, entry, spellings)
      found = []
      pattern = whole_word(entry.key)
      longer = spellings.reject { |one| one == entry.key || pattern.match(one).nil? }
      lines = []
      regions.each { |region| lines.concat(region.lines) }
      written = by_line(lines)
      lines.each do |one|
        left = masked(one.text, longer, written[one.line - 1] || "", written[one.line + 1] || "")
        found.push(Mention.new(path: path, line: one.line, term: name, used: entry.key, reason: entry.text)) unless pattern.match(left).nil?
      end
      found
    end

    # What each line of a file says, whichever region said it. A run of line
    # comments is one region per line, and a sentence wrapped across them is
    # still one sentence.
    def self.by_line(lines)
      written = {}
      lines.each { |one| written[one.line] = "#{written[one.line]} #{one.text}" }
      written
    end

    def self.whole_word(word)
      Regexp.new("\\b" + Regexp.escape(word) + "\\b")
    end

    # The text with every longer spelling blanked out, so a match left in it is
    # the word standing on its own — including a spelling a line break cut in
    # two, whose other half ends the line before or opens the line after.
    #
    # Held as spellings and interpolated first: under Spinel 2026.09.12 a Regexp
    # taken out of an Array reaches `gsub` as a String, and the text a region
    # holds has no `gsub` at all. Spinel 30d32f7 answers the first and c6bbdfb
    # the second.
    def self.masked(text, longer, before, after)
      held = "#{text}"
      longer.each do |one|
        held = held.gsub(whole_word(one), " ")
        held = unwrapped(held, one.split(" "), before, after)
      end
      held
    end

    # Each place a spelling can be cut, asked of both neighbours. A line opens
    # past its comment marker but ends only at whitespace, so a sentence closed
    # on the first half does not run on into the next line.
    def self.unwrapped(held, words, before, after)
      (1...words.length).each do |cut|
        ending = Regexp.new("\\b" + Regexp.escape(words[0, cut].join(" ")) + "\\s*\\z")
        opening = Regexp.new("\\A\\W*" + Regexp.escape(words[cut, words.length - cut].join(" ")) + "\\b")
        held = held.sub(opening, " ") unless ending.match(before).nil?
        held = held.sub(ending, " ") unless opening.match(after).nil?
      end
      held
    end
  end
end
