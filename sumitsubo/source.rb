require "sumitsubo/place"

module Sumitsubo
  # What every reading of source answers with, beside the shapes a
  # specification is read into. A mechanism compares the two, so both have to
  # be shapes it can name — and a reading reaches a grammar, which is why the
  # answers live here rather than beside the reading that builds them.
  #
  # Nothing is required here, for the same reason nothing is required beside
  # the specification's shapes: a mechanism reaches for this file, and one
  # reaching a grammar would cost every one of their tests its snapshot.
  #
  # These are values. A reading finds them and hands them over; nothing
  # afterwards changes one, so two answering the same thing are the same
  # answer, and a comparison of two of them is a comparison of what they say.
  module Source
    # A stretch of a file a person wrote, the line it starts on, and what it
    # sits in front of.
    #
    # Where a language's own syntax shares a line with what a person wrote, a
    # reading takes it off: `*/` sits at the end of the last such line, and a
    # mechanism reading that line would take it for a word. A delimiter with a
    # line to itself is left, as `=end` is, and so is what a comment opens
    # with — neither lands where a claim is read.
    class Region < Data.define(:line, :text, :followed_by)
      # What stands next to a stretch, which is a fact about the file rather
      # than a judgement on it: whoever asks decides what it means. A reading
      # that has none of the first — prose, a comment for its whole length —
      # still answers these, because what a claim can attach to is one question
      # everywhere.
      CODE = "code"
      COMMENT = "comment"
      NOTHING = "nothing"

      # The same stretch one line at a time, each answering at its own line. A
      # comment arrives whole, and what is looked for in it — a keyword, a word
      # the vocabulary turns down — is looked for by the line a reader is sent
      # to. What the whole sits in front of is what each line of it sits in
      # front of: the stretch is one node, however many lines it spans.
      def lines
        at = line
        found = []
        text.split("\n").each do |said|
          found.push(Region.new(line: at, text: said, followed_by: followed_by))
          at += 1
        end
        found
      end
    end

    # One thing source says exists, where it says it, and — where it is one a
    # caller writes arguments for — the shape it is called with. A scope
    # carries no shape at all, which is not the same as one taking nothing.
    #
    # Which language read it is not here. The caller said which, so an answer
    # carrying it would be the answer repeating the question; a caller reading
    # one file as two languages keeps the two apart by holding them apart.
    class Declaration < Data.define(:path, :line, :name, :shape)
      def place
        Place.new(path: path, line: line)
      end
    end

    # What a caller has to write to reach a declaration. Two of them saying the
    # same thing are the same shape, which is how one name declared twice is
    # asked whether it is one way in or two.
    class Shape < Data.define(:params)
      # Said to a reader as the call it describes. A shape taking nothing is
      # still a call, and says so with empty parentheses.
      def spoken
        "(#{params.map { |param| param.spoken }.join(", ")})"
      end
    end

    # One parameter: what it is called, how a caller has to pass it, and
    # whether it may be left out. A name is absent where the language lets the
    # parameter go unnamed.
    #
    # The kind words are each language's own, with one exception: `positional`
    # is sumi's, because a parameter a caller writes nothing in front of has no
    # word of its own in any of them. A contract compares the rest as text
    # without knowing what any of them means, so a second language brings its
    # own vocabulary in its own reading rather than negotiating a shared one
    # with the specification.
    class Param < Data.define(:name, :kind, :optional)
      POSITIONAL = "positional"

      # Said to a reader. The kind is left out where a bare name already says
      # it, and a dash stands where the parameter has no name of its own.
      def spoken
        called = name.nil? ? "-" : name
        word = kind == POSITIONAL ? "" : ":#{kind}"
        "#{called}#{word}#{optional ? "?" : ""}"
      end
    end

    # What source says it implements: the word it claimed with, and the rest of
    # the line unread. What counts as a name in that rest belongs to whichever
    # mechanism named the word, so nothing here reads it.
    #
    # Whether it reaches the code it claims to implement travels with it rather
    # than being read off again: only the reading knows, and a claim that
    # reaches none is still a claim somebody wrote.
    Claim = Data.define(:path, :line, :keyword, :text, :reaches_code)
  end
end
