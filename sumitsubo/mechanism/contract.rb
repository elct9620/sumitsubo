require "sumitsubo/check/claim"
require "sumitsubo/check/declaration"
require "sumitsubo/check/reach"
require "sumitsubo/contract"
require "sumitsubo/specification/builder/contract"
require "sumitsubo/mechanism/seed"

module Sumitsubo
  module Mechanism
    # The interfaces a project means to keep, checked against the source
    # implementing them. Which of the two readings below applies is the
    # definition's own to say: writing a marker says source claims its
    # contracts in a comment, and naming a language says the syntax tree
    # answers for them instead.
    class Contract
      BARREN = "contract/barren"
      UNREADABLE = "contract/unreadable"

      # Source says in a comment that it implements an interface, which is what
      # an interface needs when no construct of the language points at it.
      class Claimed
        UNCLAIMED = "contract/unclaimed"
        DUPLICATED = "contract/duplicated"
        MISPLACED = "contract/misplaced"
        UNRESOLVED = "contract/unresolved"
        NAMELESS = "contract/nameless"
        DANGLING = "contract/dangling"

        def initialize
          @unclaimed = Check::Claim::Unclaimed.new(UNCLAIMED)
          @duplicated = Check::Claim::Duplicated.new(DUPLICATED)
          @misplaced = Check::Claim::Misplaced.new(MISPLACED)
          @unresolved = Check::Claim::Unresolved.new(UNRESOLVED, "contract")
          @nameless = Check::Claim::Nameless.new(NAMELESS, "contract")
          @dangling = Check::Claim::Dangling.new(DANGLING, "contract")
        end

        def run(config, findings, definitions, source)
          reach = Sumitsubo::Contract.reach(
            Sumitsubo::Contract.claimed(definitions), config.base, config.exclusion
          )
          claims = Sumitsubo::Contract.claimed_in(definitions, reach, source)
          stated = Sumitsubo::Contract.stated_in(definitions)
          registering = Sumitsubo::Contract.registering_claims(definitions)
          # A claim standing in front of nothing is answered once, by itself: it
          # names an interface without implementing one, so putting it through
          # the comparisons below would say the same thing a second way.
          reaching = Check::Claim.reaching(claims)
          # What the two checks below compare is the claims that can implement
          # what they name; the rest answer for themselves further down.
          witnessing = Check::Claim.witnessing(reaching, registering, reach)

          @unclaimed.run(stated, witnessing).each { |one| findings.add(one) }
          @duplicated.run(witnessing, stated).each { |one| findings.add(one) }
          @misplaced.run(reaching, registering, reach).each { |one| findings.add(one) }
          @unresolved.run(Sumitsubo::Contract.named(reaching), stated).each { |one| findings.add(one) }
          @nameless.run(Sumitsubo::Contract.nameless(reaching)).each { |one| findings.add(one) }
          @dangling.run(Check::Claim.dangling(claims)).each { |one| findings.add(one) }
        end
      end

      # The syntax tree answers for the interface outright, so this reading
      # makes no claims: what it compares is what the source defines and the
      # shape a caller would have to call it with.
      class Defined
        UNDEFINED = "contract/undefined"
        CONFLICTING = "contract/conflicting"
        MISMATCHED = "contract/mismatched"

        def initialize
          @undefined = Check::Declaration::Undefined.new(UNDEFINED)
          @conflicting = Check::Declaration::Conflicting.new(CONFLICTING)
          @mismatched = Check::Declaration::Mismatched.new(MISMATCHED)
        end

        def run(config, findings, definitions, source)
          reach = Sumitsubo::Contract.reach(
            Sumitsubo::Contract.defined(definitions), config.base, config.exclusion
          )
          declared = Sumitsubo::Contract.defining(
            definitions, Sumitsubo::Contract.defined_in(definitions, reach, source), reach
          )
          grouped = Sumitsubo::Contract.declared_in(declared)

          @undefined.run(Sumitsubo::Contract.stated_names(definitions), grouped).each { |one| findings.add(one) }
          @conflicting.run(Sumitsubo::Contract.spelled_names(definitions), grouped).each { |one| findings.add(one) }
          @mismatched.run(Sumitsubo::Contract.registered_in(definitions, source), grouped).each { |one| findings.add(one) }
        end
      end

      def initialize
        @barren = Check::Reach::Barren.new(BARREN)
        @claimed = Claimed.new
        @defined = Defined.new
      end

      def specification
        "contract"
      end

      # A seed with no content is a directory: a project registers one kind of
      # contract per file, so there is a place rather than a file to create.
      def seed(root)
        Seed.new(Sumitsubo::Contract.path_in(root), nil)
      end

      # Which kinds of block this form is written in, asked before a document is
      # read so that a parser answers with those and no others.
      def kinds
        Specification::Builder::Contract::KINDS
      end

      # The source arrives with the blocks because a contract's signature is
      # read by the very reading that reads the source it describes.
      def read(blocks, path, source)
        Specification::Builder::Contract.new(path, source).build(blocks)
      end

      # The rule a document this form refused answers under.
      def unreadable
        UNREADABLE
      end

      # An include covers no file whichever reading the definition writing it
      # chose, so it is asked once for all of them.
      def verify(config, findings, specifications, source)
        definitions = specifications.all(Sumitsubo::Contract.path_in(config.root), self)
        Sumitsubo::Contract.refuse_ambiguity(definitions)
        @barren.run(Sumitsubo::Contract.covers(definitions), config.base, config.exclusion)
               .each { |one| findings.add(one) }
        @claimed.run(config, findings, definitions, source)
        @defined.run(config, findings, definitions, source)
      end
    end
  end
end
