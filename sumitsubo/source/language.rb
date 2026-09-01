require "pathname"
require "sumitsubo/error"

module Sumitsubo
  module Source
    # How a file is read for what a person put in it. A mechanism puts its
    # question to the language answering for the file rather than to a grammar,
    # which is what keeps what a build can read in one place instead of in each
    # mechanism that wanted to read something.
    #
    # Which language answers is the same question as which files a reading
    # reaches: a mechanism scans everything its `include` globs cover, and a
    # language that declares nothing for a file is how that file is passed over.
    #
    # The readings a build carries arrive as an argument, the way the parsers do:
    # nothing here names one, so a reading that reaches a grammar is named only
    # where a build says what it carries. They are offered in the order they
    # were handed over, which is what puts Prose last — it answers for whatever
    # the languages before it did not claim.
    #
    # A caller that composed its path holds a Pathname and one that read it off
    # the filesystem holds a String, so this seam wraps what it is handed and a
    # language reaches the file through that object rather than through File.
    #
    # What a reading answers with is `Sumitsubo::Source`, which every mechanism
    # comparing against source can name: a shape declared here would be one the
    # comparison could not reach for without reaching a grammar.
    #
    # That a region holds no syntax of the language's own on a line a person
    # wrote on is the one thing this seam asks of a reading and cannot check:
    # what a language required is known only where that language is read.
    class Language
      class Error < Sumitsubo::Error; end

      def initialize(readings)
        @readings = readings
      end

      # What a person wrote for another person in this file, read by the first
      # language answering for it. Prose answers for anything the rest did not,
      # so a file always finds one.
      #
      # Each says what it stands next to as well, which is one question rather
      # than two: whether a claim may sit in a comment is decided by whoever
      # asks, and a reading that answered it would be deciding for them.
      #
      # The question is put to the list rather than a language handed back: a
      # caller holding one would have to know what it is, and the whole of what
      # this is for is that nobody outside has to.
      def comments_in(path, where)
        file = Pathname.new(path)
        language = reading_of(file)
        language.nil? ? [] : language.comments_in(file, where)
      end

      # The names this file declares, read as the language named. A name is
      # spelled the way one language spells it and two of them can spell one
      # name differently, so which reads the file is the specification's to say
      # rather than the filename's to imply.
      def declarations_in(path, where, language)
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
      def declarations_of(source, where, language)
        reading = reading_named(language)
        reading.nil? ? [] : reading.declarations_of(source, where)
      end

      # Whether this build carries the language a specification named. What an
      # executable can read is decided when it is built, so a name it does not
      # answer to is a run that cannot compare rather than one that guesses.
      def carries?(language)
        @readings.any? { |reading| reading.named?(language) }
      end

      # The reading that answers for a file, and the one answering to a name.
      # Two questions rather than one: a comment is read by whichever reading
      # claims the file, and a declaration by the one the specification named.
      def reading_of(file)
        @readings.find { |reading| reading.reads?(file) }
      end

      def reading_named(language)
        @readings.find { |reading| reading.named?(language) }
      end
    end
  end
end
