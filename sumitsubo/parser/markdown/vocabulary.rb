require "sumitsubo/parser/markdown/format"
require "sumitsubo/specification"

module Sumitsubo
  module Parser
    class Markdown
      # A vocabulary and the subdomains laid over it. This answers a list where
      # the other readings answer one specification, because a project writes
      # its whole vocabulary in one file and each heading at the second level
      # opens another section of it.
      #
      # No section name is reserved and none is supplied. Which vocabulary
      # holds where another says nothing is decided by what its globs cover and
      # by the order they are written, so a word for that role would name
      # something this reading does not do.
      #
      # What a walk holds that no block carries is which heading a capture
      # arrived under: the reserved heading last seen says what the list items
      # after it are, and the term last opened says what a rejected word is
      # written under. That heading is held as itself rather than as a word
      # standing for it, so the state a walk is in and the heading a reader
      # wrote are the same thing.
      class Vocabulary
        # The one heading a term carries, which no other reading knows.
        REJECTED = "Rejected"

        # The topic a refusal from this reading sends a reader to.
        TOPIC = "glossary"

        # What a reader puts between a word taken letter for letter and the
        # prose saying why. Taken off where it is there and not asked for where
        # it is not: a reason reads the same either way, so requiring it would
        # refuse nothing a person could have meant differently. `fmt` is what
        # puts it there.
        DASH = "—"

        def initialize(path, where)
          @path = path
          @where = where
          @sections = []
          @term = nil
          @rejected = nil
          @holding = nil
        end

        def read(captures)
          captures.each { |capture| arrived(capture) }

          refuse(1, "declares no section") if @sections.empty?
          @sections
        end

        private

        def arrived(capture)
          said = Format.folded(capture.text)
          case capture.name
          when Format::H2 then section(said)
          when Format::H3 then term(said, capture.line)
          when Format::H4 then rejects(said, capture.line)
          when Format::PARAGRAPH then defines(said)
          when Format::ITEM then listed(said, capture.line)
          when Format::NESTED then set_aside(said, capture.line)
          end
        end

        def section(said)
          @sections.push(Specification.new(said, nil, [], @where, {}, []))
          @term = nil
          @rejected = nil
          @holding = nil
        end

        # A term, or the heading saying what the section covers. Either closes
        # whatever the one before it opened, so a rejected word never carries
        # past the term rejecting it.
        def term(said, line)
          refuse(line, "declares #{said} outside any section") if @sections.empty?

          @holding = said == Format::INCLUDES ? Format::INCLUDES : nil
          @rejected = nil
          @term = nil
          return unless @holding.nil?

          @term = Statement.new(said, nil, @where, line, {}, [])
          @sections[-1].statements.push(@term)
        end

        # The one heading a term carries. A word other than the reserved one is
        # refused rather than passed over: a heading misspelled there takes
        # every rejection under it out of the run without saying so.
        def rejects(said, line)
          refuse(line, "writes #{said} outside any term") if @term.nil?
          refuse(line, "writes #{said} where only #{REJECTED} is read") unless said == REJECTED

          @holding = REJECTED
          @rejected = nil
        end

        # The paragraph under a heading says what that heading declares. Only
        # the first does: a vocabulary wanting a second is writing prose, the
        # same as a feature does under a scenario. A paragraph above every
        # section is what the document says of itself, which nothing declares.
        def defines(said)
          return unless @holding.nil?

          holder = @term.nil? ? @sections[-1] : @term
          return if holder.nil?

          holder.text = said if holder.text.nil?
        end

        # What a list item is depends on the reserved heading it sits under: a
        # glob where the section says what it covers, a rejected word where a
        # term says what it refuses, and prose anywhere else.
        def listed(said, line)
          if @holding == Format::INCLUDES
            @sections[-1].includes.push(spelled(line, said))
            return
          end
          return unless @holding == REJECTED

          opened = Format.code_span(said)
          refuse(line, "rejects a word that is not in backticks") if opened.nil?

          @rejected = Statement.new(opened[0], reason(opened[1]), @where, line, {}, [])
          @term.statements.push(@rejected)
        end

        # One line a rejection does not answer for. Both halves are refused
        # rather than carried empty: one with nowhere to point matches nothing
        # and reports itself, and one with no reason is the exception that
        # outlives whoever knew why.
        def set_aside(said, line)
          return unless @holding == REJECTED

          refuse(line, "writes an ignore under no rejected word") if @rejected.nil?

          opened = Format.code_span(said)
          refuse(line, "writes an ignore that does not name a line in backticks") if opened.nil?

          why = reason(opened[1])
          refuse(line, "writes an ignore at #{opened[0]} with no reason") if why.nil?

          @rejected.statements.push(Statement.new(opened[0], why, @where, line, {}, []))
        end

        # What a list item says after the word it took letter for letter.
        def reason(said)
          return Format.empty_to_nil(said) unless said.index(DASH) == 0

          Format.empty_to_nil(said[DASH.length..-1].strip)
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
