module Sumitsubo
  module Language
    # Whatever no language before it claimed. Prose is a comment for its whole
    # length, so the file answers entire and nothing has to be found in it.
    #
    # Reached through `language.rb`, which holds the seam and the shapes a
    # reading answers with, so nothing here requires its way back up.
    class Prose
      def reads?(path)
        true
      end

      def comments_in(path, where)
        found = []
        line = 0
        path.readlines.each do |text|
          line += 1
          found.push(Region.new(line, text))
        end
        found
      end

      # Prose has no code for a comment to sit in front of, so nothing here
      # claims anything, and it declares nothing either.
      def attached_comments_in(path, where)
        []
      end

      def declarations_in(path, where)
        []
      end
    end
  end
end
