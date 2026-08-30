require "sumitsubo/source"

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

        def comments_in(path, where)
          found = []
          line = 0
          path.readlines.each do |text|
            line += 1
            found.push(Source::Region.new(line, text))
          end
          found
        end

        # Prose has no code for a comment to sit in front of, so nothing here
        # claims anything.
        def attached_comments_in(path, where)
          []
        end
      end
    end
  end
end
