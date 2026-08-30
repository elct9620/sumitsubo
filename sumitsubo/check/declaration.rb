require "sumitsubo/check"
require "sumitsubo/finding"

module Sumitsubo
  module Check
    # What the syntax tree answers is compared against. Every declaration
    # arriving here answers `name`, `shape` and `place`, and is held under the
    # name a specification would register it by.
    module Declaration
      # What a caller would have to write. A scope has no call to describe at
      # all, which is not the same as a method taking nothing.
      def self.spelled(shape)
        shape.nil? ? "nothing" : shape.spoken
      end

      # Whether every declaration of one name describes the same call. What a
      # reading answers is a value, so two shapes asking a caller for the same
      # thing are the same shape — a scope carrying none at all agrees with
      # itself, and one taking none does not agree with it.
      def self.agreed?(group)
        shape = group[0].shape
        group.all? { |declared| declared.shape == shape }
      end

      # Each of a group answers once, naming the next one round, so two of them
      # read as two lines pointing at each other rather than as every pairing
      # of the places involved.
      def self.paired(group)
        group.zip(group.rotate)
      end

      # An interface the syntax tree does not define. The specification
      # registers it and no source it reaches defines it, which is the same
      # difference an unclaimed interface is — the other reading of it.
      class Undefined
        def initialize(rule)
          @rule = rule
        end

        def run(stated, grouped)
          found = []
          stated.each do |one|
            next unless grouped[one.key].nil?

            # The caveat rides every one of these because the tree cannot tell
            # two cases apart: a definition a macro or a mixin brings into
            # being is missing from it exactly as an unwritten one is, and
            # rewriting that one fixes nothing. Which constructs those are is
            # each language's own, so this names the shape and
            # `sumi help contract` names them.
            found.push(Finding.new(
              rule: @rule, difference: true, place: one.place,
              message: "#{one.said} is defined nowhere this specification " \
                       "includes, and one the reading cannot see never is"
            ))
          end
          found
        end
      end

      # A registered name defined twice with two shapes. A language that lets a
      # type be reopened or implemented in pieces says nothing while only the
      # name is compared: the name is the way in, and there was one of them. A
      # shape is part of the way in, so two shapes are an entrance the
      # specification does not describe.
      #
      # Definitions agreeing on their shape are one way in, which is what
      # leaves ordinary reopening saying nothing still.
      class Conflicting
        def initialize(rule)
          @rule = rule
        end

        def run(names, grouped)
          found = []
          names.each do |name|
            group = grouped[name]
            next if group.nil? || group.length < 2 || Declaration.agreed?(group)

            Declaration.paired(group).each do |pair|
              found.push(Finding.new(
                rule: @rule, difference: true, place: pair[0].place,
                message: "#{pair[0].name} takes #{Declaration.spelled(pair[0].shape)} here and " \
                         "#{Declaration.spelled(pair[1].shape)} at #{pair[1].place.spoken}"
              ))
            end
          end
          found
        end
      end

      # An interface defined with a shape other than the one registered. Where
      # the definitions disagree among themselves that is already answered, and
      # comparing the contract against one of them would add nothing.
      class Mismatched
        def initialize(rule)
          @rule = rule
        end

        def run(registered, grouped)
          found = []
          registered.each do |one|
            group = grouped[one.key]
            next if group.nil? || !Declaration.agreed?(group)
            next if one.shape == group[0].shape

            # Both shapes are said, because what a reader chooses between is
            # the two of them; the name is spelled alone, since the reading
            # this comes from shows no word in front of it.
            found.push(Finding.new(
              rule: @rule, difference: true, place: one.place,
              message: "#{one.said} takes #{Declaration.spelled(group[0].shape)} " \
                       "where the specification registers #{Declaration.spelled(one.shape)}"
            ))
          end
          found
        end
      end
    end
  end
end
