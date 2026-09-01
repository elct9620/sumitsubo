require "sumitsubo/error"
require "sumitsubo/specification"
require "sumitsubo/specification/builder"
require "sumitsubo/specification/block"

module Sumitsubo
  class Specification
    module Builder
      # The interfaces a definition registers, built out of the blocks a document
      # is made of.
      #
      # A definition is read one of two ways and they are exclusive: with the
      # reserved heading naming a marker, source claims its contracts in a
      # comment and every fenced block in the document is prose; without it,
      # source declares them outright and the fenced block under each contract is
      # the signature. That heading is the only thing telling the two apart, so it
      # is written before the first contract or refused — a walk reaching a fence
      # has to know already.
      #
      # The language is the fenced block's own rather than the document's, which
      # is what lets one definition register contracts in two languages. What the
      # signature says is carried as it was written: how a shape is compared
      # against the source is the mechanism's, and this is where that text comes
      # from.
      class Contract
        KINDS = [Block::HEADING, Block::PARAGRAPH,
                 Block::ITEM, Block::CODE, Block::ROW]

        # The levels this form is written at: a name, and a heading that either
        # scopes the definition, names the marker, or declares a contract.
        NAME = 1
        REGISTERS = 2

        # A glob is written at the depth a list opens at.
        GLOB = 1

        # The heading naming the word source claims these contracts with.
        MARKER = "Marker"

        # The attributes a contract carries, each with the one value it takes.
        # A closed set both ways: a word this does not know is a form nobody
        # reads, and a value nothing answers for is a fact nobody keeps.
        ATTRIBUTES = { "internal" => "yes" }

        # What the fence says about a contract, held under the words the
        # mechanism words its own help with. Neither is an attribute a row may
        # write: a value said in two places is a specification saying one thing
        # twice.
        LANGUAGE = "language"
        SIGNATURE = "signature"

        # The topic a refusal from this form sends a reader to.
        TOPIC = "contract"

        # What stands between a scope and what it holds. Every language spelling
        # a nested name uses one of them, and which means what is that language's
        # own — all this asks is whether a name ended where another began, so that
        # a scope sharing a prefix with the contract is not read as holding it.
        SEPARATORS = [":", ".", "#"]

        # The same separators as the bytes they are. A name may be written in
        # characters a byte offset and a character index disagree about, and as
        # of 2026-09-01 this compiler answers `String#length` by the byte where
        # it could not narrow the receiver to `String`, which is what the name
        # reaching here is given. Mixing the two is only safe in bytes, and
        # `T-042` holds that.
        #
        # When it answers characters again, this constant goes and `encloses?`
        # asks `SEPARATORS.include?(key[name.length])` instead.
        SEPARATOR_BYTES = SEPARATORS.map { |one| one.getbyte(0) }

        def initialize(path, source)
          @path = path
          @source = source
          @key = nil
          @text = nil
          @marker = nil
          @marker_at = nil
          @includes = []
          @contracts = []
          @contract = nil
          @holding = nil
        end

        def build(blocks)
          blocks.each { |block| arrived(block) }

          refuse(1, "declares no name") if @key.nil?
          refuse(@marker_at, "names #{MARKER} and gives no word to claim with") if @marker.nil? && !@marker_at.nil?
          @contracts.each { |contract| declared(contract) }

          Specification.new(@key, @text, @includes, @path, attributes, @contracts)
        end

        private

        def arrived(block)
          case block.kind
          when Block::HEADING then heading(block)
          when Block::PARAGRAPH then described(block)
          when Block::ITEM then item(block)
          when Block::CODE then signed(block)
          when Block::ROW then attributed(block)
          end
        end

        def heading(block)
          return named(block) if block.level == NAME
          return unless block.level == REGISTERS

          registers(block)
        end

        # A definition is named once, and a file naming two says which of them it
        # is nowhere.
        def named(block)
          refuse(block.line, "declares a second name") unless @key.nil?

          @key = block.text
        end

        # The reserved headings, or a contract. Which arrived is what the blocks
        # after it are read as: a list under one spells includes, a paragraph
        # under another names the marker, and a paragraph under a contract says
        # what it is for.
        def registers(block)
          said = block.text
          @contract = nil
          @holding = nil

          return @holding = INCLUDES if said == INCLUDES
          return marking(block.line) if said == MARKER

          @contract = registered(block)
          @contracts.push(@contract)
        end

        def marking(line)
          refuse(line, "names #{MARKER} twice") unless @marker_at.nil?
          refuse(line, "names #{MARKER} after a contract, which is read one way or the other") unless @contracts.empty?

          @marker_at = line
          @holding = MARKER
        end

        # A contract's name is what a claim in the source names, so it is taken
        # letter for letter, and the heading carries it alone: a description is
        # a paragraph, an attribute is a row, and neither is written where a
        # reader is reading a name.
        def registered(block)
          name = block.taken
          if name.nil? || name.empty?
            refuse(block.line, "declares a contract whose heading does not open with a name in backticks")
          end

          said = block.rest
          refuse(block.line, "writes #{said} after a name, where a heading carries the name alone") unless said.empty?

          Statement.new(name, nil, [], @path, block.line, {}, [])
        end

        # The marker, the definition's own description, or a contract's. Only the
        # first paragraph under each says what it declares; a second is prose.
        def described(block)
          return marked(block) if @holding == MARKER
          return unless @holding.nil?

          return @contract.text = block.text if !@contract.nil? && @contract.text.nil?
          return unless @contract.nil?

          @text = block.text if @text.nil? && @contracts.empty?
        end

        # The word source claims with is consumed letter for letter, so it is
        # taken that way like every other such word.
        def marked(block)
          return unless @marker.nil?

          claimed = block.taken
          refuse(block.line, "names a marker that is not a word in backticks") if claimed.nil?

          @marker = claimed
        end

        def item(block)
          return unless @holding == INCLUDES && block.level == GLOB

          @includes.push(Builder.scoped(block, @path, TOPIC))
        end

        # The cells of one row, held as the attribute they state. A row states
        # an attribute of the contract it sits under, so one standing above the
        # first is an attribute of nothing rather than of the document.
        def attributed(block)
          cells = block.cells
          return if cells.empty?

          line = cells[0].line
          refuse(line, "writes an attribute outside any contract") if @contract.nil?
          unless cells.length == 2
            refuse(line, "writes an attribute row of #{cells.length} #{cells.length == 1 ? "cell" : "cells"} rather than two")
          end

          carried(line, cells[0].text.strip, cells[1].text.strip)
        end

        # One attribute as the row wrote it, once the closed set has answered
        # for both halves. An attribute written twice says which of them it is
        # nowhere, the way a second name does.
        def carried(line, said, value)
          takes = ATTRIBUTES[said]
          refuse(line, "writes #{said}, which is not an attribute a contract carries") if takes.nil?
          refuse(line, "writes #{said} as #{value}, where it takes #{takes}") unless value == takes
          refuse(line, "writes #{said} twice") unless @contract.attributes[said].nil?

          @contract.attributes[said] = [value]
        end

        # A fenced block taken as the signature of the contract it sits under. A
        # marker reading has no signature to take, so every fence in such a
        # document is prose; so is a second one under one contract, and so is one
        # written before any contract.
        def signed(block)
          return unless @marker_at.nil?
          return if @contract.nil? || !@contract.attributes[SIGNATURE].nil?

          if block.language.nil?
            refuse(block.line, "writes a signature with no language, which is what says how #{@contract.key} is spelled")
          end

          @contract.attributes[LANGUAGE] = [block.language]
          @contract.attributes[SIGNATURE] = [block.text]
        end

        # What every contract has to answer once the document is read. The marker
        # reading asks nothing of a name — a claim is a claim in whatever the file
        # is written in — so this is the other one's alone.
        def declared(contract)
          return unless @marker.nil?

          named = contract.attributes[LANGUAGE]
          if named.nil?
            refuse(contract.line, "registers #{contract.key} with no signature, so nothing says how its name is spelled")
          end

          language = named[0]
          refuse(contract.line, "names #{language}, which this sumi does not carry") unless @source.carries?(language)
          registering(contract, language)
        end

        # The signature read as the language it names. Asking the reading rather
        # than the spelling of the name is what makes the two sides one: what a
        # contract can register is what that reading finds.
        #
        # What comes back is thrown away. The shape is read again when the two
        # sides are compared, because a value derived here would be a second
        # place the specification says something.
        def registering(contract, language)
          found = declarations_of(contract, language)
          holding = found.reject { |name| name.name == contract.key }
          # Nothing was taken out, so nothing declared what the heading names.
          if holding.length == found.length
            refuse(contract.line, "writes a signature declaring #{spelled(found)}, and not #{contract.key}")
          end

          holding.each do |name|
            next if name.shape.nil? && encloses?(name.name, contract.key)

            refuse(contract.line, "writes a signature declaring #{name.name} as well, " \
                                  "where a signature declares the one contract and what holds it")
          end
        end

        def declarations_of(contract, language)
          @source.declarations_of(contract.attributes[SIGNATURE][0], @path, language)
        rescue Sumitsubo::Error
          # Named rather than passed on: the reading's message is about a piece
          # of source, and what a reader has is a specification. Caught as the
          # error every reading answers with, so nothing here reaches for the one
          # that names a grammar.
          refuse(contract.line, "writes a signature the #{language} reading cannot read")
        end

        # Whether a declaration is one of the scopes the contract's own name is
        # written inside. A signature carries the nesting because that is what
        # makes the name what it is, so the scopes are declarations too and
        # registering none of them.
        def encloses?(name, key)
          key.start_with?(name) && SEPARATOR_BYTES.include?(key.getbyte(name.bytesize))
        end

        def spelled(found)
          return "nothing" if found.empty?

          found.map { |name| name.name }.join(", ")
        end

        def attributes
          found = {}
          found["marker"] = [@marker] unless @marker.nil?
          found
        end

        def refuse(line, said)
          Builder.refuse(@path, line, said, TOPIC)
        end
      end
    end
  end
end
