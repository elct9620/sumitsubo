require "sumitsubo/specification/parser/markdown/format"
require "sumitsubo/specification"

module Sumitsubo
  class Specification
    module Parser
      class Markdown
        module Builder
          # A vocabulary: the sections a project lays over one another, the terms
          # each declares, and the words those terms reject.
          #
          # The tree is deeper here than the other two builders answer, and that
          # is the whole of the difference — one file is still one specification.
          # A section is a container that asserts nothing itself; what asserts is
          # the term under it. Which section holds where another says nothing is
          # decided by what its globs cover and by the order they are written, so
          # the sections share one specification for that order to be written in.
          #
          # The query asks for the levels this form is written at and no others.
          # A nested item is anchored one level deeper than a plain one: without
          # that anchor a third level would arrive spelled exactly like the second
          # and be read as one, and two levels is what a list carries here.
          #
          # What a walk holds that no block carries is which heading a capture
          # arrived under: the reserved heading last seen says what the list items
          # after it are, and the term last opened says what a rejected word is
          # written under. That heading is held as itself rather than as a word
          # standing for it, so the state a walk is in and the heading a reader
          # wrote are the same thing.
          class Vocabulary
            QUERY = <<~QUERY
              (atx_heading (atx_h1_marker) (inline) @h1)
              (atx_heading (atx_h2_marker) (inline) @h2)
              (atx_heading (atx_h3_marker) (inline) @h3)
              (atx_heading (atx_h4_marker) (inline) @h4)
              (section (paragraph (inline) @paragraph))
              (section (list (list_item (paragraph (inline) @item))))
              (section (list (list_item (list (list_item (paragraph (inline) @nested))))))
            QUERY

            # The one heading a term carries, which no other kind knows.
            REJECTED = "Rejected"

            # The topic a refusal from this builder sends a reader to.
            TOPIC = "glossary"

            # What a reader puts between a word taken letter for letter and the
            # prose saying why. Taken off where it is there and not asked for
            # where it is not: a reason reads the same either way, so requiring it
            # would refuse nothing a person could have meant differently. `fmt` is
            # what puts it there.
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

            def query
              QUERY
            end

            def build(captures)
              captures.each { |capture| arrived(capture) }

              refuse(1, "declares no title") if @key.nil?
              # The sections carry the boundaries here, so the container declares
              # none. The shape allows one as their default; nothing needs it yet.
              Specification.new(@key, @text, [], @where, {}, @sections)
            end

            private

            def arrived(capture)
              said = Format.folded(capture.text)
              case capture.name
              when Format::H1 then titled(said, capture.line)
              when Format::H2 then section(said, capture.line)
              when Format::H3 then term(said, capture.line)
              when Format::H4 then rejects(said, capture.line)
              when Format::PARAGRAPH then defines(said)
              when Format::ITEM then listed(said, capture.line)
              when Format::NESTED then set_aside(said, capture.line)
              end
            end

            # A title names the vocabulary, and a file naming two says which of
            # them it is nowhere. It declares nothing by itself: it is what says
            # this document is a vocabulary at all, which is what leaves one
            # declaring no section a vocabulary that checks nothing rather than a
            # document read as the wrong kind.
            def titled(said, line)
              refuse(line, "declares a second title") unless @key.nil?

              @key = said
            end

            # No section name is reserved and none is supplied. Which vocabulary
            # holds where another says nothing is decided by what its globs cover
            # and by the order they are written, so a word for that role would
            # name something this builder does not do.
            def section(said, line)
              # Every section answers a list of globs whether or not it wrote
              # any, so what covers nothing is spelled the same as what covers
              # something and no caller is made to ask which it got.
              @section = Statement.new(said, nil, [], @where, line, {}, [])
              @sections.push(@section)
              @term = nil
              @rejected = nil
              @holding = nil
            end

            # A term, or the heading saying what the section covers. Either closes
            # whatever the one before it opened, so a rejected word never carries
            # past the term rejecting it.
            def term(said, line)
              refuse(line, "declares #{said} outside any section") if @section.nil?

              @holding = said == Format::INCLUDES ? Format::INCLUDES : nil
              @rejected = nil
              @term = nil
              return unless @holding.nil?

              @term = Statement.new(said, nil, [], @where, line, {}, [])
              @section.statements.push(@term)
            end

            # The one heading a term carries. A word other than the reserved one
            # is refused rather than passed over: a heading misspelled there takes
            # every rejection under it out of the run without saying so.
            def rejects(said, line)
              refuse(line, "writes #{said} outside any term") if @term.nil?
              refuse(line, "writes #{said} where only #{REJECTED} is read") unless said == REJECTED

              @holding = REJECTED
              @rejected = nil
            end

            # The paragraph under a heading says what that heading declares. Only
            # the first does: a vocabulary wanting a second is writing prose, the
            # same as a feature does under a scenario. The one above every section
            # says what the document itself is for.
            def defines(said)
              return unless @holding.nil?

              if @section.nil?
                @text = said if @text.nil?
                return
              end

              holder = @term.nil? ? @section : @term
              holder.text = said if holder.text.nil?
            end

            # What a list item is depends on the reserved heading it sits under: a
            # glob where the section says what it covers, a rejected word where a
            # term says what it refuses, and prose anywhere else.
            def listed(said, line)
              if @holding == Format::INCLUDES
                scoped(Format.glob(@path, line, said, TOPIC), line)
                return
              end
              return unless @holding == REJECTED

              opened = Format.code_span(said)
              refuse(line, "rejects a word that is not in backticks") if opened.nil?

              @rejected = Statement.new(opened.taken, reason(opened.after), [], @where, line, {}, [])
              @term.statements.push(@rejected)
            end

            # One glob onto the section it was written under. A boundary is a
            # section's rather than the document's, and the line is carried with
            # it because a glob covering nothing answers where a reader goes to
            # fix it.
            def scoped(glob, line)
              @section.includes.push(Statement.new(glob, nil, [], @where, line, {}, []))
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

              why = reason(opened.after)
              refuse(line, "writes an ignore at #{opened.taken} with no reason") if why.nil?

              @rejected.statements.push(Statement.new(opened.taken, why, [], @where, line, {}, []))
            end

            # What a list item says after the word it took letter for letter.
            def reason(said)
              return Format.empty_to_nil(said) unless said.index(DASH) == 0

              Format.empty_to_nil(said[DASH.length..-1].strip)
            end

            def refuse(line, said)
              Format.refuse(@path, line, said, TOPIC)
            end
          end
        end
      end
    end
  end
end
