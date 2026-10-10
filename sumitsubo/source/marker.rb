require "sumitsubo/error"
require "sumitsubo/source"
require "sumitsubo/place"

module Sumitsubo
  module Source
    # What a piece of source claims. The claim sits in the comment in front of
    # the code, which is as far as a mechanical check goes: what a claim asserts
    # about that code is its mechanism's to say, and none of them says the code
    # is right.
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
      def self.marked_in(path, keywords, languages)
        # The reading renders the path itself, so a claim names its file the
        # same way whichever mechanism asked.
        where = Place.file(path)
        comments = languages.comments_in(path, where)
        in_front_at = in_front_of_code(comments)
        begun_at = begins(comments)
        claims = []
        dangling = []
        comments.each do |comment|
          held = in_front_at[comment.line] ? claims : dangling
          claimed_in(comment, keywords, where, begun_at[comment.line]).each { |one| held.push(one) }
        end
        Source::Marked.new(claims: claims, dangling: dangling)
      end

      # Answered under the line each comment starts on: the line its run
      # began, which is the comment a person wrote however many a language
      # split it into. Claims sharing that line were written as one.
      def self.begins(comments)
        found = {}
        begun = 0
        joined = false
        comments.each do |comment|
          begun = comment.line unless joined
          found[comment.line] = begun
          joined = comment.followed_by == Source::Region::COMMENT
        end
        found
      end

      # Answered under the line each comment starts on. It stands in front of
      # code through the comments after it, because what a person wrote between
      # a claim and the code it is about is still what they wrote — and in
      # front of nothing where the run of them ends the file or the block.
      #
      # The comments arrive in the order they were met, so the last is the one
      # that settles the run and the answer is carried backwards from it.
      def self.in_front_of_code(comments)
        found = {}
        below = false
        comments.reverse.each do |comment|
          below = comment.followed_by == Source::Region::CODE ||
                  (comment.followed_by == Source::Region::COMMENT && below)
          found[comment.line] = below
        end
        found
      end

      # The claims one comment carries. It spans lines whole, so a claim answers
      # at the line its keyword is on rather than where the comment began.
      def self.claimed_in(comment, keywords, where, comment_line)
        found = []
        comment.lines.each do |one|
          keywords.each do |keyword|
            claimed = text_after(one.text, keyword)
            next if claimed.nil?

            found.push(Source::Claim.new(where, one.line, comment_line, keyword, claimed))
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
