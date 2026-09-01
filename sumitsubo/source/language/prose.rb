require "sumitsubo/source"
require "sumitsubo/source/language/nodes"

module Sumitsubo
  module Source
    module Language
      # Whatever no language before it claimed. Prose is a comment for its whole
      # length, so the file answers entire and nothing has to be found in it.
      #
      # Reached through `language.rb`, which holds the seam and the shapes a
      # reading answers with, so nothing here requires its way back up.
      class Prose
        # Prose is what a file falls to rather than something a specification
        # names, so it answers to no name and declares nothing: a specification
        # asking for what a file declares has said which language it means.
        def named?(name)
          false
        end

        def reads?(path)
          true
        end

        # Prose has no code for a comment to sit in front of, so every line
        # stands in front of more of the same and the last in front of nothing.
        # Saying so is what puts a claim written here on the same footing as one
        # written at the end of a source file, rather than out of sight.
        def comments_in(path, where)
          said = path.readlines
          found = []
          line = 0
          said.each do |text|
            line += 1
            found.push(Source::Region.new(
              line, text, line == said.length ? Source::Region::NOTHING : Source::Region::COMMENT
            ))
          end
          found
        end
      end
    end
  end
end
