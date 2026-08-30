require "sumitsubo/error"
require "sumitsubo/place"
require "sumitsubo/specification"

module Sumitsubo
  class Specification
    # How a specification file is read into the shapes a mechanism judges
    # against. A mechanism puts its question to whichever parser answers for the
    # file rather than to a format, which is what keeps what a build can read in
    # one place instead of in each mechanism that wanted to read something.
    #
    # The parsers a build carries arrive as an argument, the way the languages
    # do: nothing here names one, so a parser that reaches a grammar is named
    # only where a build says what it carries.
    #
    # A parser reads the specification; a reading reads the source. The two words
    # stay apart because a contract already has two readings of its own.
    module Parser
      # The parser answering for this file, which is the first one that says it
      # reads it. A file no parser answers for is a comparison that cannot be
      # made rather than a specification read as something it is not.
      def self.of(path, parsers)
        parser = parsers.find { |candidate| candidate.reads?(path) }
        return parser unless parser.nil?

        raise Unreadable, "#{Place.file(path)} is not a specification this sumi can read"
      end

      # Whether this build carries a parser answering for the file, the way
      # `Language.carries?` asks after a language. It is what lets a mechanism
      # find its specifications without naming a format: a file no parser reads
      # is one this build was never meant to read, rather than a specification
      # written wrong.
      def self.reads?(path, parsers)
        parsers.any? { |parser| parser.reads?(path) }
      end
    end
  end
end
