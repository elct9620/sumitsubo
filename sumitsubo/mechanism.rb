require "sumitsubo/glossary"
require "sumitsubo/contract"
require "sumitsubo/behavior"
require "sumitsubo/specification/repository"
require "sumitsubo/source/repository"

module Sumitsubo
  # A mechanism is one kind of specification and the checks it is verified by.
  # It names the word .sumi.json switches it by, lays down a seed to start a
  # reference line from, says how a file of its own is read, and runs its
  # checks over what the two repositories hand back.
  #
  # A mechanism registers by being in the list: Spinel decides what an
  # executable carries when it is built, so there is no hook to register
  # through.
  #
  # What a build carries arrives as those two repositories rather than being
  # named here, the way the revision does. Nothing in this graph reaches a
  # grammar or names a format, which is what leaves a snapshot of it one
  # `--regen` can write.
  module Mechanism
    # What a mechanism lays down to start a reference line from. A seed with no
    # content is a directory: a project keeps one specification per feature, so
    # there is a place rather than a file to create.
    Seed = Struct.new(:path, :content)

    class Glossary
      # The name .sumi.json knows this specification by.
      def specification
        "glossary"
      end

      def seed(root)
        Seed.new(Sumitsubo::Glossary.path_in(root), Sumitsubo::Glossary::SEED)
      end

      # What a mechanism could not read is its own to report, so the parser's
      # refusal is answered under this mechanism's name.
      def read(parser, path, source)
        parser.glossary(path)
      rescue Sumitsubo::Unreadable => e
        raise Sumitsubo::Glossary::Error, e.message
      end

      def verify(config, findings, specifications, source)
        path = Sumitsubo::Glossary.path_in(config.root)
        vocabulary = specifications.one(path, self)
        Sumitsubo::Glossary.barren(vocabulary, config.base, path, config.exclusion, specifications).each { |one| findings.add(one) }
        scope = Sumitsubo::Glossary.scope(vocabulary, config.base, config.exclusion)
        mentions = Sumitsubo::Glossary.uses(
          Sumitsubo::Glossary.check(scope, config.base, source), vocabulary
        )
        Sumitsubo::Glossary.standing(mentions, vocabulary, config.base).each { |one| findings.add(one) }
        Sumitsubo::Glossary.stale(mentions, vocabulary).each { |one| findings.add(one) }
      end
    end

    class Contract
      def specification
        "contract"
      end

      # A seed with no content is a directory: a project registers one kind of
      # contract per file, so there is a place rather than a file to create.
      def seed(root)
        Seed.new(Sumitsubo::Contract.path_in(root), nil)
      end

      # The languages arrive with the parser because a contract's signature is
      # read by the very reading that reads the source it describes.
      def read(parser, path, source)
        parser.contract(path, source)
      rescue Sumitsubo::Unreadable => e
        raise Sumitsubo::Contract::Error, e.message
      end

      def verify(config, findings, specifications, source)
        definitions = specifications.all(Sumitsubo::Contract.path_in(config.root), self)
        Sumitsubo::Contract.refuse_ambiguity(definitions)
        Sumitsubo::Contract.barren(definitions, config.base, config.exclusion, specifications).each { |one| findings.add(one) }
        claimed = Sumitsubo::Contract.claimed(definitions)
        reach = Sumitsubo::Contract.reach(claimed, config.base, config.exclusion)
        claims = Sumitsubo::Contract.claimed_in(definitions, reach, source)
        # What the two readings below compare is the claims that can implement
        # what they name; the rest answer for themselves further down.
        witnessing = Sumitsubo::Contract.witnessing(definitions, claims, reach)

        Sumitsubo::Contract.unclaimed(definitions, witnessing).each { |one| findings.add(one) }
        Sumitsubo::Contract.duplicated(definitions, witnessing).each { |one| findings.add(one) }
        Sumitsubo::Contract.misplaced(definitions, claims, reach).each { |one| findings.add(one) }
        Sumitsubo::Contract.unresolved(definitions, claims).each { |one| findings.add(one) }
        # The other reading makes no claims, so what it compares is what the
        # source defines and the shape a caller would have to call it with.
        spelled = Sumitsubo::Contract.reach(
          Sumitsubo::Contract.defined(definitions), config.base, config.exclusion
        )
        declared = Sumitsubo::Contract.defining(
          definitions, Sumitsubo::Contract.defined_in(definitions, spelled, source), spelled
        )
        Sumitsubo::Contract.undefined(definitions, declared).each { |one| findings.add(one) }
        Sumitsubo::Contract.conflicting(definitions, declared).each { |one| findings.add(one) }
        Sumitsubo::Contract.mismatched(definitions, declared, source).each { |one| findings.add(one) }
      end

    end

    class Behavior
      def specification
        "behavior"
      end

      def seed(root)
        Seed.new(Sumitsubo::Behavior.path_in(root), nil)
      end

      def read(parser, path, source)
        parser.behavior(path)
      rescue Sumitsubo::Unreadable => e
        raise Sumitsubo::Behavior::Error, e.message
      end

      def verify(config, findings, specifications, source)
        features = specifications.all(Sumitsubo::Behavior.path_in(config.root), self)
        Sumitsubo::Behavior.refuse_ambiguity(features)
        Sumitsubo::Behavior.barren(features, config.base, config.exclusion, specifications).each { |one| findings.add(one) }
        reach = Sumitsubo::Behavior.reach(features, config.base, config.exclusion)
        claims = Sumitsubo::Behavior.claimed_in(reach, source)
        # What the reading below compares is the claims that can witness; the
        # rest answer for themselves further down.
        witnessing = Sumitsubo::Behavior.witnessing(features, claims, reach)

        Sumitsubo::Behavior.uncovered(features, witnessing).each { |one| findings.add(one) }
        Sumitsubo::Behavior.misplaced(features, claims, reach).each { |one| findings.add(one) }
        Sumitsubo::Behavior.unresolved(features, claims).each { |one| findings.add(one) }
      end
    end

    # The order a run reaches them in, which is the order init lays them down,
    # and the order the README sets them out in.
    ALL = [Glossary.new, Contract.new, Behavior.new]
  end
end
