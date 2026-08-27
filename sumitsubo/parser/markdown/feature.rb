require "sumitsubo/parser/markdown/format"
require "sumitsubo/specification"

module Sumitsubo
  module Parser
    class Markdown
      # A feature and its scenarios, read from the blocks a document is made
      # of. What this holds that no block carries is the order they arrived in
      # — which scenario a row states its step under, and where one row ends.
      #
      # One of these reads one document, so what a walk is in the middle of is
      # held here rather than threaded through every method that needs it.
      class Feature
        # The words a step is spelled with. A row naming another word is
        # refused rather than passed over: a step nobody reads is a promise
        # nobody keeps.
        STEPS = ["Given", "When", "Then"]

        # The topic a refusal from this reading sends a reader to.
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

        def read(captures)
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
          # paragraph after a table closes the last row on its own, and between
          # two rows there would otherwise be nothing to tell them apart.
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
        # prose this reading passes over.
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

        # An include is taken letter for letter, so it is spelled in a code
        # span the way every other thing the tool consumes unread is.
        def item(capture)
          @includes.push(spelled(capture.line, Format.folded(capture.text)))
        end

        # The cells held so far, stated as the step they make. A row is closed
        # by what follows it, so the last row in a document is closed by the
        # document ending — the one close nothing in the run announces.
        def stated
          return if @row.empty?

          line = @row[0].line
          refuse(line, "writes a step outside any scenario") if @scenarios.empty?
          hold(step_of(line, @row.length, @row[0].text.strip), @row[1].text.strip)
        end

        # A scenario's id is what a claim in the source names, so it is spelled
        # in a code span and taken from it letter for letter; what follows is
        # the title, which nothing has to match and so has no shape to keep.
        def scenario_from(said, line)
          opened = Format.code_span(said)
          if opened.nil? || opened[0].empty?
            refuse(line, "declares a scenario whose heading does not open with an id in backticks")
          end

          Statement.new(opened[0], Format.empty_to_nil(opened[1]), @path, line, { "given" => [] }, [])
        end

        # Which step a row states, given how many cells it turned out to have.
        # A row of any other width is a separator lost or an unescaped one
        # gained, and either way what it says cannot be told apart from what it
        # means.
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

        def spelled(line, said)
          opened = Format.code_span(said)
          refuse(line, "writes an include that is not a glob in backticks") if opened.nil?

          opened[0]
        end

        def refuse(line, said)
          Format.refuse(@path, line, said, TOPIC)
        end
      end
    end
  end
end
