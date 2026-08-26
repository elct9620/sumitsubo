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

      # What the query calls each thing it captures. A block says what it is by
      # the name it arrives under, so nothing here reads the text to decide.
      TITLE = "title"
      HEADING = "heading"
      PARAGRAPH = "paragraph"
      ITEM = "item"
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

      private

      # Every byte sequence is a legal document, so the grammar refuses
      # nothing: what a specification written wrong loses is the shape the
      # query matches, and saying so is this file's rather than the grammar's.
      def blocks_in(path)
        file = Pathname.new(path)
        @grammar.captures_in(GRAMMAR, file, BLOCKS, Where.of(file))
      end

      # A feature and its scenarios. The title names the feature and the
      # paragraph under it says what it is for; every other heading declares a
      # scenario, whose id is the code span it opens with and whose title is
      # the rest of that same heading.
      def read(captures, path)
        key = nil
        text = nil
        scoping = false
        includes = []
        scenarios = []
        row = []

        captures.each do |capture|
          name = capture.name
          # A table row is one line, so the cells held so far are a row as soon
          # as anything on another line arrives.
          if !row.empty? && !(name == CELL && capture.line == row[0].line)
            refuse(path, row[0].line, "writes a step outside any scenario") if scenarios.empty?
            under = step_of(path, row[0].line, row.length, row[0].text.strip)
            hold(scenarios[-1].attributes, under, row[1].text.strip)
            row = []
          end

          case name
          when TITLE
            refuse(path, capture.line, "declares a second title") unless key.nil?

            key = folded(capture.text)
          when PARAGRAPH
            # Only the paragraph under the title says what the feature is for.
            # A scenario says it in its own heading, so a paragraph after one
            # is prose this parser passes over.
            text = folded(capture.text) if text.nil? && scenarios.empty?
          when HEADING
            said = folded(capture.text)
            scoping = said == INCLUDES
            scenarios.push(scenario_from(path, said, capture.line)) unless scoping
          when ITEM
            includes.push(spelled(path, capture.line, folded(capture.text))) if scoping
          when CELL
            row.push(capture)
          end
        end

        unless row.empty?
          refuse(path, row[0].line, "writes a step outside any scenario") if scenarios.empty?
          under = step_of(path, row[0].line, row.length, row[0].text.strip)
          hold(scenarios[-1].attributes, under, row[1].text.strip)
        end

        refuse(path, 1, "declares no title") if key.nil?
        Specification.new(key, text, includes, path, {}, scenarios)
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
