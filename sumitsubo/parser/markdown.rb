require "pathname"
require "sumitsubo/error"
require "sumitsubo/specification"
require "sumitsubo/where"

module Sumitsubo
  module Parser
    # A specification as Markdown, which is the document a person reads as well
    # as the reference line the tool compares against.
    #
    # The grammar is handed in rather than reached for, the way a language is,
    # so nothing here opens the binding: what a build carries decides which
    # grammar answers, and this file can be read — and its test regenerated —
    # without one.
    #
    # Captures arrive in the order the grammar met them, so what a document
    # says is one run of blocks read start to end. Depth comes from which
    # heading a capture arrived under rather than from the tree: a section
    # nests by level, and the grammar spells each level as a kind of its own.
    class Markdown
      # The extension is the whole of what says a file is written this way. A
      # specification is named by the project rather than found by its content,
      # so nothing here opens the file to decide.
      SUFFIX = ".md"

      # The grammar the query below is written against. Node names are that
      # grammar's own and no two spell one alike, so the query and the name
      # travel together rather than the name arriving from outside.
      GRAMMAR = "markdown"

      # The blocks a specification is written in — which is to say, the format.
      # A block a specification may be written in is here; anything else a
      # document holds is prose the readings walk past. So a mechanism never
      # extends this: three of them share one query, and what a fourth needs is
      # already captured. Adding a pattern is widening the format, which is a
      # decision worth writing down rather than a line worth adding quietly.
      #
      # Every heading level is asked for, because six is all Markdown has and a
      # level nobody captures is a heading that vanishes with its section. A
      # heading arrives under a name for its level rather than with the level to
      # read: the grammar spells each marker as a kind of its own, and no level
      # means one thing across the readings — an h3 states a term in a
      # vocabulary and is prose in a feature.
      #
      # Every other pattern is anchored at the section holding it, which is what
      # tells a paragraph of its own from the paragraph a list item is made of —
      # both are `(paragraph (inline))`, and only where they sit says which. A
      # nested item is anchored one level deeper for the same reason:
      # unanchored, a third level would arrive spelled exactly like the second
      # and be read as one. Two levels is what a list carries here, so a third
      # is captured by nothing.
      #
      # A fence and a table row are each asked for as well as their parts, and
      # arrive ahead of them, so where one ends is the grammar's answer rather
      # than a comparison of line numbers — and a fence carrying no language is
      # still a fence rather than nothing. The cells stay the grammar's too: a
      # separator a document escapes belongs to the cell holding it, and
      # splitting the row's own text would take it for a separator.
      BLOCKS = <<~BLOCKS
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
      BLOCKS

      # What the query calls each thing it captures. A block says what it is by
      # the name it arrives under, so nothing here reads the text to decide.
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

      # The heading that says what a specification answers for rather than
      # declaring something. It is prose, so a scenario of the same name is
      # written in a code span and does not collide with it.
      INCLUDES = "Includes"

      # The words a step is spelled with. A row naming another word is refused
      # rather than passed over: a step nobody reads is a promise nobody keeps.
      STEPS = ["Given", "When", "Then"]

      def initialize(grammar)
        @grammar = grammar
      end

      def reads?(path)
        "#{path}".end_with?(SUFFIX)
      end

      def behavior(path)
        read(blocks_in(path), path)
      end

      # The line each include is written on. The reserved heading says which
      # list items are includes, the same as the reading below; what a finding
      # wants of them is the line rather than the glob. Asked only once one of
      # them turned out to cover nothing, so a document whose includes all
      # reach a file is never read a second time.
      def spelled_in(path)
        found = {}
        scoping = false
        blocks_in(path).each do |capture|
          scoping = folded(capture.text) == INCLUDES if capture.name == H2
          next unless capture.name == ITEM && scoping

          glob = spelled(path, capture.line, folded(capture.text))
          found[glob] = capture.line if found[glob].nil?
        end
        found
      end

      private

      # Every byte sequence is a legal document, so the grammar refuses
      # nothing: what a specification written wrong loses is the shape the
      # query matches, and saying so is this file's rather than the grammar's.
      def blocks_in(path)
        file = Pathname.new(path)
        @grammar.captures_in(GRAMMAR, file, BLOCKS, Where.of(file))
      end

      # A feature and its scenarios. What this holds that no block carries is
      # the order they arrived in — which scenario a row states its step under,
      # and where one row ends.
      def read(captures, path)
        key = nil
        text = nil
        scoping = false
        includes = []
        scenarios = []
        row = []

        captures.each do |capture|
          name = capture.name
          # A row is closed by the first capture that is not one of its own
          # cells. That is what the row itself is asked for: a heading or a
          # paragraph after a table closes the last row on its own, and between
          # two rows there would otherwise be nothing to tell them apart.
          unless name == CELL
            stated(path, scenarios, row)
            row = []
          end

          case name
          when H1
            key = titled(path, capture, key)
          when PARAGRAPH
            text = described(capture, text, scenarios.empty?)
          when H2
            scoping = heading(path, capture, scenarios)
          when ITEM
            item(path, capture, includes) if scoping
          when CELL
            row.push(capture)
          end
        end
        stated(path, scenarios, row)

        refuse(path, 1, "declares no title") if key.nil?
        Specification.new(key, text, includes, path, {}, scenarios)
      end

      # Every heading but the reserved one declares a scenario. Which kind this
      # was is answered rather than kept, because it is what the items after it
      # are read as: under the reserved one they spell includes, and anywhere
      # else a list is prose.
      def heading(path, capture, scenarios)
        said = folded(capture.text)
        return true if said == INCLUDES

        scenarios.push(scenario_from(path, said, capture.line))
        false
      end

      def item(path, capture, includes)
        includes.push(spelled(path, capture.line, folded(capture.text)))
      end

      # A title names the feature, and a file naming two says which of them it
      # is nowhere.
      def titled(path, capture, key)
        refuse(path, capture.line, "declares a second title") unless key.nil?

        folded(capture.text)
      end

      # Only the paragraph under the title says what the feature is for. A
      # scenario says it in its own heading, so a paragraph after one is prose
      # this parser passes over.
      def described(capture, text, opening)
        text.nil? && opening ? folded(capture.text) : text
      end

      # The cells held so far, stated as the step they make. A row is closed
      # by what follows it, so the last row in a document is closed by the
      # document ending — the one close nothing in the run announces.
      def stated(path, scenarios, row)
        return if row.empty?

        refuse(path, row[0].line, "writes a step outside any scenario") if scenarios.empty?
        under = step_of(path, row[0].line, row.length, row[0].text.strip)
        hold(scenarios[-1].attributes, under, row[1].text.strip)
      end

      # A scenario's id is what a claim in the source names, so it is spelled
      # in a code span and taken from it letter for letter; what follows is the
      # title, which nothing has to match and so has no shape to keep.
      def scenario_from(path, said, line)
        opened = code_span(said)
        if opened.nil? || opened[0].empty?
          refuse(path, line, "declares a scenario whose heading does not open with an id in backticks")
        end

        Statement.new(opened[0], empty_to_nil(opened[1]), path, line, { "given" => [] }, [])
      end

      # Which step a row states, given how many cells it turned out to have. A
      # row of any other width is a separator lost or an unescaped one gained,
      # and either way what it says cannot be told apart from what it means.
      def step_of(path, line, cells, name)
        unless cells == 2
          refuse(path, line, "writes a step row of #{cells} #{cells == 1 ? "cell" : "cells"} rather than two")
        end
        unless STEPS.include?(name)
          refuse(path, line, "writes a step named #{name} rather than Given, When or Then")
        end

        name.downcase
      end

      # A step joins the ones already stated under that word, so a scenario
      # standing on two states reads as two rows and is held as two.
      def hold(steps, under, said)
        holding = steps[under]
        steps[under] = holding.nil? ? [said] : holding + [said]
      end

      # An include is taken letter for letter, so it is spelled in a code span
      # the way every other thing the tool consumes unread is.
      def spelled(path, line, said)
        opened = code_span(said)
        refuse(path, line, "writes an include that is not a glob in backticks") if opened.nil?

        opened[0]
      end

      # What a pair of backticks opens the text with, and what follows it.
      # Found by the marks themselves rather than by a pattern: what is wanted
      # is the run between them, and taking it is not recognising a shape.
      def code_span(said)
        return nil unless said.index("`") == 0

        closed = said.index("`", 1)
        return nil if closed.nil?

        [said[1, closed - 1], said[(closed + 1)..-1].strip]
      end

      # A soft line break is a space, which is what lets a paragraph be wrapped
      # for a reader without the wrapping reaching what it says.
      def folded(said)
        said.split("\n").map { |line| line.strip }.join(" ")
      end

      def empty_to_nil(said)
        said.empty? ? nil : said
      end

      def refuse(path, line, said)
        raise Unreadable, "#{Where.of(path)}:#{line} #{said}; sumi help behavior has the form"
      end
    end
  end
end
