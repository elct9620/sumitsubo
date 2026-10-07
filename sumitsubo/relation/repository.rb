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

      def add(relation)
        @all.push(relation)
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

      # Every claim naming a statement this mechanism keeps.
      def claims_of(mechanism)
        found = []
        @all.each do |one|
          next unless one.kind == CLAIM && one.object.mechanism == mechanism

          found.push(one)
        end
        found
      end
    end
  end
end
