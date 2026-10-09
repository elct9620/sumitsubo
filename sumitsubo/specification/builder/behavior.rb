require "sumitsubo/specification"
require "sumitsubo/place"
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
      # numbers. A table arrives ahead of its rows, and the row naming its
      # columns is what says whether they are steps or attributes.
      class Behavior
        KINDS = [Block::HEADING, Block::PARAGRAPH,
                 Block::ITEM, Block::CODE, Block::TABLE, Block::ROW]

        # The levels this form is written at: a title, and a heading that either
        # scopes the feature or states a scenario.
        TITLE = 1
        SCENARIO = 2

        # A glob is written at the depth a list opens at. One written deeper
        # scopes nothing, the way a list under a scenario is prose.
        GLOB = 1

        # The words a step is spelled with, in the order a scenario states them:
        # as many states as it stands on, the one operation under test, and the
        # one outcome that operation settles. One outcome a scenario keeps a
        # scenario to one observation, so a second is a scenario of its own.
        STEPS = ["Given", "When", "Then"]

        # The attributes a scenario carries: the two taking the reason they are
        # said, and the two naming the statements it relates to and refines.
        ATTRIBUTES = { "unverifiable" => Builder::REASON, "deprecated" => Builder::REASON,
                       "relates" => Builder::KEYS, "refines" => Builder::KEYS }

        # The columns each table a scenario holds is headed by.
        STEPPED = ["Step", "Statement"]
        ATTRIBUTED = ["Attribute", "Value"]

        # The topic a refusal from this form sends a reader to.
        TOPIC = "behavior"

        def initialize(path)
          @path = Place.file(path)
          @refusals = []
          @key = nil
          @text = nil
          @scoping = false
          @scoped_at = nil
          @includes = []
          @scenarios = []
          @open = nil
          @table = nil
          @step = 0
          @misstepped = false
        end

        def build(blocks)
          blocks.each { |block| taken(block) }
          closed
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
          when Block::CODE then fenced(block)
          when Block::TABLE then tabled(block)
          when Block::ROW then stated(block)
          end
        end

        # A title names the feature, or a heading declares a scenario. Every
        # heading but the reserved one declares one, and which arrived is what
        # the items after it are read as.
        def heading(block)
          return titled(block) if block.level == TITLE
          return beside(block) if @scoping && block.level > SCENARIO
          return unless block.level == SCENARIO

          closed
          @scoping = block.text == INCLUDES
          return scoping(block.line) if @scoping

          @open = scenario_from(block)
          @scenarios.push(@open)
          @misstepped = @open.key.nil? || @open.key.empty?
        end

        # A scenario ends where the next heading at its level begins, and the
        # steps it never stated are said at its heading. One whose heading or
        # step rows were already refused has said what is wrong with it.
        def closed
          scenario = @open
          @open = nil
          @table = nil
          stepped = @step
          misstepped = @misstepped
          @step = 0
          @misstepped = false
          return if scenario.nil? || misstepped || stepped == STEPS.length

          gathered(scenario.line, "declares a scenario stating no #{STEPS[stepped]}")
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
          return beside(block) if @scoping
          return unless @text.nil? && @scenarios.empty?

          @text = block.text
        end

        def item(block)
          return unless @scoping
          return beside(block) unless block.level == GLOB

          @includes.push(Builder.scoped(block, @path, TOPIC, @includes))
        end

        def scoping(line)
          @refusals.push(Builder.rescoped(@path, line, @scoped_at, TOPIC)) unless @scoped_at.nil?
          @scoped_at = line if @scoped_at.nil?
        end

        # A fenced block says nothing to a feature anywhere but where the
        # globs stand.
        def fenced(block)
          beside(block) if @scoping
        end

        # A scenario's id is what a claim in the source names, so it is taken
        # letter for letter; what follows is the title, which nothing has to
        # match and so has no shape to keep.
        def scenario_from(block)
          id = block.taken
          if id.nil? || id.empty?
            gathered(block.line, "declares a scenario whose heading does not open with an id in backticks")
          end

          Statement.new(id, Builder.empty_to_nil(block.rest), [], @path, block.line, {}, [])
        end

        # Which table the rows after this one belong to, as the row naming its
        # columns says. Where no scenario holds it, or the globs stand, its
        # rows answer for themselves.
        def tabled(block)
          @table = block.cells.map { |cell| cell.text.strip }
          return if @scoping || @open.nil?
          return if @table == STEPPED || @table == ATTRIBUTED

          misstep(block.line, "writes a table headed #{@table.join(" and ")}, " \
                              "where a scenario holds its steps and its attributes")
        end

        # The cells of one row, stated as the step or the attribute they make.
        def stated(block)
          beside(block) if @scoping

          cells = block.cells
          return if cells.empty?

          line = cells[0].line
          refuse(line, "writes a row outside any scenario") if @open.nil?
          unless cells.length == 2
            said = "writes a row #{Builder.width_of(cells.length)}"
            @table == STEPPED ? misstep(line, said) : refuse(line, said)
          end

          name = cells[0].text.strip
          value = cells[1].text.strip
          if @table == STEPPED
            stage(line, name, value)
          elsif @table == ATTRIBUTED
            Builder.carried(@open.attributes, ATTRIBUTES,
                            Builder::Row.new(line: line, said: name, value: value),
                            "an attribute a scenario carries", @path, TOPIC)
          end
        end

        # One step, held under the scenario as what it states, where the order
        # says it may stand. A state may follow a state, and the operation and
        # its outcome are each stated once, in that order.
        def stage(line, name, said)
          # Compared in a block: Spinel 2026.09.12 hands `index(name)` a boxed
          # string where it takes a C one and refuses it. Master 0e8befeb does not.
          at = STEPS.index { |one| one == name }
          misstep(line, "writes #{name} among the steps, where Given, When and Then are written") if at.nil?
          return held(line, name, said) if @misstepped

          misstep(line, "writes #{name} after #{STEPS[@step - 1]}") if at + 1 < @step
          misstep(line, "writes #{name} a second time") if at + 1 == @step && at > 0
          misstep(line, "writes #{name} before #{STEPS[@step]}") if at > @step

          @step = at + 1
          held(line, name, said)
        end

        # Once a step stood out of order, where the rows after it stand follows
        # from that one, so they are held without being placed again.
        def held(line, name, said)
          @open.statements.push(Statement.new(name, said, [], @path, line, {}, []))
        end

        # A refusal standing where a step would, which says what is wrong with
        # the steps already.
        def misstep(line, said)
          @misstepped = true
          refuse(line, said)
        end

        def refuse(line, said)
          Builder.refuse(@path, line, said, TOPIC)
        end

        def beside(block)
          Builder.beside(block, @path, TOPIC)
        end
      end
    end
  end
end
