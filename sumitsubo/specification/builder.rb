require "sumitsubo/error"
require "sumitsubo/place"
require "sumitsubo/specification"

module Sumitsubo
  class Specification
    # How the blocks a document is made of become the shapes a mechanism judges
    # against. One builder builds one document, so what a walk is in the middle
    # of is held on it rather than threaded through every method that needs it.
    #
    # Nothing here names a format. A form says which kinds of block it is
    # written in and reads what each one means for itself, which is why a level
    # that states a term in one form is prose in another.
    module Builder
      # The one heading every kind of specification spells alike, since every
      # one of them says what it answers for. It is prose, so a scenario or a
      # contract of the same name is written as a run taken letter for letter
      # and does not collide with it; a term is prose too, which is what a
      # vocabulary gives up to have it.
      INCLUDES = "Includes"

      # One glob, as whatever wrote it will hold it. A boundary is written the
      # same way at every depth, and the line goes with it because a glob
      # covering nothing answers where a reader goes to fix it.
      #
      # Answered rather than pushed into an array handed over. A module function
      # that pushes into its array parameter raises at run time in this compiler
      # once one caller reaches it with an instance variable — measured in
      # `tmp/2026-08-30-module-function-array-parameter.md`, and to be undone
      # when that is fixed. Answering is the better shape either way, so what
      # goes when the defect does is this note rather than the code.
      def self.scoped(block, path, topic)
        glob = block.taken
        refuse(path, block.line, "writes an include that is not a glob in backticks", topic) if glob.nil?

        Statement.new(glob, nil, [], path, block.line, {}, [])
      end

      # A refusal names the topic that has the form it was written against,
      # because one syntax carries three of them and a reader sent to the wrong
      # one is sent nowhere.
      def self.refuse(path, line, said, topic)
        raise Unreadable, "#{Place.of(path, line).spoken} #{said}; sumi help #{topic} has the form"
      end

      def self.empty_to_nil(said)
        said.empty? ? nil : said
      end
    end
  end
end
