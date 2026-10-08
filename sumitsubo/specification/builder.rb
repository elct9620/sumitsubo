require "sumitsubo/error"
require "sumitsubo/place"
require "sumitsubo/specification"
require "sumitsubo/specification/block"

module Sumitsubo
  class Specification
    # How the blocks a document is made of become the shapes a mechanism judges
    # against. One builder builds one document, so what a walk is in the middle
    # of is held on it rather than threaded through every method that needs it.
    #
    # Nothing here names a format. A form says which kinds of block it reads
    # and what each one means for itself, which is why a level that states a
    # term in one form is prose in another.
    module Builder
      # The one heading every kind of specification spells alike, since every
      # one of them says what it answers for. Every form knows it by the prose
      # a heading carries and by nothing else, which is why it is written here
      # as the text itself rather than the name a heading is read for.
      INCLUDES = "Includes"

      # One glob, as whatever wrote it will hold it. A boundary is written the
      # same way at every depth, and the line goes with it because a glob
      # covering nothing answers where a reader goes to fix it.
      #
      # Answered rather than pushed into the includes handed over, which are
      # asked only whether this glob is among them: what a specification
      # reaches is a set, and which array a statement joins is for the builder
      # holding it to decide.
      def self.scoped(block, path, topic, held)
        glob = block.taken
        refuse(path, block.line, "writes an include that is not a glob in backticks", topic) if glob.nil?

        first = held.find { |one| one.key == glob }
        refuse(path, block.line, "writes #{glob} a second time, #{first_written(path, first.line)}", topic) unless first.nil?

        Statement.new(glob, nil, [], path, block.line, {}, [])
      end

      # The reserved heading written again where it was already written once.
      # Gathered rather than raised: the globs under it are still globs, and
      # each is asked about on its own.
      def self.rescoped(path, line, first, topic)
        refusal(path, line, "writes #{INCLUDES} a second time, #{first_written(path, first)}", topic)
      end

      def self.first_written(path, line)
        "first written at #{Place.of(path, line).spoken}"
      end

      # What a block is called when it is written where only globs stand.
      WRITTEN = { Block::HEADING => "a heading", Block::PARAGRAPH => "a paragraph",
                  Block::ITEM => "a nested item", Block::CODE => "a fenced block",
                  Block::ROW => "a table row" }

      # Anything written beside the globs. What a specification reaches is a
      # set, so the heading holding it holds nothing a reader could take for
      # part of it, and a note on one glob is written after it on its line.
      def self.beside(block, path, topic)
        refuse(path, block.line, "writes #{WRITTEN[block.kind]} under #{INCLUDES}, which holds its globs alone", topic)
      end

      # A refusal names the topic that has the form it was written against,
      # because one syntax carries three of them and a reader sent to the wrong
      # one is sent nowhere.
      #
      # Worded once for the two ways a form reaches for one: raised where what
      # comes after it leans on what was refused, and gathered where it does
      # not. A document answers for every way it is out of shape, so the walk
      # goes on either way and the raise reaches no further than the block it
      # was made about.
      def self.refusal(path, line, said, topic)
        Refusal.new(Place.of(path, line), "#{said}; sumi help #{topic} has the form")
      end

      def self.refuse(path, line, said, topic)
        raise Misshapen.new([refusal(path, line, said, topic)])
      end

      # How wide a row turned out to be, said the way both forms say it. A row
      # of any width but two is a separator lost or an unescaped one gained, and
      # only the second is something a person can be told what to do about: what
      # they meant as one cell was read as two, and the tool cannot tell that
      # from a row they meant to write wide.
      def self.width_of(count)
        said = "of #{count} #{count == 1 ? "cell" : "cells"} rather than two"
        return said if count < 2

        "#{said}, where a | inside a cell is written \\|"
      end

      # What an attribute takes in place of a fixed value when it says why.
      #
      # Held in one table where a pair is meant — the fixed values and the
      # reasoned words as two sets: under Spinel 2026.09.12 a scenario's empty
      # set of fixed values leaves `key?` on the shared parameter without the
      # other form's arm, and the run crashes. Spinel c1d108a has the arm.
      REASON = "a reason"

      # What an attribute takes when it names other statements: their keys,
      # each in backticks, set apart by commas. A key is taken letter for
      # letter, so one carrying a space or a comma is still one key.
      KEYS = "keys in backticks"

      # One attribute as a row wrote it, held under the word its first cell
      # names. The set is closed both ways: a word nothing knows is a form
      # nobody reads, and a fixed value nothing answers for is a fact nobody
      # keeps. An attribute taking a reason with nothing in its second cell
      # says nothing at all.
      #
      # An attribute written twice says which of them it is nowhere, the way a
      # second name does.
      def self.carried(attributes, takes, row, carries, path, topic)
        line = row.line
        said = row.said
        value = row.value
        taken = takes[said]
        refuse(path, line, "writes #{said}, which is not #{carries}", topic) if taken.nil?
        held = [value]
        if taken == REASON
          refuse(path, line, "writes #{said} with no reason", topic) if value.empty?
        elsif taken == KEYS
          refuse(path, line, "writes #{said} naming nothing", topic) if value.empty?
          held = keys_in(value)
          refuse(path, line, "writes #{said} as #{value}, where it takes #{taken}", topic) if held.empty?
        elsif value != taken
          refuse(path, line, "writes #{said} as #{value}, where it takes #{taken}", topic)
        end
        refuse(path, line, "writes #{said} twice", topic) unless attributes[said].nil?

        attributes[said] = held
      end

      # The keys a cell names, or none where any part of it is not one key in
      # backticks: a cell half read would name less than its writer meant.
      def self.keys_in(value)
        found = []
        # Interpolated first: in this program Spinel 2026.09.12 splits the boxed
        # cell text into an array it then reads as C strings, and C refuses it.
        # Master 0e8befeb compiles `value.split`.
        parts = "#{value}".split(",").map { |one| one.strip }
        parts.each do |part|
          return [] unless part.length > 2 && part.start_with?("`") && part.end_with?("`")

          found.push(part[1, part.length - 2])
        end
        found
      end

      # A row of two cells, as the first names it and the second says it.
      Row = Data.define(:line, :said, :value)

      def self.empty_to_nil(said)
        said.empty? ? nil : said
      end
    end
  end
end
