# `Specification` is assigned rather than declared, so a file reopening it
# before that assignment runs loses what it added: CRuby warns and carries
# on, and the compiler merges either way. Nothing here calls into it — the
# require is the order.
require "sumitsubo/specification"

module Sumitsubo
  class Specification
    # A run of a block's text the document marked as taken letter for letter,
    # beside where it sits in that text. The offsets are what say whether the
    # block opens with the run and where the text after it starts, which is the
    # difference between a heading naming a contract and one saying a sentence
    # about it.
    #
    # They count bytes, the way the tree measures, so a block is sliced by bytes
    # rather than by characters — a dash a reader wrote is three of one and one
    # of the other.
    Span = Struct.new(:taken, :from, :to)

    # What a document is made of, said in the words a specification is written in
    # rather than in any one format's: a heading and its level, a paragraph, a
    # list item and its depth, a fenced block and the language it declares, a
    # table row and the cells under it. The structure a reader already sees.
    #
    # `level` is how deep the block sits — which level a heading is written at,
    # and how far a list item is indented. They are one number because they are
    # one question, and a form asks it of whichever kind it reads.
    #
    # This is what a parser answers with and what a form reads, which is why it
    # sits beside the shapes rather than under either of them. Which of these a
    # document is made of is not decided here: a feature and a vocabulary are two
    # forms sharing one syntax, so what to ask for belongs to the form being
    # read, and what a block means belongs there too.
    class Block < Struct.new(:kind, :level, :line, :text, :language, :spans, :cells)
      # The kinds a document is made of. A form asks for the ones it is written
      # in and no others, which is what leaves a level it has no use for as
      # prose.
      HEADING = "heading"
      PARAGRAPH = "paragraph"
      ITEM = "item"
      CODE = "code"
      ROW = "row"

      # A cell arrives under the row holding it rather than on its own, since
      # where one row ends and the next begins is what a form has to know. It is
      # asked for with the row and never apart from it.
      CELL = "cell"

      # The run this block opens with, or nil where it opens with anything else.
      # A contract's name, a scenario's id and a word a term turns down are each
      # written this way, so a block opening with prose is a form nobody reads
      # rather than one read loosely.
      def taken
        return nil if spans.empty? || !text.byteslice(0, spans[0].from).strip.empty?

        spans[0].taken
      end

      # Everything written after that run, as it was written. A title may carry a
      # run of its own, so this is the text rather than what is left once the
      # runs are taken out of it.
      def rest
        return text.strip if spans.empty?

        text.byteslice(spans[0].to, text.bytesize - spans[0].to).strip
      end
    end
  end
end
