require "sumitsubo/parser/markdown/format"
require "sumitsubo/specification"

module Sumitsubo
  module Parser
    class Markdown
      module Builder
        # A feature and its scenarios, built out of the blocks a document is
        # made of.
        #
        # The query is here rather than beside the format because a feature and
        # a vocabulary are two forms sharing one syntax: the same level states a
        # term in one and is prose in the other. Asking only for what this form
        # is written in is what makes a subheading in a description prose — it
        # is never captured, rather than captured and passed over — and what
        # lets a fourth kind of specification be added without widening anything
        # a third one reads.
        #
        # A table row is asked for as well as its cells, and arrives ahead of
        # them, so where one row ends and the next begins is the grammar's
        # answer rather than a comparison of line numbers. The cells stay the
        # grammar's too: a separator a document escapes belongs to the cell
        # holding it, and splitting the row's own text would take it for a
        # separator.
        #
        # One of these builds one document, so what a walk is in the middle of
        # is held here rather than threaded through every method that needs it.
        class Feature
          QUERY = <<~QUERY
            (atx_heading (atx_h1_marker) (inline) @h1)
            (atx_heading (atx_h2_marker) (inline) @h2)
            (section (paragraph (inline) @paragraph))
            (section (list (list_item (paragraph (inline) @item))))
            (pipe_table_row) @row
            (pipe_table_row (pipe_table_cell) @cell)
          QUERY

          # The words a step is spelled with. A row naming another word is
          # refused rather than passed over: a step nobody reads is a promise
          # nobody keeps.
          STEPS = ["Given", "When", "Then"]

          # The topic a refusal from this builder sends a reader to.
          TOPIC = "behavior"

          def initialize(path)
            @path = path
            @key = nil
            @text = nil
            @scoping = false
            @includes = []
            @scenarios = []
            @row = []
          end

          def query
            QUERY
          end

          def build(captures)
            captures.each { |capture| arrived(capture) }
            stated

            refuse(1, "declares no title") if @key.nil?
            Specification.new(@key, @text, @includes, @path, {}, @scenarios)
          end

          private

          def arrived(capture)
            name = capture.name
            # A row is closed by the first capture that is not one of its own
            # cells. That is what the row itself is asked for: a heading or a
            # paragraph after a table closes the last row on its own, and
            # between two rows there would otherwise be nothing to tell them
            # apart.
            unless name == Format::CELL
              stated
              @row = []
            end

            case name
            when Format::H1 then titled(capture)
            when Format::PARAGRAPH then described(capture)
            when Format::H2 then heading(capture)
            when Format::ITEM then item(capture) if @scoping
            when Format::CELL then @row.push(capture)
            end
          end

          # A title names the feature, and a file naming two says which of them
          # it is nowhere.
          def titled(capture)
            refuse(capture.line, "declares a second title") unless @key.nil?

            @key = Format.folded(capture.text)
          end

          # Only the paragraph under the title says what the feature is for. A
          # scenario says it in its own heading, so a paragraph after one is
          # prose this builder passes over.
          def described(capture)
            return unless @text.nil? && @scenarios.empty?

            @text = Format.folded(capture.text)
          end

          # Every heading but the reserved one declares a scenario. Which kind
          # arrived is what the items after it are read as: under the reserved
          # one they spell includes, and anywhere else a list is prose.
          def heading(capture)
            said = Format.folded(capture.text)
            @scoping = said == Format::INCLUDES
            return if @scoping

            @scenarios.push(scenario_from(said, capture.line))
          end

          def item(capture)
            @includes.push(Format.glob(@path, capture.line, Format.folded(capture.text), TOPIC))
          end

          # The cells held so far, stated as the step they make. A row is
          # closed by what follows it, so the last row in a document is closed
          # by the document ending — the one close nothing in the run
          # announces.
          def stated
            return if @row.empty?

            line = @row[0].line
            refuse(line, "writes a step outside any scenario") if @scenarios.empty?
            hold(step_of(line, @row.length, @row[0].text.strip), @row[1].text.strip)
          end

          # A scenario's id is what a claim in the source names, so it is
          # spelled in a code span and taken from it letter for letter; what
          # follows is the title, which nothing has to match and so has no
          # shape to keep.
          def scenario_from(said, line)
            opened = Format.code_span(said)
            if opened.nil? || opened.taken.empty?
              refuse(line, "declares a scenario whose heading does not open with an id in backticks")
            end

            Statement.new(opened.taken, Format.empty_to_nil(opened.after), @path, line, { "given" => [] }, [])
          end

          # Which step a row states, given how many cells it turned out to
          # have. A row of any other width is a separator lost or an unescaped
          # one gained, and either way what it says cannot be told apart from
          # what it means.
          def step_of(line, cells, name)
            unless cells == 2
              refuse(line, "writes a step row of #{cells} #{cells == 1 ? "cell" : "cells"} rather than two")
            end
            refuse(line, "writes a step named #{name} rather than Given, When or Then") unless STEPS.include?(name)

            name.downcase
          end

          # A step joins the ones already stated under that word, so a scenario
          # standing on two states reads as two rows and is held as two.
          def hold(under, said)
            steps = @scenarios[-1].attributes
            holding = steps[under]
            steps[under] = holding.nil? ? [said] : holding + [said]
          end

          def refuse(line, said)
            Format.refuse(@path, line, said, TOPIC)
          end
        end
      end
    end
  end
end
