require "sumitsubo/error"
require "sumitsubo/specification"
require "sumitsubo/where"

module Sumitsubo
  module Reading
    # What the markdown grammar hands back, made into a specification — the
    # part of that work no grammar owns.
    #
    # Nothing here reaches the binding: a reading captures what its own query
    # asked for and brings the captures here, which is what keeps this file,
    # and every test of it, on the side a snapshot can be regenerated from.
    #
    # Captures arrive in the order the parser met them, so what a document says
    # is one run of blocks read start to end. Depth comes from which heading
    # the capture arrived under rather than from the tree: a section nests by
    # level, and the grammar spells each level as a kind of its own.
    #
    # The walk keeps what it has read in one scope and the helpers take words
    # and lines rather than what is being built. That is the compiler's
    # constraint as much as this reading's: a collection crossing a method
    # boundary reaches it carrying a type it settles from the first call.
    module Blocks
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

      # A feature and its scenarios. The title names the feature and the
      # paragraph under it says what it is for; every other heading declares a
      # scenario, whose id is the code span it opens with and whose title is
      # the rest of that same heading.
      def self.behavior(captures, path)
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
            # is prose this reading passes over.
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
      def self.scenario_from(path, said, line)
        opened = code_span(said)
        if opened.nil? || opened[0].empty?
          refuse(path, line, "declares a scenario whose heading does not open with an id in backticks")
        end

        Statement.new(opened[0], empty_to_nil(opened[1]), path, line, { "given" => [] }, [])
      end

      # Which step a row states, given how many cells it turned out to have. A
      # row of any other width is a separator lost or an unescaped one gained,
      # and either way what it says cannot be told apart from what it means.
      def self.step_of(path, line, cells, name)
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
      def self.hold(steps, under, said)
        holding = steps[under]
        steps[under] = holding.nil? ? [said] : holding + [said]
      end

      # An include is taken letter for letter, so it is spelled in a code span
      # the way every other thing the tool consumes unread is.
      def self.spelled(path, line, said)
        opened = code_span(said)
        refuse(path, line, "writes an include that is not a glob in backticks") if opened.nil?

        opened[0]
      end

      # What a pair of backticks opens the text with, and what follows it.
      # Found by the marks themselves rather than by a pattern: what is wanted
      # is the run between them, and taking it is not recognising a shape.
      def self.code_span(said)
        return nil unless said.index("`") == 0

        closed = said.index("`", 1)
        return nil if closed.nil?

        [said[1, closed - 1], said[(closed + 1)..-1].strip]
      end

      # A soft line break is a space, which is what lets a paragraph be wrapped
      # for a reader without the wrapping reaching what it says.
      def self.folded(said)
        said.split("\n").map { |line| line.strip }.join(" ")
      end

      def self.empty_to_nil(said)
        said.empty? ? nil : said
      end

      def self.refuse(path, line, said)
        raise Unreadable, "#{Where.of(path)}:#{line} #{said}; sumi help behavior has the form"
      end
    end
  end
end
