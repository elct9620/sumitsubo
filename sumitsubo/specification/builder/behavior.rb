require "sumitsubo/specification"
require "sumitsubo/specification/builder"
require "sumitsubo/specification/block"

module Sumitsubo
  class Specification
    module Builder
      # A feature and its scenarios, built out of the blocks a document is made
      # of.
      #
      # The kinds are asked for rather than taken as they come, which is what
      # makes a subheading in a description prose: this form is written at the
      # levels below and reads nothing at any other.
      #
      # A row arrives whole, with the cells under it, so where one row ends and
      # the next begins is the grammar's answer rather than a comparison of line
      # numbers.
      class Behavior
        KINDS = [Block::HEADING, Block::PARAGRAPH,
                 Block::ITEM, Block::ROW]

        # The levels this form is written at: a title, and a heading that either
        # scopes the feature or states a scenario.
        TITLE = 1
        SCENARIO = 2

        # A glob is written at the depth a list opens at. One written deeper
        # scopes nothing, the way a list under a scenario is prose.
        GLOB = 1

        # The words a step is spelled with. A row naming another word is refused
        # rather than passed over: a step nobody reads is a promise nobody keeps.
        STEPS = ["Given", "When", "Then"]

        # The topic a refusal from this form sends a reader to.
        TOPIC = "behavior"

        def initialize(path)
          @path = path
          @refusals = []
          @key = nil
          @text = nil
          @scoping = false
          @includes = []
          @scenarios = []
        end

        def build(blocks)
          blocks.each { |block| taken(block) }
          gathered(1, "declares no title") if @key.nil?
          raise Sumitsubo::Misshapen.new(@refusals) unless @refusals.empty?

          Specification.new(@key, @text, @includes, @path, {}, @scenarios)
        end

        private

        # A refusal says one way the document is out of shape and stops the
        # block it was made about; the blocks after it are still read, so a
        # reader is handed all of them at once and fixes them in one pass. What
        # follows from an earlier refusal is a refusal too — the block it would
        # have leaned on is not there.
        def taken(block)
          arrived(block)
        rescue Sumitsubo::Misshapen => e
          @refusals.concat(e.refusals)
        end

        # A refusal gathered rather than raised, for where nothing after it
        # leans on what it was about.
        def gathered(line, said)
          @refusals.push(Builder.refusal(@path, line, said, TOPIC))
        end

        def arrived(block)
          case block.kind
          when Block::HEADING then heading(block)
          when Block::PARAGRAPH then described(block)
          when Block::ITEM then item(block)
          when Block::ROW then stated(block)
          end
        end

        # A title names the feature, or a heading declares a scenario. Every
        # heading but the reserved one declares one, and which arrived is what
        # the items after it are read as.
        def heading(block)
          return titled(block) if block.level == TITLE
          return unless block.level == SCENARIO

          @scoping = block.text == INCLUDES
          return if @scoping

          @scenarios.push(scenario_from(block))
        end

        # A file naming two titles says which of them it is nowhere.
        def titled(block)
          gathered(block.line, "declares a second title") unless @key.nil?

          @key = block.text
        end

        # Only the paragraph under the title says what the feature is for. A
        # scenario says it in its own heading, so a paragraph after one is prose
        # this form passes over.
        def described(block)
          return unless @text.nil? && @scenarios.empty?

          @text = block.text
        end

        def item(block)
          return unless @scoping && block.level == GLOB

          @includes.push(Builder.scoped(block, @path, TOPIC))
        end

        # A scenario's id is what a claim in the source names, so it is taken
        # letter for letter; what follows is the title, which nothing has to
        # match and so has no shape to keep.
        def scenario_from(block)
          id = block.taken
          if id.nil? || id.empty?
            gathered(block.line, "declares a scenario whose heading does not open with an id in backticks")
          end

          Statement.new(id, Builder.empty_to_nil(block.rest), [], @path, block.line,
                        { "given" => [] }, [])
        end

        # The cells of one row, stated as the step they make.
        def stated(block)
          cells = block.cells
          return if cells.empty?

          line = cells[0].line
          refuse(line, "writes a step outside any scenario") if @scenarios.empty?
          hold(step_of(line, cells.length, cells[0].text.strip), cells[1].text.strip)
        end

        # Which step a row states, given how many cells it turned out to have. A
        # row of any other width is a separator lost or an unescaped one gained,
        # and either way what it says cannot be told apart from what it means.
        def step_of(line, count, name)
          unless count == 2
            refuse(line, "writes a step row #{Builder.width_of(count)}")
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
          Builder.refuse(@path, line, said, TOPIC)
        end
      end
    end
  end
end
