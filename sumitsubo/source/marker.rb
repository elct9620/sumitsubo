require "sumitsubo/error"
require "sumitsubo/source"
require "sumitsubo/place"

module Sumitsubo
  module Source
    # What a piece of source claims to implement. The claim sits in the comment
    # in front of the code, which is as far as a mechanical check reaches: it
    # establishes that a behavior was read and implemented, never that the
    # implementation is right.
    #
    # The keywords arrive as an argument, and what follows one is handed back
    # unread: the mechanism that names a word owns how the word is read. Behavior
    # reads a list of ids where Contract reads one name, and a name like
    # `GET /users/:id` carries the space a list would have split on.
    module Marker
      # What a name is spelled with. It is the one thing that may not stand in
      # front of a keyword: everything else there is the comment's own, and a
      # letter makes the keyword the tail of a longer word instead.
      LETTER = /[A-Za-z0-9_]/

      # Where a claim could sit arrives from outside, so nothing here knows what
      # the file is written in: a language with no comment for code to follow
      # says so by offering none, which is how anything but source is passed
      # over.
      #
      # A whole set of keywords is read in one pass because parsing is the cost:
      # a project declaring several kinds of contract would otherwise read every
      # file once per kind.
      def self.claims_in(path, keywords, languages)
        # A caller reaching a mechanism other than Behavior has no reason to have
        # rendered the path first, so the reading owns how it answers.
        where = Place.file(path)
        claims = []
        languages.attached_comments_in(path, where).each do |comment|
          # A comment spanning lines arrives whole, so the claim answers at the
          # line the keyword is on rather than where the comment began.
          comment.lines.each do |one|
            keywords.each do |keyword|
              claimed = text_after(one.text, keyword)
              claims.push(Source::Claim.new(where, one.line, keyword, claimed)) unless claimed.nil?
            end
          end
        end
        claims
      end

      # Everything after the keyword to the end of the line, or nil where the
      # line carries no such keyword. Splitting on whitespace is what makes the
      # keyword end where a person stopped writing it; joining the rest back is
      # what leaves the mechanism free to read it as one thing or many.
      def self.text_after(text, keyword)
        words = text.split(" ")
        found = []
        seen = false
        words.each do |word|
          found.push(word) if seen
          seen = true if claiming?(word, keyword)
        end
        seen ? found.join(" ") : nil
      end

      # Whether this word carries the keyword. A language writes its comment
      # against the marker with nothing between — `//@behavior`, `#@behavior`,
      # the `*` down the side of a block comment — so the word is not always the
      # keyword itself. What that leaves out is `mail@behavior.example`, where a
      # letter in front makes the keyword part of a word of someone else's.
      def self.claiming?(word, keyword)
        return false unless word.end_with?(keyword)

        # A word that is the keyword has nothing in front of it, which is the
        # one position the letter cannot be read from.
        at = word.length - keyword.length - 1
        at < 0 || LETTER.match("#{word[at]}").nil?
      end
    end
  end
end
