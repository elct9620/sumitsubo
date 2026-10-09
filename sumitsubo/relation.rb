module Sumitsubo
  # What a run found to correspond, of one kind and from one end to the other.
  # A specification and the source are each read once, and what joins them is
  # kept here rather than inside the check that first needed it, so every later
  # question about the join asks the same answer.
  #
  # The ends are not one shape: a claim and a dangling marker run from where
  # the marker was written to a reference, a declaration from what a language
  # read, a mention from the word a person wrote, a reach from one artifact to another, and what one statement says of
  # another from one reference to the next. Which pair a
  # relation carries is what its kind says, so a caller asks the kind before it
  # asks an end anything only that shape answers.
  class Relation < Data.define(:kind, :subject, :object)
    CLAIM = "claim"
    DANGLING = "dangling"
    REACH = "reach"
    RELATES = "relates"
    REFINES = "refines"
    DECLARES = "declares"
    MENTIONS = "mentions"

    # A specification reaching a file, both taken whole.
    def self.reach(specification, file)
      new(kind: REACH, subject: Artifact.new(path: specification), object: Artifact.new(path: file))
    end

    # A place in source naming a statement, with code below it.
    def self.claim(marked, reference)
      new(kind: CLAIM, subject: marked, object: reference)
    end

    # A declaration in source naming a statement as the language that read it
    # spells it.
    def self.declares(spelled, reference)
      new(kind: DECLARES, subject: spelled, object: reference)
    end

    # A word a person wrote, naming the term in the vocabulary that rejects
    # it where it stands.
    def self.mentions(mention, reference)
      new(kind: MENTIONS, subject: mention, object: reference)
    end

    # A place in source naming a statement, with no code below it.
    def self.dangling(marked, reference)
      new(kind: DANGLING, subject: marked, object: reference)
    end

    # Two statements a specification says belong together. Which of them
    # wrote it says nothing, so it reads the same from either end.
    def self.relates(subject, object)
      new(kind: RELATES, subject: subject, object: object)
    end

    # A statement saying it narrows another, from the narrower to the one it
    # refines.
    def self.refines(subject, object)
      new(kind: REFINES, subject: subject, object: object)
    end

    # A statement as a relation names it: the mechanism keeping it, and its
    # key. It names the statement whether or not one was declared under it, which
    # is what lets a claim resolving to nothing still be kept.
    class Reference < Data.define(:mechanism, :key)
      # A key as a specification wrote it. One opening with a mechanism's name
      # and a space is that mechanism's; any other is kept by the mechanism
      # writing it, so a scenario names another scenario by its id alone.
      def self.written(said, own, names)
        at = said.index(" ")
        unless at.nil?
          named = said[0, at]
          return new(mechanism: named, key: said[at + 1, said.length - at - 1]) if names.include?(named)
        end
        new(mechanism: own, key: said)
      end
    end

    # A file as one end of a relation, taken whole rather than at a line.
    class Artifact < Data.define(:path)
    end
  end
end
