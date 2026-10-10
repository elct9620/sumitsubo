require "sumitsubo/check"
require "sumitsubo/finding"

module Sumitsubo
  module Check
    # What a marker in the source is compared against. Both sides answer three
    # things — the word they are found by, where they sit, and how they are
    # said to a reader — which is what lets two mechanisms asking one question
    # run one check under one name.
    module Claim
      # The claims within the reach of the specification declaring what they
      # name: each sitting among the files it answers for, which are the only
      # claims that can answer for what it declares. Filtering once is what
      # leaves the checks below unchanged.
      def self.within(claims, declaring, reach)
        found = []
        claims.each do |claim|
          spec = declaring[claim.key]
          next if spec.nil?
          next if reach[spec][claim.place.path].nil?

          found.push(claim)
        end
        found
      end

      # The specification says a thing exists and no claim within its reach
      # does, which is a difference between the two sides.
      class Unclaimed
        def initialize(check)
          @check = check
        end

        # It answers at the specification that declares it, which is also where
        # the include that bounded the search is written, so the message names
        # neither.
        def run(stated, claims)
          made = {}
          claims.each { |claim| made[claim.key] = true }
          found = []
          stated.each do |one|
            next unless one.unverifiable.nil?
            next unless made[one.key].nil?

            found.push(Finding.new(
              check: @check, difference: true, place: one.place,
              message: "#{one.said} is claimed nowhere this specification includes"
            ))
          end
          found
        end
      end

      # The specification says nothing can hold a thing to the source and a
      # claim within its reach does. The reason it was set aside no longer
      # stands, and nothing was compared while it was, so this is a comparison
      # that could not be made rather than a difference.
      #
      # It answers at the specification, where the reason is written, and
      # names the first claim so a reader can see where the source has it.
      class Stale
        def initialize(check)
          @check = check
        end

        def run(stated, claims)
          made = {}
          claims.each { |claim| made[claim.key] = claim if made[claim.key].nil? }
          found = []
          stated.each do |one|
            next if one.unverifiable.nil?

            claim = made[one.key]
            next if claim.nil?

            found.push(Finding.new(
              check: @check, difference: false, place: one.place,
              message: "#{one.said} is unverifiable, yet claimed at #{claim.place.spoken}"
            ))
          end
          found
        end
      end

      # A claim resolving to nothing the specification declares. Nothing on the
      # specification side can confirm it — either the specification is not
      # there to confirm against, or what it named was removed and the claim
      # should have gone with it. Both are comparisons that could not be made
      # rather than differences.
      class Unresolved
        def initialize(check, what)
          @check = check
          @what = what
        end

        def run(claims, stated)
          declared = {}
          stated.each { |one| declared[one.key] = true }
          found = []
          claims.each do |claim|
            next unless declared[claim.key].nil?

            found.push(Finding.new(
              check: @check, difference: false, place: claim.place,
              message: "#{claim.said} resolves to no #{@what}"
            ))
          end
          found
        end
      end

      # A claim with no code under it. Nothing was compared: the marker is
      # about the code below it and there is none, so this is a comparison that
      # could not be made rather than a difference.
      #
      # It answers at the marker rather than at the specification, because the
      # line to fix is the one somebody left hanging.
      class Dangling
        def initialize(check)
          @check = check
        end

        def run(claims)
          claims.map do |claim|
            Finding.new(
              check: @check, difference: false, place: claim.place,
              message: "#{claim.said} stands in front of nothing; a claim needs code below it"
            )
          end
        end
      end

      # A claim carrying nothing after the marker. It names nothing at all,
      # which is a different thing to say than a name that resolves to none.
      class Nameless
        def initialize(check, what)
          @check = check
          @what = what
        end

        def run(claims)
          claims.map do |claim|
            Finding.new(
              check: @check, difference: false, place: claim.place,
              message: "#{claim.said} names no #{@what}"
            )
          end
        end
      end

      # A claim naming something the specification declaring it does not reach.
      # The name resolves, so neither side is wrong about the thing; what could
      # not be made is the comparison, since nothing among the files that
      # specification answers for claims it.
      #
      # Saying nothing about it would leave the statement reported as claimed
      # nowhere with the claim in plain sight.
      class Misplaced
        def initialize(check)
          @check = check
        end

        # Named by the specification that declares it rather than by its
        # includes: the fix is written there, and one reaching dozens of files
        # would otherwise spell all of them at the reader.
        def run(claims, declaring, reach)
          found = []
          claims.each do |claim|
            spec = declaring[claim.key]
            next if spec.nil?
            next unless reach[spec][claim.place.path].nil?

            found.push(Finding.new(
              check: @check, difference: false, place: claim.place,
              message: "#{claim.said} is claimed outside what #{spec} includes"
            ))
          end
          found
        end
      end

      # One thing claimed in two places. A contract is the way in, so a second
      # way in is a difference about the code: the specification is unambiguous
      # and the code grew an entrance it does not describe.
      #
      # Only resolved claims are compared. Two claims on a name nothing
      # declares are already two findings, and saying they agree with each
      # other adds nothing.
      class Duplicated
        def initialize(check)
          @check = check
        end

        def run(claims, stated)
          declared = {}
          stated.each { |one| declared[one.key] = true }

          seen = {}
          claims.each do |claim|
            next if declared[claim.key].nil?

            group = seen[claim.key]
            if group.nil?
              group = []
              seen[claim.key] = group
            end
            group.push(claim)
          end

          found = []
          seen.keys.sort.each do |key|
            group = seen[key]
            next if group.length < 2

            # Each of a group answers once, naming the next one round, so two
            # of them read as two lines pointing at each other rather than as
            # every pairing of the places involved.
            group.zip(group.rotate).each do |pair|
              found.push(Finding.new(
                check: @check, difference: true, place: pair[0].place,
                message: "#{pair[0].said} is claimed at #{pair[1].place.spoken} as well"
              ))
            end
          end
          found
        end
      end
    end
  end
end
