require "sumitsubo/check"
require "sumitsubo/finding"
require "sumitsubo/place"
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

      # A section that writes no glob at all. Its words hold in no file, so
      # every one of them is checked nowhere — the nothing barren answers for,
      # arrived at by naming no pattern rather than by naming one that matches
      # nothing.
      #
      # Only a vocabulary asks this. A feature and a definition answer for
      # their statements one at a time, so one reaching nothing already says so
      # once for every scenario and every contract it declares.
      class Unscoped
        def initialize(rule)
          @rule = rule
        end

        # A section declaring nothing is passed over: it asserts nothing about
        # the code, so a run reaching none of its files has missed nothing.
        def run(sections)
          found = []
          sections.each do |section|
            next unless section.includes.empty?
            next if section.statements.empty?

            found.push(Finding.new(
              rule: @rule, difference: false,
              place: Place.of(section.path, section.line),
              message: "#{section.key} names no include; " \
                       "the words it declares are checked nowhere"
            ))
          end
          found
        end
      end
    end
  end
end
