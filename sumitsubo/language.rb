require "pathname"
require "sumitsubo/error"
# Each language is a file of its own, holding the grammar it reads through and
# the queries written against that grammar's node names. They are required here
# rather than requiring their way back, so a caller reaches one through this
# seam and never by name.
require "sumitsubo/language/ruby"
require "sumitsubo/language/rust"
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

    # A declaration and, where it is one a caller writes arguments for, the
    # parameters it takes. A scope carries none at all, which is not the same
    # as one that takes none.
    #
    # It carries the language that read it because a name is spelled the way
    # one language spells it: two of them can spell one name alike and mean
    # nothing alike, so what a name is compared against is the language it
    # was read as together with the name.
    Name = Struct.new(:path, :line, :name, :params, :language)

    # One parameter: what it is called, how a caller has to pass it, and
    # whether it may be left out. A name is absent where the language lets the
    # parameter go unnamed.
    #
    # The kind words are each language's own and they stay on this side. A
    # contract compares them as text without knowing what any of them means,
    # so a second language brings its own vocabulary in its own reading rather
    # than negotiating a shared one with the specification.
    Param = Struct.new(:name, :kind, :optional)

    # The order a file is offered to them, which is what puts Prose last.
    ALL = [Ruby.new, Rust.new, Prose.new]

    # What a person wrote for another person in this file, read by the first
    # language answering for it. Prose answers for anything the rest did not,
    # so a file always finds one.
    #
    # The question is put to the list rather than a language handed back: a
    # caller holding one would have to know what it is, and the whole of what
    # this is for is that nobody outside has to.
    def self.comments_in(path, where)
      file = Pathname.new(path)
      language = reading_of(file)
      language.nil? ? [] : language.comments_in(file, where)
    end

    # The comments a claim could sit in.
    def self.attached_comments_in(path, where)
      file = Pathname.new(path)
      language = reading_of(file)
      language.nil? ? [] : language.attached_comments_in(file, where)
    end

    # The names this file declares, read as the language named. A name is
    # spelled the way one language spells it and two of them can spell one
    # name differently, so which reads the file is the specification's to say
    # rather than the filename's to imply.
    def self.declarations_in(path, where, language)
      file = Pathname.new(path)
      reading = reading_named(language)
      reading.nil? ? [] : reading.declarations_in(file, where)
    end

    # The same reading of a piece of text nobody wrote to a file. A
    # specification registers a contract by writing the declaration it means,
    # so the shape it registers is read by the very reading the source is read
    # by — which is what keeps a specification from spelling a shape no
    # definition could have.
    #
    # It answers where the caller says rather than where a file sits: the text
    # came out of a specification, and that is where a reader has to be sent.
    def self.declarations_of(source, where, language)
      reading = reading_named(language)
      reading.nil? ? [] : reading.declarations_of(source, where)
    end

    # Whether this build carries the language a specification named. What an
    # executable can read is decided when it is built, so a name it does not
    # answer to is a run that cannot compare rather than one that guesses.
    def self.carries?(language)
      ALL.any? { |reading| reading.named?(language) }
    end

    # Whether a definition written in that language could carry this name.
    # A shape judgement and nothing more: it says the name is spellable there,
    # never that anything defines it.
    def self.definable?(language, name)
      reading = reading_named(language)
      !reading.nil? && reading.definable?(name)
    end

    # The reading that answers for a file, and the one answering to a name.
    # Two questions rather than one: a comment is read by whichever reading
    # claims the file, and a declaration by the one the specification named.
    def self.reading_of(file)
      ALL.find { |reading| reading.reads?(file) }
    end

    def self.reading_named(language)
      ALL.find { |reading| reading.named?(language) }
    end
  end
end
