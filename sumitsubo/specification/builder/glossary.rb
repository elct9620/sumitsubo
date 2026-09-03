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

        # Two forms of the one path. A refusal is composed from the first; the
        # second is what a term and a rejected word carry, so a refusal naming
        # two of them points at both. The other forms hold one and render where
        # they answer.
        def initialize(path)
          @path = path
          @where = Place.file(path)
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
        # The document is the boundary a section is opened once inside, and the
        # name is the only handle a reader has on one: the tool tells two apart
        # by what each covers and by where each sits, and neither is on the
        # page.
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
        #
        # The section is the boundary a term is declared once inside. Across two,
        # a later term replacing an earlier one is the whole point of writing
        # two; inside one there is nothing to replace, so the first would leave
        # the run taking its rejected words with it and nothing said.
        def term(block)
          said = block.text
          refuse(block.line, "declares #{said} outside any section") if @section.nil?

          @holding = said == INCLUDES ? INCLUDES : nil
          @rejected = nil
          @term = nil
          return unless @holding.nil?

          first = @section.statements.find { |one| one.key == said }
          refuse(block.line, "declares #{said} a second time in #{@section.key}, first declared at #{first_at(first)}") unless first.nil?

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
        #
        # The term is the boundary a word is rejected once inside. A mention is
        # held under the term and the word alone, so two of them are one key —
        # one line reported twice with two reasons, and an ignore under either
        # setting both aside.
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

          first = @term.statements.find { |one| one.key == denied }
          refuse(block.line, "rejects #{denied} a second time under #{@term.key}, first rejected at #{first_at(first)}") unless first.nil?

          @rejected = Statement.new(denied, reason(block.rest), [], @where, block.line, {}, [])
          @term.statements.push(@rejected)
        end

        # One line a rejection does not answer for. Both halves are refused
        # rather than carried empty: one with nowhere to point matches nothing
        # and reports itself, and one with no reason is the exception that
        # outlives whoever knew why.
        #
        # The rejected word is the boundary a line is set aside once under. Two
        # naming one line are one key — the second's reason standing, and the
        # first never made to go stale, which is the exception outliving what it
        # was written for that a stale ignore exists to catch.
        def set_aside(block)
          return unless @holding == REJECTED

          refuse(block.line, "writes an ignore under no rejected word") if @rejected.nil?

          at = block.taken
          if at.nil? || at.empty?
            refuse(block.line, "writes an ignore that does not name a line in backticks")
          end

          why = reason(block.rest)
          refuse(block.line, "writes an ignore at #{at} with no reason") if why.nil?

          first = @rejected.statements.find { |one| one.key == at }
          refuse(block.line, "sets #{at} aside a second time under #{@rejected.key}, first set aside at #{first_at(first)}") unless first.nil?

          @rejected.statements.push(Statement.new(at, why, [], @where, block.line, {}, []))
        end

        # What a list item says after the word it took letter for letter. The
        # dash is taken off rather than counted past: it is written outside
        # ASCII, and a count of it would have to be the same kind of thing as
        # the index it is handed to.
        def reason(said)
          return Builder.empty_to_nil(said) unless said.start_with?(DASH)

          Builder.empty_to_nil(said.delete_prefix(DASH).strip)
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
