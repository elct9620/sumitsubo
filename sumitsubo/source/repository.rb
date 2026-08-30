require "sumitsubo/place"
require "sumitsubo/source"
require "sumitsubo/source/marker"

module Sumitsubo
  module Source
    # Everything a run read out of the source, and the one place any of it is
    # read from. Which language answers for a file is the languages' to say, so
    # this names none: it holds the seam and asks it the three questions a
    # comparison has of source.
    #
    # A path arrives composed and answers rendered, because what a reading
    # hands back is what a finding points at.
    class Repository
      def initialize(languages)
        @languages = languages
      end

      # What a person wrote for another person in this file.
      def comments(path)
        @languages.comments_in(path, Place.file(path))
      end

      # What these files claim with any of these words, read in one pass per
      # file: parsing is the cost, so a project registering several kinds still
      # reads each of them once.
      def claims(paths, keywords)
        found = []
        paths.each do |path|
          Marker.claims_in(path, keywords, @languages).each { |one| found.push(one) }
        end
        found
      end

      # What a file declares, read as the language a specification named.
      def declarations(path, language)
        @languages.declarations_in(path, Place.file(path), language)
      end

      # The same reading of a piece of text nobody wrote to a file, which is
      # what lets a specification register the shape it means by writing the
      # declaration out.
      def declarations_of(said, where, language)
        @languages.declarations_of(said, where, language)
      end

      # Whether this build reads the language a specification named.
      def carries?(language)
        @languages.carries?(language)
      end
    end
  end
end
