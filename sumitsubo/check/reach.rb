require "sumitsubo/check"
require "sumitsubo/source/scope"

module Sumitsubo
  module Check
    # What the walk answers about a specification's own includes, before any
    # source is compared against it.
    module Reach
      # An include covering no file. Its statements are then compared against
      # nothing, and every one of them answers as claimed nowhere — which is
      # why saying so is worth a finding of its own.
      #
      # The walk is asked about globs and the include carries the line it was
      # written on, so where to answer is known without asking the parser a
      # second time.
      class Barren
        def initialize(rule)
          @rule = rule
        end

        def run(covers, base, exclusion)
          found = []
          covers.each { |cover| found.concat(barren_of(cover, base, exclusion)) }
          found
        end

        private

        # One specification's includes that cover nothing, each answering where
        # it was written. The walk is asked about the globs alone, so the set it
        # answers with is what the includes are read back against.
        def barren_of(cover, base, exclusion)
          globs = cover.includes.map { |one| one.key }
          empty = {}
          Source::Scope.barren(base, globs, exclusion).each { |glob| empty[glob] = true }
          covered = cover.includes.select { |one| empty[one.key] }
          covered.map { |one| Source::Scope.barren_at(@rule, cover.path, one.key, one.line) }
        end
      end
    end
  end
end
