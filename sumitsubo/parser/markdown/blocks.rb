require "sumitsubo/error"
require "sumitsubo/where"

module Sumitsubo
  module Parser
    class Markdown
      # The blocks a specification is written in — which is to say, the format.
      # A block a specification may be written in is here; anything else a
      # document holds is prose the readings walk past. So a mechanism never
      # extends this: three of them share one query, and what a fourth needs is
      # already captured. Adding a pattern is widening the format, which is a
      # decision worth writing down rather than a line worth adding quietly.
      #
      # What a reading makes of a block is its own; what every reading does the
      # same way is here, because a code span means one thing across the three
      # and a document read two ways is a format with two definitions.
      module Blocks
        # Every heading level is asked for, because six is all Markdown has and
        # a level nobody captures is a heading that vanishes with its section. A
        # heading arrives under a name for its level rather than with the level
        # to read: the grammar spells each marker as a kind of its own, and no
        # level means one thing across the readings — an h3 states a term in a
        # vocabulary and is prose in a feature.
        #
        # Every other pattern is anchored at the section holding it, which is
        # what tells a paragraph of its own from the paragraph a list item is
        # made of — both are `(paragraph (inline))`, and only where they sit
        # says which. A nested item is anchored one level deeper for the same
        # reason: unanchored, a third level would arrive spelled exactly like
        # the second and be read as one. Two levels is what a list carries here,
        # so a third is captured by nothing.
        #
        # A fence and a table row are each asked for as well as their parts, and
        # arrive ahead of them, so where one ends is the grammar's answer rather
        # than a comparison of line numbers — and a fence carrying no language
        # is still a fence rather than nothing. The cells stay the grammar's
        # too: a separator a document escapes belongs to the cell holding it,
        # and splitting the row's own text would take it for a separator.
        QUERY = <<~QUERY
          (atx_heading (atx_h1_marker) (inline) @h1)
          (atx_heading (atx_h2_marker) (inline) @h2)
          (atx_heading (atx_h3_marker) (inline) @h3)
          (atx_heading (atx_h4_marker) (inline) @h4)
          (atx_heading (atx_h5_marker) (inline) @h5)
          (atx_heading (atx_h6_marker) (inline) @h6)
          (section (paragraph (inline) @paragraph))
          (section (list (list_item (paragraph (inline) @item))))
          (section (list (list_item (list (list_item (paragraph (inline) @nested))))))
          (section (fenced_code_block) @fence)
          (section (fenced_code_block (info_string (language) @language)))
          (section (fenced_code_block (code_fence_content) @content))
          (pipe_table_row) @row
          (pipe_table_row (pipe_table_cell) @cell)
        QUERY

        # What the query calls each thing it captures. A block says what it is
        # by the name it arrives under, so nothing here reads the text to
        # decide.
        H1 = "h1"
        H2 = "h2"
        H3 = "h3"
        H4 = "h4"
        H5 = "h5"
        H6 = "h6"
        PARAGRAPH = "paragraph"
        ITEM = "item"
        NESTED = "nested"
        FENCE = "fence"
        LANGUAGE = "language"
        CONTENT = "content"
        CELL = "cell"

        # The headings that say what a specification answers for rather than
        # declaring something. They are prose, so a scenario or a contract of
        # the same name is written in a code span and does not collide with
        # them; a term is prose too, which is what a vocabulary gives up to have
        # them.
        INCLUDES = "Includes"
        REJECTED = "Rejected"

        # The topic a refusal sends a reader to for the form it was written
        # against, since one format answers for three of them.
        BEHAVIOR = "behavior"
        GLOSSARY = "glossary"

        # What a reader puts between a word taken letter for letter and the
        # prose saying why. Taken off where it is there and not asked for where
        # it is not: a reason reads the same either way, so requiring it would
        # refuse nothing a person could have meant differently. `fmt` is what
        # puts it there.
        DASH = "—"

        # What a pair of backticks opens the text with, and what follows it.
        # Found by the marks themselves rather than by a pattern: what is
        # wanted is the run between them, and taking it is not recognising a
        # shape.
        def self.code_span(said)
          return nil unless said.index("`") == 0

          closed = said.index("`", 1)
          return nil if closed.nil?

          [said[1, closed - 1], said[(closed + 1)..-1].strip]
        end

        # What a list item says after the word it took letter for letter.
        def self.reason(said)
          return empty_to_nil(said) unless said.index(DASH) == 0

          empty_to_nil(said[DASH.length..-1].strip)
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
        # because one format reads three of them and a reader sent to the wrong
        # one is sent nowhere.
        def self.refuse(path, line, said, topic)
          raise Unreadable, "#{Where.of(path)}:#{line} #{said}; sumi help #{topic} has the form"
        end
      end
    end
  end
end
