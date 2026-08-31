require "sumitsubo/place"
require "sumitsubo/specification"
require "sumitsubo/specification/builder"
require "sumitsubo/specification/block"

module Sumitsubo
  class Specification
    module Builder
      # A vocabulary: the sections a project lays over one another, the terms
      # each declares, and the words those terms reject.
      #
      # The tree is deeper here than the other two forms answer, and that is the
      # whole of the difference — one file is still one specification. A section
      # is a container that asserts nothing itself; what asserts is the term
      # under it. Which section holds where another says nothing is decided by
      # what its globs cover and by the order they are written, so the sections
      # share one specification for that order to be written in.
      #
      # What a walk holds that no block carries is which heading a capture
      # arrived under: the reserved heading last seen says what the list items
      # after it are, and the term last opened says what a rejected word is
      # written under. That heading is held as itself rather than as a word
      # standing for it, so the state a walk is in and the heading a reader wrote
      # are the same thing.
      class Glossary
        KINDS = [Block::HEADING, Block::PARAGRAPH, Block::ITEM]

        # The levels this form is written at: a title, a section, a term, and
        # the one heading a term carries.
        TITLE = 1
        SECTION = 2
        TERM = 3
        REJECTS = 4

        # A glob and a rejected word are written at the depth a list opens at,
        # and a line set aside one deeper.
        WORD = 1
        IGNORE = 2

        # The one heading a term carries, which no other kind knows.
        REJECTED = "Rejected"

        # The topic a refusal from this form sends a reader to.
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
          @key = nil
          @text = nil
          @sections = []
          @section = nil
          @term = nil
          @rejected = nil
          @holding = nil
        end

        def build(blocks)
          blocks.each { |block| arrived(block) }

          refuse(1, "declares no title") if @key.nil?
          # The sections carry the boundaries here, so the container declares
          # none. The shape allows one as their default; nothing needs it yet.
          Specification.new(@key, @text, [], @where, {}, @sections)
        end

        private

        def arrived(block)
          case block.kind
          when Block::HEADING then heading(block)
          when Block::PARAGRAPH then defines(block)
          when Block::ITEM then listed(block)
          end
        end

        def heading(block)
          case block.level
          when TITLE then titled(block)
          when SECTION then section(block)
          when TERM then term(block)
          when REJECTS then rejects(block)
          end
        end

        # A title names the vocabulary, and a file naming two says which of them
        # it is nowhere. It declares nothing by itself: it is what says this
        # document is a vocabulary at all, which is what leaves one declaring no
        # section a vocabulary that checks nothing rather than a document read as
        # the wrong kind.
        def titled(block)
          refuse(block.line, "declares a second title") unless @key.nil?

          @key = block.text
        end

        # No section name is reserved and none is supplied. Which vocabulary
        # holds where another says nothing is decided by what its globs cover
        # and by the order they are written, so a word for that role would name
        # something this form does not do.
        #
        # The name is refused a second time because it is the only handle a
        # reader has on a section. The tool tells two apart by what each covers
        # and by where each sits, and neither of those is on the page.
        def section(block)
          said = block.text
          first = @sections.find { |one| one.key == said }
          refuse(block.line, "opens a second section named #{said}, first opened at #{first_at(first)}") unless first.nil?

          @section = Statement.new(said, nil, [], @where, block.line, {}, [])
          @sections.push(@section)
          @term = nil
          @rejected = nil
          @holding = nil
        end

        # A term, or the heading saying what the section covers. Either closes
        # whatever the one before it opened, so a rejected word never carries
        # past the term rejecting it.
        def term(block)
          said = block.text
          refuse(block.line, "declares #{said} outside any section") if @section.nil?

          @holding = said == INCLUDES ? INCLUDES : nil
          @rejected = nil
          @term = nil
          return unless @holding.nil?

          @term = Statement.new(said, nil, [], @where, block.line, {}, [])
          @section.statements.push(@term)
        end

        # The one heading a term carries. A word other than the reserved one is
        # refused rather than passed over: a heading misspelled there takes every
        # rejection under it out of the run without saying so.
        def rejects(block)
          said = block.text
          refuse(block.line, "writes #{said} outside any term") if @term.nil?
          refuse(block.line, "writes #{said} where only #{REJECTED} is read") unless said == REJECTED

          @holding = REJECTED
          @rejected = nil
        end

        # The paragraph under a heading says what that heading declares. Only the
        # first does: a vocabulary wanting a second is writing prose, the same as
        # a feature does under a scenario. The one above every section says what
        # the document itself is for.
        def defines(block)
          return unless @holding.nil?

          if @section.nil?
            @text = block.text if @text.nil?
            return
          end

          holder = @term.nil? ? @section : @term
          holder.text = block.text if holder.text.nil?
        end

        # What a list item is depends on the reserved heading it sits under and
        # on how deep it was written: a glob where the section says what it
        # covers, a rejected word where a term says what it refuses, a line set
        # aside under that word, and prose anywhere else.
        def listed(block)
          return set_aside(block) if block.level == IGNORE
          return unless block.level == WORD
          if @holding == INCLUDES
            @section.includes.push(Builder.scoped(block, @path, TOPIC))
            return
          end
          return unless @holding == REJECTED

          denied = block.taken
          refuse(block.line, "rejects a word that is not in backticks") if denied.nil? || denied.empty?

          @rejected = Statement.new(denied, reason(block.rest), [], @where, block.line, {}, [])
          @term.statements.push(@rejected)
        end

        # One line a rejection does not answer for. Both halves are refused
        # rather than carried empty: one with nowhere to point matches nothing
        # and reports itself, and one with no reason is the exception that
        # outlives whoever knew why.
        def set_aside(block)
          return unless @holding == REJECTED

          refuse(block.line, "writes an ignore under no rejected word") if @rejected.nil?

          at = block.taken
          if at.nil? || at.empty?
            refuse(block.line, "writes an ignore that does not name a line in backticks")
          end

          why = reason(block.rest)
          refuse(block.line, "writes an ignore at #{at} with no reason") if why.nil?

          @rejected.statements.push(Statement.new(at, why, [], @where, block.line, {}, []))
        end

        # What a list item says after the word it took letter for letter.
        def reason(said)
          return Builder.empty_to_nil(said) unless said.index(DASH) == 0

          Builder.empty_to_nil(said[DASH.length..-1].strip)
        end

        # Where the first of a name was written, for a refusal naming both. A
        # statement holds the file as a reader will see it, so the place is made
        # from that rather than rendered a second time.
        def first_at(statement)
          Place.new(path: statement.path, line: statement.line).spoken
        end

        def refuse(line, said)
          Builder.refuse(@path, line, said, TOPIC)
        end
      end
    end
  end
end
