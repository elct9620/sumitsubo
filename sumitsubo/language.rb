require "sumitsubo/error"
require "sumitsubo/grammar"

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
  module Language
    class Error < Sumitsubo::Error; end

    # A stretch of a file a person wrote, and the line it starts on.
    Region = Struct.new(:line, :text)

    # Ruby, read through the grammar this build links in.
    class Ruby
      def reads?(path)
        "#{path}".end_with?(".rb")
      end

      # What a person wrote for another person is the comments and nothing
      # else. An identifier is a spelling of a concept rather than the
      # concept's name, so counting one would answer for every legitimate
      # class in the tree.
      def comments_in(path, where)
        found = []
        captures = TreeSitter.capture(
          Grammar::RUBY, File.read("#{path}"), Grammar::COMMENTS, where
        )
        captures.each { |capture| found.push(Region.new(capture.line, capture.text)) }
        found
      rescue TreeSitter::ParseError => e
        # Source the grammar cannot read is not a difference between the two
        # sides either: half a file yields regions the rest of it never made.
        raise Error, e.message
      end
    end

    # Whatever no language before it claimed. Prose is a comment for its whole
    # length, so the file answers entire and nothing has to be found in it.
    class Prose
      def reads?(path)
        true
      end

      def comments_in(path, where)
        found = []
        line = 0
        File.readlines("#{path}").each do |text|
          line += 1
          found.push(Region.new(line, text))
        end
        found
      end
    end

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
      found = []
      read = false
      ALL.each do |language|
        next if read || !language.reads?(path)

        found = language.comments_in(path, where)
        read = true
      end
      found
    end
  end
end
