module Sumitsubo
  # What every mechanism reads a specification into. The three of them had a
  # vocabulary each — section and term, definition and interface, feature and
  # scenario — for the same two things: a file's worth of what a project
  # declares, and one declaration in it.
  #
  # A statement carries its own statements, so what used to be a structure of
  # its own is one of these under another: a rejected word sits under the term
  # rejecting it, and the line set aside sits under that. What earns a
  # statement of its own rather than an attribute is being pointed at from
  # somewhere else.
  #
  # Nothing is required here. A mechanism reaches for this file, and a reading
  # that reaches a grammar would cost every one of their tests its snapshot.
  Specification = Struct.new(:key, :text, :includes, :path, :attributes, :statements)

  # `key` is what a claim in the source names, and `text` is what the
  # declaration says: an id and its title, a name and its description, a term
  # and its definition are one pair rather than three.
  #
  # Attributes are what one mechanism declares and another has no use for,
  # held under the words that mechanism words its own help with. Each answers
  # a list, so a shape carrying one is spelled no differently from a shape
  # carrying several, and a flag is the empty list — it says a thing of itself
  # by being there.
  Statement = Struct.new(:key, :text, :path, :line, :attributes, :statements)

  # The attribute a boundary is held under where a specification writes one
  # deeper than its own container. It is spelled here rather than in either
  # side because a parser writes it and a mechanism reads it, and the two have
  # to mean the same word.
  INCLUDE = "include"

  # The kind a parameter carries when the specification names none, and the one
  # kind word this tool owns rather than borrows: it names the parameter a
  # caller writes with no marking of any sort, which every language has one of.
  POSITIONAL = "positional"

  # One parameter a contract registers. The kind is carried as text and never
  # read: what these words mean belongs to the reading that answers them, so a
  # specification writes the words its language uses and nothing here learns
  # any of them.
  #
  # It sits with the two shapes above because a reading builds one and a
  # mechanism compares it, and neither of those may reach for the other.
  Param = Struct.new(:name, :kind, :optional)
end
