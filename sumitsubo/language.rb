require "pathname"
require "sumitsubo/error"
require "sumitsubo/grammar"
require "sumitsubo/definitions"

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
          Grammar::RUBY, path.read, Grammar::COMMENTS, where
        )
        captures.each { |capture| found.push(Region.new(capture.line, capture.text)) }
        found
      rescue TreeSitter::ParseError => e
        # Source the grammar cannot read is not a difference between the two
        # sides either: half a file yields regions the rest of it never made.
        raise Error, e.message
      end

      # The comments with code after them. A claim sits in front of what
      # implements it, so a comment nothing follows claims nothing.
      def attached_comments_in(path, where)
        found = []
        captures = TreeSitter.capture(
          Grammar::RUBY, path.read, Grammar::ATTACHED, where
        )
        captures.each { |capture| found.push(Region.new(capture.line, capture.text)) }
        found
      rescue TreeSitter::ParseError => e
        raise Error, e.message
      end

      # The names this file declares and the shape each is reached by. Only
      # Ruby answers one here, which is why the shapes stay with the reading
      # that makes them rather than moving up to this file.
      def declarations_in(path, where)
        Definitions.names_in(path)
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
        path.readlines.each do |text|
          line += 1
          found.push(Region.new(line, text))
        end
        found
      end

      # Prose has no code for a comment to sit in front of, so nothing here
      # claims anything, and it declares nothing either.
      def attached_comments_in(path, where)
        []
      end

      def declarations_in(path, where)
        []
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

    # The names this file declares. A language with no declarations to read
    # says so by answering none, which is how anything but source is passed
    # over without a caller having to ask what it was.
    def self.declarations_in(path, where)
      file = Pathname.new(path)
      index = 0
      while index < ALL.length
        language = ALL[index]
        return language.declarations_in(file, where) if language.reads?(file)

        index += 1
      end
      []
    end
  end
end
