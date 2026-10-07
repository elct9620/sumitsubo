module Sumitsubo
  # What a run found to correspond, of one kind and from one end to the other.
  # A specification and the source are each read once, and what joins them is
  # kept here rather than inside the check that first needed it, so every later
  # question about the join asks the same answer.
  #
  # The ends are not one shape: a claim runs from an anchor to a reference, a
  # reach from one artifact to another. Which pair a relation carries is what
  # its kind says, so a caller asks the kind before it asks an end anything only
  # that shape answers.
  class Relation < Data.define(:kind, :subject, :object)
    CLAIM = "claim"
    REACH = "reach"

    # A specification reaching a file, both taken whole.
    def self.reach(specification, file)
      new(kind: REACH, subject: Artifact.new(path: specification), object: Artifact.new(path: file))
    end

    # A place in source naming a statement.
    def self.claim(anchor, reference)
      new(kind: CLAIM, subject: anchor, object: reference)
    end

    # A statement as a relation names it: the mechanism keeping it, and its
    # key. It names the statement whether or not one was declared under it, which
    # is what lets a claim resolving to nothing still be kept.
    class Reference < Data.define(:mechanism, :key)
    end

    # A place in source a relation runs from: the line, and the line the comment
    # holding it began on, since one comment witnessing many is one place.
    class Anchor < Data.define(:path, :line, :comment_line, :in_front_of_code)
    end

    # A file as one end of a relation, taken whole rather than at a line.
    class Artifact < Data.define(:path)
    end
  end
end
