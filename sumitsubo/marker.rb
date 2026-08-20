require "sumitsubo/error"
require "sumitsubo/grammar"

module Sumitsubo
  # What a piece of source claims to implement. The claim sits in the comment
  # in front of the code, which is as far as a mechanical check reaches: it
  # establishes that a behaviour was read and implemented, never that the
  # implementation is right.
  #
  # The keyword arrives as an argument because the mechanism names its own —
  # see Behavior::MARKER.
  module Marker
    class Error < Sumitsubo::Error; end

    Claim = Struct.new(:path, :line, :id)

    # Only Ruby has "the comment in front of the code". Anything else in scope
    # claims nothing rather than failing: the scope is a filter, and a claim is
    # either there or not.
    def self.claims_in(path, keyword)
      return [] unless path.end_with?(".rb")

      claims = []
      comments_in(path).each do |comment|
        line = comment.line
        # A comment spanning lines arrives whole, so the claim answers at the
        # line the keyword is on rather than where the comment began.
        comment.text.split("\n").each do |text|
          ids_in(text, keyword).each { |id| claims.push(Claim.new(path, line, id)) }
          line += 1
        end
      end
      claims
    end

    def self.comments_in(path)
      TreeSitter.capture(Grammar::RUBY, File.read(path), Grammar::ATTACHED, path)
    rescue TreeSitter::ParseError => e
      # Source the grammar cannot read is not a difference between the two
      # sides: half a file yields claims the rest of it never made.
      raise Error, e.message
    end

    # Everything after the keyword, to the end of the line. Splitting on
    # whitespace is what makes the keyword match whole rather than inside a
    # longer word. The marker is data rather than prose, so a trailing remark
    # becomes an id resolving to nothing, which the run reports rather than
    # quietly accepting.
    def self.ids_in(text, keyword)
      words = text.split(" ")
      found = []
      after = false
      words.each do |word|
        found.push(word) if after
        after = true if word == keyword
      end
      found
    end
  end
end
