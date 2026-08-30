module Sumitsubo
  # What a check compares, said in the words both sides can be put into. A
  # mechanism turns its own specification and its own reading of source into
  # these, and that turning is the whole of what differs between two mechanisms
  # asking one question.
  #
  # Nothing is required here, for the same reason nothing is required beside a
  # finding: a check reaches for this file, and a reading that reached a grammar
  # would cost every one of their tests its snapshot.
  module Check
    # What a specification says can be claimed: the word a claim names it by,
    # where the specification declares it, and how it is said to a reader.
    Stated = Data.define(:key, :place, :said)

    # What source claims: the same word, where it says so, and how that is said.
    Made = Data.define(:key, :place, :said)

    # What a specification registers for a name the syntax tree answers for:
    # the shape a caller would have to write, beside the name it is written
    # under.
    Registered = Data.define(:key, :place, :said, :shape)

    # What one specification's includes cover, and where that specification is.
    # A glossary writes them in sections and answers for all of them at once,
    # where a feature and a definition each answer for their own.
    Covers = Data.define(:path, :patterns)
  end
end
