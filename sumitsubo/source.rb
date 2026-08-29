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
    # A stretch of a file a person wrote, and the line it starts on.
    Region = Data.define(:line, :text)

    # One thing source says exists, where it says it, and — where it is one a
    # caller writes arguments for — what it takes. A scope carries no
    # parameters at all, which is not the same as one that takes none.
    #
    # Which language read it is not here. The caller said which, so an answer
    # carrying it would be the answer repeating the question; a caller reading
    # one file as two languages keeps the two apart by holding them apart.
    Declaration = Data.define(:path, :line, :name, :params)

    # One parameter: what it is called, how a caller has to pass it, and
    # whether it may be left out. A name is absent where the language lets the
    # parameter go unnamed.
    #
    # The kind words are each language's own. A contract compares them as text
    # without knowing what any of them means, so a second language brings its
    # own vocabulary in its own reading rather than negotiating a shared one
    # with the specification.
    Param = Data.define(:name, :kind, :optional)

    # What source says it implements: the word it claimed with, and the rest of
    # the line unread. What counts as a name in that rest belongs to whichever
    # mechanism named the word, so nothing here reads it.
    Claim = Data.define(:path, :line, :keyword, :text)
  end
end
