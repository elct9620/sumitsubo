require "pathname"
require "sumitsubo/error"
require "sumitsubo/specification/parser/markdown/builder/definition"
require "sumitsubo/specification/parser/markdown/builder/feature"
require "sumitsubo/specification/parser/markdown/builder/vocabulary"
require "sumitsubo/specification/parser/markdown/format"
require "sumitsubo/place"
require "sumitsubo/specification"

module Sumitsubo
  class Specification
    module Parser
      # A specification as Markdown, which is the document a person reads as well
      # as the reference line the tool compares against.
      #
      # The grammar is handed in rather than reached for, the way a language is,
      # so nothing here opens the binding: what a build carries decides which
      # grammar answers, and this file can be read — and its test regenerated —
      # without one.
      #
      # This is the seam and nothing else: it hands a builder's query to the
      # grammar and hands the captures back to that builder. Which blocks a
      # question is answered from is the builder's, because a feature and a
      # vocabulary are two forms sharing one syntax; what a block means is the
      # builder's for the same reason.
      class Markdown
        # The extension is the whole of what says a file is written this way. A
        # specification is named by the project rather than found by its content,
        # so nothing here opens the file to decide.
        SUFFIX = ".md"

        # The grammar every query here is written against. Node names are that
        # grammar's own and no two spell one alike, so the name travels with the
        # queries rather than arriving from outside.
        GRAMMAR = "markdown"

        def initialize(grammar)
          @grammar = grammar
        end

        def reads?(path)
          "#{path}".end_with?(SUFFIX)
        end

        def behavior(path)
          built(Builder::Feature.new(path), path)
        end

        def glossary(path)
          file = Pathname.new(path)
          where = Place.file(file)
          raise Unreadable, "no glossary at #{where}; sumi init lays one down" unless file.exist?

          built(Builder::Vocabulary.new(path, where), path)
        end

        # The languages arrive from outside the way they do for the other format:
        # a contract read from the syntax tree says which language spells its
        # name, and whether this build carries that one is not the format's to
        # know.
        def contract(path, source)
          built(Builder::Definition.new(path, source), path)
        end

        # The line each include is written on. Every kind of specification lists
        # them under the reserved heading and they differ only in which level
        # that heading sits at, so this is asked of a document without being told
        # which kind it is.
        #
        # Asked only once one of them turned out to cover nothing, so a document
        # whose includes all reach a file is never read a second time.
        def spelled_in(path)
          found = {}
          scoping = false
          captured(Format::SPELLED, path).each do |capture|
            said = Format.folded(capture.text)
            scoping = said == Format::INCLUDES unless capture.name == Format::ITEM
            next unless capture.name == Format::ITEM && scoping

            # The document was built before this is asked, so an item under the
            # reserved heading is a code span already: one that is not was
            # refused then, and there is no topic to name a second refusal under.
            glob = Format.code_span(said)
            found[glob.taken] = capture.line if !glob.nil? && found[glob.taken].nil?
          end
          found
        end

        private

        def built(builder, path)
          builder.build(captured(builder.query, path))
        end

        # Every byte sequence is a legal document, so the grammar refuses
        # nothing: what a specification written wrong loses is the shape the
        # query matches, and saying so is a builder's rather than the grammar's.
        def captured(query, path)
          file = Pathname.new(path)
          @grammar.captures_in(GRAMMAR, file, query, Place.file(file))
        end
      end
    end
  end
end
