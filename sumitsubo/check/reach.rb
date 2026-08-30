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
      # Where the include was written is asked of the parser that read the
      # specification, since only that one knows how its format spells a glob.
      class Barren
        def initialize(rule)
          @rule = rule
        end

        def run(covers, base, exclusion, specifications)
          found = []
          covers.each do |cover|
            empty = Source::Scope.barren(base, cover.patterns, exclusion)
            next if empty.empty?

            spelled = specifications.spelling(cover.path)
            empty.each do |pattern|
              found.push(Source::Scope.barren_at(@rule, cover.path, pattern, spelled[pattern]))
            end
          end
          found
        end
      end
    end
  end
end
