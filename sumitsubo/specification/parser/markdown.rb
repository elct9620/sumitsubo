require "pathname"
require "sumitsubo/error"
require "sumitsubo/place"
require "sumitsubo/specification/block"

module Sumitsubo
  class Specification
    module Parser
      # A specification as Markdown, which is the document a person reads as well
      # as the reference line the tool compares against.
      #
      # The grammars are handed in rather than reached for, the way a language is,
      # so nothing here opens the binding: what a build carries decides which one
      # answers, and this file can be read — and its test regenerated — without
      # one.
      #
      # This is where Markdown stops. A form says which kinds of block it is
      # written in and gets blocks back, so what a heading level means, or what a
      # run in backticks is for, is never asked here.
      #
      # Two grammars answer, and they are put in that order rather than by turns:
      # every document's structure first, then the text inside every block of it.
      # Each query is compiled once that way, where asking both of one document at
      # a time recompiles them for every file.
      class Markdown
        # The extension is the whole of what says a file is written this way. A
        # specification is named by the project rather than found by its content,
        # so nothing here opens the file to decide.
        SUFFIX = ".md"

        # The grammars every query here is written against. Node names are one
        # grammar's own and no two spell one alike, so the names travel with the
        # queries rather than arriving from outside.
        GRAMMAR = "markdown"
        INLINE = "markdown_inline"

        # What each kind is written as.
        #
        # A fence and a row are each asked for as well as their parts, and arrive
        # ahead of them, so one carrying neither is still itself — and where one
        # ends is the grammar's answer rather than a comparison of line numbers.
        PATTERNS = {
          Block::HEADING => <<~QUERY,
            (atx_heading (atx_h1_marker) (inline) @h1)
            (atx_heading (atx_h2_marker) (inline) @h2)
            (atx_heading (atx_h3_marker) (inline) @h3)
            (atx_heading (atx_h4_marker) (inline) @h4)
          QUERY
          Block::PARAGRAPH => "(section (paragraph (inline) @paragraph))\n",
          Block::ITEM => <<~QUERY,
            (section (list (list_item (paragraph (inline) @item))))
            (section (list (list_item (list (list_item (paragraph (inline) @nested))))))
          QUERY
          Block::CODE => <<~QUERY,
            (section (fenced_code_block) @fence)
            (section (fenced_code_block (info_string (language) @language)))
            (section (fenced_code_block (code_fence_content) @content))
          QUERY
          Block::ROW => <<~QUERY
            (pipe_table_row) @row
            (pipe_table_row (pipe_table_cell) @cell)
          QUERY
        }

        # What a capture is a block of, and how deep it sits. A heading's level
        # and a list item's depth are one number because they are one question,
        # and the grammar spells each of them as a kind of its own.
        OF = {
          "h1" => Block::HEADING, "h2" => Block::HEADING,
          "h3" => Block::HEADING, "h4" => Block::HEADING,
          "paragraph" => Block::PARAGRAPH,
          "item" => Block::ITEM, "nested" => Block::ITEM
        }
        DEEP = {
          "h1" => 1, "h2" => 2, "h3" => 3, "h4" => 4,
          "paragraph" => 0, "item" => 1, "nested" => 2
        }

        # The captures a fence and a row are assembled from, which are the ones
        # that are not a block of their own.
        FENCE = "fence"
        LANGUAGE = "language"
        CONTENT = "content"
        ROW = "row"
        CELL = "cell"

        # Every run of text a document marked as taken letter for letter, asked
        # of the text a block-level node holds unparsed. That text is the whole
        # of what the inline grammar is carried for.
        SPANS = "(code_span) @taken"

        MARK = "`"

        def initialize(grammar)
          @grammar = grammar
        end

        def reads?(path)
          "#{path}".end_with?(SUFFIX)
        end

        # The blocks each of these files is made of, in the kinds asked for.
        def blocks(paths, kinds)
          asked = PATTERNS.keys.select { |kind| kinds.include?(kind) }
          query = asked.map { |kind| PATTERNS[kind] }.join
          reading = {}
          paths.each { |path| reading[path] = captured(query, path) }
          spanned = spans_in(reading, paths)

          answered = {}
          paths.each { |path| answered[path] = built(reading[path], spanned) }
          answered
        end

        private

        # Every run taken letter for letter, held under the text it was found in.
        # One text answers once however many documents wrote it, which is also
        # what keeps the second grammar to a single question.
        def spans_in(reading, paths)
          spanned = {}
          paths.each { |path| spanning(reading[path], path, spanned) }
          spanned
        end

        def spanning(captures, path, spanned)
          captures.each do |capture|
            next if OF[capture.name].nil?

            said = folded(capture.text)
            spanned[said] = spans_of(said, path) if spanned[said].nil?
          end
        end

        def spans_of(said, path)
          found = @grammar.captures_of(INLINE, said, SPANS, Place.file(path))
          found.map { |capture| Span.new(taken_from(capture.text), capture.start, capture.finish) }
        end

        # What the marks hold, which is the word itself. They are a run of the
        # same length at each end, and what stands between them is taken as it
        # stands: a word padded with a space either side reads the same to
        # everyone else, and is a way nobody writes one here.
        def taken_from(letters)
          marks = 0
          while letters[marks] == MARK
            marks = marks + 1
          end
          letters[marks..(-1 - marks)]
        end

        # The blocks these captures make. A fence and a row are each closed by
        # the first capture that is not one of their own parts, and by the
        # document ending — the one close nothing in the run announces.
        def built(captures, spanned)
          found = []
          holding = nil
          captures.each do |capture|
            holding = closed(found, holding, capture.name)
            holding = opened(found, holding, capture, spanned)
          end
          found.push(holding) unless holding.nil?
          found
        end

        # Whatever was being assembled, where this capture is no part of it.
        def closed(found, holding, name)
          return holding if holding.nil?
          return holding if holding.kind == Block::CODE && (name == LANGUAGE || name == CONTENT)
          return holding if holding.kind == Block::ROW && name == CELL

          found.push(holding)
          nil
        end

        # This capture, either onto what is being assembled or as a block of its
        # own. A block nothing else is part of is finished the moment it is made.
        def opened(found, holding, capture, spanned)
          case capture.name
          when FENCE then return Block.new(Block::CODE, 0, capture.line, "", nil, [], [])
          when ROW then return Block.new(Block::ROW, 0, capture.line, "", nil, [], [])
          when LANGUAGE then holding.language = capture.text.strip unless holding.nil?
          when CONTENT then holding.text = capture.text unless holding.nil?
          when CELL then holding.cells.push(cell(capture)) unless holding.nil?
          else found.push(spoken(capture, spanned))
          end
          holding
        end

        def cell(capture)
          Block.new(Block::CELL, 0, capture.line, capture.text, nil, [], [])
        end

        # One block of text a reader wrote, with the runs it marked as taken
        # letter for letter.
        def spoken(capture, spanned)
          said = folded(capture.text)
          Block.new(OF[capture.name], DEEP[capture.name], capture.line, said, nil, spanned[said], [])
        end

        # A soft line break is a space, which is what lets a paragraph be wrapped
        # for a reader without the wrapping reaching what it says. The runs are
        # read from the folded text, so what a span points into and what a form
        # reads are one string.
        def folded(said)
          said.split("\n").map { |line| line.strip }.join(" ")
        end

        # Every byte sequence is a legal document, so the grammar refuses
        # nothing: what a specification written wrong loses is the shape the
        # query matches, and saying so is a form's rather than the grammar's.
        def captured(query, path)
          file = Pathname.new(path)
          raise Unreadable, "#{Place.file(file)} is not there to read" unless file.exist?

          @grammar.captures_in(GRAMMAR, file, query, Place.file(file))
        end
      end
    end
  end
end
