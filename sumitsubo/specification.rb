module Sumitsubo
  # What every mechanism reads a specification into. The three of them speak a
  # vocabulary each — section and term, definition and interface, feature and
  # scenario — of the same two things: a file's worth of what a project
  # declares, and one declaration in it.
  #
  # A statement carries its own statements, so what could be a structure of
  # its own is one of these under another: a rejected word sits under the term
  # rejecting it, and the line set aside sits under that. What earns a
  # statement of its own rather than an attribute is being pointed at from
  # somewhere else.
  #
  # An include is one of those statements too, held under `includes` rather
  # than among what the container declares: a barren one answers at the line it
  # was written on, and nothing reads it as a declaration.
  #
  # `path` is the file as a reader is handed it, and every form keeps it that
  # way, so a relation, a reach and a finding name one file by one string.
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
  # carrying several, and one nothing said is absent rather than empty.
  #
  # A statement carries includes because a section answers for a boundary the
  # way the document does, and one written deeper is still the container's own
  # rather than a declaration under it.
  #
  # An arrangement is where a statement's parts are written, which only a
  # form writing an attributes table has to say, so the others leave it out.
  Statement = Struct.new(:key, :text, :includes, :path, :line, :attributes, :statements, :arrangement)

  # Where a statement writes its attributes table, from its heading row to its
  # last, beside the line of what the table sits right above — the steps, the
  # signature — and the last line the statement holds. Each is nil where the
  # statement writes no such thing or runs to the end of its document.
  Arrangement = Struct.new(:from, :to, :above, :ends)
end
