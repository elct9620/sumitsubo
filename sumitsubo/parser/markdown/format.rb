require "sumitsubo/error"
require "sumitsubo/where"

module Sumitsubo
  module Parser
    class Markdown
      # What Markdown gives a specification to be written in: the names a query
      # may ask for a block under, and the ways a captured run of text is taken
      # apart.
      #
      # Which of those blocks a document is made of is not here. A feature and
      # a vocabulary are two forms sharing one syntax — the same level states a
      # term in one and is prose in the other — so what to ask the grammar for
      # belongs to the kind of specification being read, and each builder writes
      # its own query out of the names below.
      #
      # A heading is asked for by its level, because the grammar spells each
      # marker as a kind of its own and reading the level off the text would be
      # deciding structure from content.
      module Format
        H1 = "h1"
        H2 = "h2"
        H3 = "h3"
        H4 = "h4"
        PARAGRAPH = "paragraph"
        ITEM = "item"
        NESTED = "nested"
        FENCE = "fence"
        LANGUAGE = "language"
        CONTENT = "content"
        ROW = "row"
        CELL = "cell"

        # The one heading every kind of specification spells alike, since every
        # one of them says what it answers for. It is prose, so a scenario or a
        # contract of the same name is written in a code span and does not
        # collide with it; a term is prose too, which is what a vocabulary gives
        # up to have it. A heading only one kind knows belongs to that kind.
        INCLUDES = "Includes"

        # Where each include is written, asked of a document without being told
        # which kind it is: every kind lists them under the reserved heading,
        # and which level that heading sits at is the only thing they differ in.
        SPELLED = <<~SPELLED
          (atx_heading (atx_h1_marker) (inline) @h1)
          (atx_heading (atx_h2_marker) (inline) @h2)
          (atx_heading (atx_h3_marker) (inline) @h3)
          (atx_heading (atx_h4_marker) (inline) @h4)
          (section (list (list_item (paragraph (inline) @item))))
        SPELLED

        # What a pair of backticks opened the text with, and what followed it.
        # Two runs of text that read alike and mean nothing alike, so each is
        # named rather than reached for by position — a heading hands the rest
        # of itself back to be opened again, and `said[1]` would say nothing
        # about which of the two that is.
        Span = Struct.new(:taken, :after)

        # What a pair of backticks opens the text with, and what follows it.
        # Found by the marks themselves rather than by a pattern: what is
        # wanted is the run between them, and taking it is not recognising a
        # shape.
        def self.code_span(said)
          return nil unless said.index("`") == 0

          closed = said.index("`", 1)
          return nil if closed.nil?

          Span.new(said[1, closed - 1], said[(closed + 1)..-1].strip)
        end

        # A soft line break is a space, which is what lets a paragraph be
        # wrapped for a reader without the wrapping reaching what it says.
        def self.folded(said)
          said.split("\n").map { |line| line.strip }.join(" ")
        end

        def self.empty_to_nil(said)
          said.empty? ? nil : said
        end

        # A refusal names the topic that has the form it was written against,
        # because one format is written in three of them and a reader sent to
        # the wrong one is sent nowhere. Which topic that is belongs to the
        # kind being read, so it arrives from there.
        def self.refuse(path, line, said, topic)
          raise Unreadable, "#{Where.of(path)}:#{line} #{said}; sumi help #{topic} has the form"
        end
      end
    end
  end
end
