require "pathname"
require "sumitsubo/error"
require "sumitsubo/parser/markdown/format"
require "sumitsubo/parser/markdown/feature"
require "sumitsubo/parser/markdown/vocabulary"
require "sumitsubo/where"

module Sumitsubo
  module Parser
    # A specification as Markdown, which is the document a person reads as well
    # as the reference line the tool compares against.
    #
    # The grammar is handed in rather than reached for, the way a language is,
    # so nothing here opens the binding: what a build carries decides which
    # grammar answers, and this file can be read — and its test regenerated —
    # without one.
    #
    # What is here is the format and the seam: the one place a document becomes
    # blocks. What a project declares is each reading's, one for every kind of
    # specification, because the three answer different questions and no caller
    # ever chooses between them.
    class Markdown
      # The extension is the whole of what says a file is written this way. A
      # specification is named by the project rather than found by its content,
      # so nothing here opens the file to decide.
      SUFFIX = ".md"

      # The grammar the query is written against. Node names are that grammar's
      # own and no two spell one alike, so the query and the name travel
      # together rather than the name arriving from outside.
      GRAMMAR = "markdown"

      def initialize(grammar)
        @grammar = grammar
      end

      def reads?(path)
        "#{path}".end_with?(SUFFIX)
      end

      def behavior(path)
        Feature.new(path).read(blocks_in(path))
      end

      def glossary(path)
        file = Pathname.new(path)
        where = Where.of(file)
        raise Unreadable, "no glossary at #{where}; sumi init lays one down" unless file.exist?

        Vocabulary.new(path, where).read(blocks_in(path))
      end

      # The line each include is written on. The reserved heading says which
      # list items are includes, the same as the reading does; what a finding
      # wants of them is the line rather than the glob. Asked only once one of
      # them turned out to cover nothing, so a document whose includes all
      # reach a file is never read a second time.
      def spelled_in(path)
        found = {}
        scoping = false
        blocks_in(path).each do |capture|
          said = Format.folded(capture.text)
          scoping = said == Format::INCLUDES if capture.name == Format::H2
          next unless capture.name == Format::ITEM && scoping

          # The document was read before this is asked, so an item under the
          # reserved heading is a code span already: one that is not was
          # refused by the reading, and there is no second refusal to make
          # here — nor a topic to name it under, since this is asked of every
          # kind of specification alike.
          glob = Format.code_span(said)
          found[glob[0]] = capture.line if !glob.nil? && found[glob[0]].nil?
        end
        found
      end

      private

      # Every byte sequence is a legal document, so the grammar refuses
      # nothing: what a specification written wrong loses is the shape the
      # query matches, and saying so is a reading's rather than the grammar's.
      def blocks_in(path)
        file = Pathname.new(path)
        @grammar.captures_in(GRAMMAR, file, Format::QUERY, Where.of(file))
      end
    end
  end
end
