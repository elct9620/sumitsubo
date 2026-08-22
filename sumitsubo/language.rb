require "pathname"
require "sumitsubo/error"
# Each language is a file of its own, holding both the grammar it reads through
# and the queries written against that grammar's node names. They are required
# here rather than requiring their way back, so a caller reaches one through
# this seam and never by name.
require "sumitsubo/language/ruby"
require "sumitsubo/language/prose"

module Sumitsubo
  # How a file is read for what a person put in it. A mechanism puts its
  # question to the language answering for the file rather than to a grammar,
  # which is what keeps what a build can read in one place instead of in each
  # mechanism that wanted to read something.
  #
  # Which language answers is the same question as which files a reading
  # reaches: a mechanism scans everything its `include` globs cover, and a
  # language that declares nothing for a file is how that file is passed over.
  #
  # A language registers by being in the list below, the way a mechanism does:
  # Spinel decides what an executable carries when it is built, so there is no
  # hook to register through. Prose comes last because it answers for whatever
  # the languages before it did not claim.
  #
  # A caller that composed its path holds a Pathname and one that read it off
  # the filesystem holds a String, so this seam wraps what it is handed and a
  # language reaches the file through that object rather than through File.
  module Language
    class Error < Sumitsubo::Error; end

    # A stretch of a file a person wrote, and the line it starts on.
    Region = Struct.new(:line, :text)

    # The order a file is offered to them, which is what puts Prose last.
    ALL = [Ruby.new, Prose.new]

    # What a person wrote for another person in this file, read by the first
    # language answering for it. Prose answers for anything the rest did not,
    # so a file always finds one.
    #
    # The question is put to the list rather than a language handed back: a
    # caller holding one would have to know what it is, and the whole of what
    # this is for is that nobody outside has to.
    def self.comments_in(path, where)
      file = Pathname.new(path)
      index = 0
      while index < ALL.length
        language = ALL[index]
        return language.comments_in(file, where) if language.reads?(file)

        index += 1
      end
      []
    end

    # The comments a claim could sit in. Written out rather than folded in
    # with the reading above: what they share is a loop, and a way to hand one
    # question to the other is a mechanism where two of these are ten lines.
    def self.attached_comments_in(path, where)
      file = Pathname.new(path)
      index = 0
      while index < ALL.length
        language = ALL[index]
        return language.attached_comments_in(file, where) if language.reads?(file)

        index += 1
      end
      []
    end

    # The names this file declares, read as the language named. A name is
    # spelled the way one language spells it and two of them can spell one
    # name differently, so which reads the file is the specification's to say
    # rather than the filename's to imply.
    def self.declarations_in(path, where, language)
      file = Pathname.new(path)
      index = 0
      while index < ALL.length
        reading = ALL[index]
        return reading.declarations_in(file, where) if reading.named?(language)

        index += 1
      end
      []
    end

    # Whether this build carries the language a specification named. What an
    # executable can read is decided when it is built, so a name it does not
    # answer to is a run that cannot compare rather than one that guesses.
    def self.carries?(language)
      index = 0
      while index < ALL.length
        return true if ALL[index].named?(language)

        index += 1
      end
      false
    end

    # Whether a definition written in that language could carry this name.
    # A shape judgement and nothing more: it says the name is spellable there,
    # never that anything defines it.
    def self.definable?(language, name)
      index = 0
      while index < ALL.length
        reading = ALL[index]
        return reading.definable?(name) if reading.named?(language)

        index += 1
      end
      false
    end
  end
end
