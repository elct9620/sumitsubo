require "sumitsubo/error"
require "sumitsubo/where"

module Sumitsubo
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
      index = 0
      while index < parsers.length
        parser = parsers[index]
        return parser if parser.reads?(path)

        index += 1
      end
      raise Unreadable, "#{Where.of(path)} is not a specification this sumi can read"
    end
  end
end
