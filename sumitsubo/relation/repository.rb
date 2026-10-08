require "sumitsubo/relation"

module Sumitsubo
  class Relation
    # Every relation a run found, in the order it was found: a mechanism puts
    # them here as it reads, and whoever asks afterwards reads them back without
    # reading the source again.
    class Repository
      def initialize
        @all = []
      end

      # Answers the relation rather than the list: Spinel master at e527d205d
      # gives the list two array types in a whole program and refuses it, where
      # the 2026.09.12 release accepts either.
      def add(relation)
        @all.push(relation)
        relation
      end

      # The files a specification reaches, in the order it reached them.
      def reached_from(path)
        found = []
        @all.each do |one|
          next unless one.kind == REACH && one.subject.path == path

          found.push(one.object.path)
        end
        found
      end

      # Every relation of this kind, in the order it was kept.
      def of(kind)
        @all.select { |one| one.kind == kind }
      end

      # Every relation of this kind naming a statement this mechanism keeps.
      def naming(kind, mechanism)
        found = []
        @all.each do |one|
          next unless one.kind == kind && one.object.mechanism == mechanism

          found.push(one)
        end
        found
      end
    end
  end
end
