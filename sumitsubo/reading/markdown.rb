require "pathname"
require "sumitsubo/error"
require "sumitsubo/language/grammar"
require "sumitsubo/reading/blocks"
require "sumitsubo/where"
require "treesitter"

module Sumitsubo
  module Reading
    # A specification as Markdown, which is the document a person reads as well
    # as the reference line the tool compares against.
    #
    # This is the whole of what reaches the grammar. The query names the blocks
    # a specification is written in and nothing else, and what it captured goes
    # to Blocks to be made into a specification — which is what keeps the
    # judgement, and its test, on the side a snapshot can be regenerated from.
    class Markdown
      SUFFIX = ".md"

      # The blocks a specification is written in. Every pattern is anchored at
      # the section holding it, which is what tells a paragraph of its own from
      # the paragraph a list item is made of — both are `(paragraph (inline))`,
      # and only where they sit says which.
      #
      # A heading arrives under a name for its level rather than with the level
      # to read, because the grammar spells each marker as a kind of its own.
      BLOCKS = <<~BLOCKS
        (atx_heading (atx_h1_marker) (inline) @title)
        (atx_heading (atx_h2_marker) (inline) @heading)
        (section (paragraph (inline) @paragraph))
        (section (list (list_item (paragraph (inline) @item))))
        (pipe_table_row (pipe_table_cell) @cell)
      BLOCKS

      def reads?(path)
        "#{path}".end_with?(SUFFIX)
      end

      def behavior(path)
        Blocks.behavior(blocks_in(path), path)
      end

      private

      # Every byte sequence is a legal document, so the grammar refuses
      # nothing: what a specification written wrong loses is the shape the
      # query matches, and saying so is Blocks' rather than the parser's.
      def blocks_in(path)
        file = Pathname.new(path)
        TreeSitter.capture(Grammar::MARKDOWN, file.read, BLOCKS, Where.of(file))
      end
    end
  end
end
