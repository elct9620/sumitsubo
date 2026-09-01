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
      # A name ending where the keyword begins. That is the one thing that may
      # not stand in front of a keyword: everything else there is the comment's
      # own, and a letter makes the keyword the tail of a longer word instead.
      LETTER = /[A-Za-z0-9_]\z/

      # The comments arrive from outside, so nothing here knows what the file is
      # written in — only that each says what it stands next to, which is the
      # same question in every language and in prose, where nothing stands next
      # to the last line.
      #
      # A whole set of keywords is read in one pass because parsing is the cost:
      # a project declaring several kinds of contract would otherwise read every
      # file once per kind.
      def self.claims_in(path, keywords, languages)
        # A caller reaching a mechanism other than Behavior has no reason to have
        # rendered the path first, so the reading owns how it answers.
        where = Place.file(path)
        comments = languages.comments_in(path, where)
        reaching = reaching_in(comments)
        claims = []
        comments.each do |comment|
          claimed_in(comment, keywords, where, reaching[comment.line]).each { |one| claims.push(one) }
        end
        claims
      end

      # Whether each comment stands in front of code, under the line it starts
      # on. It reaches code through the comments after it, because what a person
      # wrote between a claim and what implements it is still what they wrote —
      # and reaches none where the run of them ends the file or the block.
      #
      # The comments arrive in the order they were met, so the last is the one
      # that settles the run and the answer is carried backwards from it.
      def self.reaching_in(comments)
        found = {}
        reaches = false
        comments.reverse.each do |comment|
          reaches = comment.followed_by == Source::Region::CODE ||
                    (comment.followed_by == Source::Region::COMMENT && reaches)
          found[comment.line] = reaches
        end
        found
      end

      # The claims one comment carries. It spans lines whole, so a claim answers
      # at the line its keyword is on rather than where the comment began, while
      # what the comment stands in front of is the same for every line of it.
      def self.claimed_in(comment, keywords, where, reaches)
        found = []
        comment.lines.each do |one|
          keywords.each do |keyword|
            claimed = text_after(one.text, keyword)
            found.push(Source::Claim.new(where, one.line, keyword, claimed, reaches)) unless claimed.nil?
          end
        end
        found
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

        LETTER.match(word.delete_suffix(keyword)).nil?
      end
    end
  end
end
