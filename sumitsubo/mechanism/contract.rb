require "sumitsubo/check/claim"
require "sumitsubo/check/declaration"
require "sumitsubo/check/reach"
require "sumitsubo/definition/declared"
require "sumitsubo/definition/kept"
require "sumitsubo/definition/compared"
require "sumitsubo/reach"
require "sumitsubo/relation"
require "sumitsubo/specification/builder/contract"
require "sumitsubo/finding"
require "sumitsubo/mechanism/seed"

module Sumitsubo
  module Mechanism
    # The interfaces a project means to keep, checked against the source
    # implementing them. What it establishes is that a declared interface is
    # implemented somewhere in scope, never that the implementation is right.
    #
    # Verification runs one way: an interface nothing claims is a difference,
    # while an interface nobody declared is not. Only the contracts that matter
    # are registered, so the absence of a declaration says nothing.
    #
    # Which of the two readings below applies is the definition's own to say:
    # writing a marker says source claims its contracts in a comment, and
    # naming a language says the syntax tree answers for them instead.
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
        STALE = "contract/stale"

        def initialize
          @unclaimed = Check::Claim::Unclaimed.new(UNCLAIMED)
          @duplicated = Check::Claim::Duplicated.new(DUPLICATED)
          @misplaced = Check::Claim::Misplaced.new(MISPLACED)
          @unresolved = Check::Claim::Unresolved.new(UNRESOLVED, "contract")
          @nameless = Check::Claim::Nameless.new(NAMELESS, "contract")
          @dangling = Check::Claim::Dangling.new(DANGLING)
          @stale = Check::Claim::Stale.new(STALE)
        end

        def run(findings, definitions, relations, mechanism)
          reach = Reach.of(Definition.claimed(definitions), relations)
          claims = Definition.read(relations.naming(Relation::CLAIM, mechanism))
          stated = Definition.stated_in(definitions)
          registering = Definition.registering_claims(definitions)
          # What the two checks below compare is the claims that can implement
          # what they name; the rest answer for themselves further down.
          within = Check::Claim.within(claims, registering, reach)

          @unclaimed.run(stated, within).each { |one| findings.add(one) }
          @stale.run(stated, within).each { |one| findings.add(one) }
          @duplicated.run(within, stated).each { |one| findings.add(one) }
          @misplaced.run(claims, registering, reach).each { |one| findings.add(one) }
          @unresolved.run(Definition.named(claims), stated).each { |one| findings.add(one) }
          @nameless.run(Definition.nameless(claims)).each { |one| findings.add(one) }
          # A marker standing in front of nothing names an interface without
          # implementing one, so it is answered once, by itself, rather than
          # through the comparisons above.
          @dangling.run(Definition.read(relations.naming(Relation::DANGLING, mechanism))).each { |one| findings.add(one) }
        end
      end

      # The syntax tree answers for the interface outright, so this reading
      # makes no claims: what it compares is what the source defines and the
      # shape a caller would have to call it with.
      class Defined
        UNDEFINED = "contract/undefined"
        CONFLICTING = "contract/conflicting"
        MISMATCHED = "contract/mismatched"
        STALE = "contract/stale"

        def initialize
          @undefined = Check::Declaration::Undefined.new(UNDEFINED)
          @conflicting = Check::Declaration::Conflicting.new(CONFLICTING)
          @mismatched = Check::Declaration::Mismatched.new(MISMATCHED)
          @stale = Check::Declaration::Stale.new(STALE)
        end

        def run(findings, definitions, source, relations, mechanism)
          reach = Reach.of(Definition.defined(definitions), relations)
          declared = Definition.defining(
            definitions, Definition.declared_from(relations.naming(Relation::DECLARES, mechanism)), reach
          )
          grouped = Definition.declared_in(declared)

          stated = Definition.stated_names(definitions)
          @undefined.run(stated, grouped).each { |one| findings.add(one) }
          @stale.run(stated, grouped).each { |one| findings.add(one) }
          @conflicting.run(Definition.spelled_names(definitions), grouped).each { |one| findings.add(one) }
          @mismatched.run(Definition.registered_in(definitions, source), grouped).each { |one| findings.add(one) }
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

      def switches
        []
      end

      # A seed with no content is a directory: a project registers one kind of
      # contract per file, so there is a place rather than a file to create.
      def seed(root)
        Seed.new(Definition.path_in(root), nil)
      end

      # Which kinds of block this form reads, asked before a document is
      # read so that a parser answers with those and no others.
      def kinds
        Specification::Builder::Contract::KINDS
      end

      # The languages arrive with the blocks because a contract's signature is
      # read by the very reading that reads the source it describes.
      def read(blocks, path, languages)
        Specification::Builder::Contract.new(path, languages).build(blocks)
      end

      # A document this form refused, worded as the finding a run answers
      # with. The check is worded here because it is this mechanism's, the way
      # every other check of its own is.
      def refused(refusal)
        Finding.refused(UNREADABLE, refusal)
      end

      # Nothing about how a definition is written is checked yet, so it is
      # written the one way it reads.
      def rewrites(config, definition, lines)
        []
      end

      # Every specification this mechanism keeps, and everything that can be
      # said about them before a line of source is read: one name standing for
      # two interfaces is refused here, because no document answers for it by
      # itself. What a form refused is already kept as the documents were read.
      #
      # `fmt` asks for this and nothing else, and `verify` asks for it first,
      # so the two commands say the same thing about a reference line.
      def declared(config, specifications)
        definitions = specifications.all(Definition.path_in(config.root), self)
        Definition.refuse_ambiguity(definitions)
        definitions
      end

      # Every contract the specifications declare, which is what a statement
      # elsewhere names by its key.
      def statements(config, specifications)
        declared(config, specifications).map { |one| one.statements }.flatten
      end

      # The files every definition reaches.
      def reach(config, specifications, relations)
        Reach.keep(declared(config, specifications), config.base, config.exclusion, relations, config.here)
      end

      # What the source says about each contract, kept for whoever asks after:
      # every claim and declaration in the files the definitions reach.
      def keep(config, specifications, source, relations)
        Definition.keep(declared(config, specifications), source, relations, specification)
      end

      # The statements a key written elsewhere names: every one declared under
      # it, so a key two of them answer to is not quietly taken as either.
      def find(key, writer, config, specifications, relations, named)
        named.select { |one| one.key == key }
      end

      def verify(config, findings, specifications, source, relations)
        definitions = declared(config, specifications)
        # An include covers no file whichever reading the definition writing it
        # chose, so it is asked once for all of them.
        @barren.run(Reach.covers(definitions), config.base, config.exclusion)
               .each { |one| findings.add(one) }
        @claimed.run(findings, definitions, relations, specification)
        @defined.run(findings, definitions, source, relations, specification)
      end
    end
  end
end
