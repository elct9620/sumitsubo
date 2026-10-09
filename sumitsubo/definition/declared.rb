require "pathname"
require "sumitsubo/error"
require "sumitsubo/place"
require "sumitsubo/finding"
require "sumitsubo/reach"
require "sumitsubo/relation"
require "sumitsubo/check"
require "sumitsubo/source"
require "sumitsubo/source/repository"
require "sumitsubo/specification"

module Sumitsubo
  # The structured specification the Contract mechanism verifies against. What
  # it establishes is that a declared interface is implemented somewhere in
  # scope, never that the implementation is right.
  #
  # Verification runs one way: an interface nothing claims is a difference,
  # while an interface nobody declared is not. Only the contracts that matter
  # are registered, so the absence of a declaration says nothing.
  #
  # A definition names the word source claims its interfaces with, or names
  # the language its names are spelled in and is read from the syntax tree
  # instead. The marker is what a route needs because no construct of the
  # language points at one; a method is a construct, so which of the two a
  # definition names is what says which reading applies.
  #
  # Nothing here names the grammar. What that keeps regenerable is no longer
  # this file's own test, which reads real documents now, but the three that
  # reach this file through `require "sumitsubo"` alone.
  #
  # A module beside Mechanism::Contract rather than its class methods: Spinel
  # 2026.09.12 cannot type a class method's parameter where another shares its
  # name. Master 7232a802 can, so fold these in once the pin moves past it.
  module Definition
    DIRECTORY = "contract"

    class Error < Sumitsubo::Error; end

    # A definition is a Specification and its contracts are Statements: a
    # name is the key a claim names, and the description is what it says.
    #
    # The marker and the language are attributes of the definition, and a
    # definition carries one or the other: the marker is the word source
    # claims its contracts with, the language is what the other reading
    # spells names in. The signature and `internal` are attributes of the
    # contract, read off the fence under it and off a row a reader wrote;
    # either is absent where nothing said it, which is not the same as
    # having said nothing.

    # What a claim, or a declaration, refers to: a name and the word it is
    # registered under. The marker is that word for the reading that claims —
    # `@command verify` and `@route verify` name different things — and the
    # language for the one that declares, since two languages may spell one
    # name and mean nothing alike.
    #
    # Two of them saying the same thing are the same name, which is what
    # lets the two sides find each other without a key being spelled out at
    # every place they meet. Spoken to a reader it is the pair, except that the
    # reading which declares has no word: a message should not read as though
    # one were missing.
    Name = Data.define(:namespace, :bare) do
      include Comparable

      # Ordered so a run answers in the same order twice, which is all this is
      # for: what the order means to a reader is nothing.
      def <=>(other)
        [namespace.to_s, bare] <=> [other.namespace.to_s, other.bare]
      end

      # Said to a reader. Named rather than left to `to_s`, because what a
      # message shows is this mechanism's to decide and not a conversion
      # anything may reach for.
      def spoken
        namespace.nil? ? bare : "#{namespace} #{bare}"
      end
    end

    # The mechanism names its own directory; where the root sits is the tool's
    # to say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / DIRECTORY
    end

    # The word source claims this definition's contracts with, or nil where
    # the definition names a language and is read from the syntax tree
    # instead. Attributes answer lists, so the one word a definition carries
    # is the first of one.
    def self.marker_of(definition)
      words = definition.attributes["marker"]
      words.nil? ? nil : words[0]
    end

    # The language one contract's name is spelled in. A signature says it on the
    # contract itself, which is what lets one definition register contracts in
    # two languages; where a specification says it once for the whole file,
    # that is what every contract under it answers.
    def self.language_of(definition, interface)
      named = interface.attributes["language"]
      return named[0] unless named.nil?

      named = definition.attributes["language"]
      named.nil? ? nil : named[0]
    end

    # Every language one definition registers contracts in, which is once per
    # language its files are read as.
    def self.languages_of(definition)
      found = []
      definition.statements.each do |interface|
        language = language_of(definition, interface)
        found.push(language) unless language.nil?
      end
      found.uniq.sort
    end

    # What a name is registered under. The marker is the namespace for the
    # reading that claims — `@command verify` and `@route verify` name
    # different things — and the language is the namespace for the other,
    # because a name is spelled the way one language spells it and a Rust
    # declaration does not implement a Ruby contract.
    def self.namespace_of(definition, interface)
      marker = marker_of(definition)
      marker.nil? ? language_of(definition, interface) : marker
    end

    def self.claimed(definitions)
      found = []
      definitions.each { |definition| found.push(definition) unless marker_of(definition).nil? }
      found
    end

    def self.defined(definitions)
      found = []
      definitions.each { |definition| found.push(definition) if marker_of(definition).nil? }
      found
    end

    # The words source claims these contracts with, read in one pass.
    def self.keywords(definitions)
      claimed(definitions).map { |definition| marker_of(definition) }.uniq.sort
    end

    # An interface defined with a shape other than the one registered. Where
    # the definitions disagree among themselves that is already answered, and
    # comparing the contract against one of them would add nothing.
    # A claim resolving to no interface. Nothing on the specification side can
    # confirm it, which is a comparison that could not be made rather than a
    # difference.
    # A claim carrying nothing after the marker names no contract at all,
    # which is a different thing to say than a name that resolves to none.
    # One interface claimed in two places. A contract is the way in, so a
    # second way in is a difference about the code: the specification is
    # unambiguous and the code grew an entrance it does not describe.
    #
    # Only resolved claims are compared. Two claims on a name nothing declares
    # are already two findings, and saying they agree with each other adds
    # nothing.
    # What a caller would have to write. A scope has no call to describe at
    # all, which is not the same as a method taking nothing.
    # What a mechanism could not read is its own to report, so the parser's
    # refusal is answered here under this mechanism's own name.
    # The marker is the namespace, so two files may share one word and one
    # name may sit under two words. What cannot happen is the same name twice
    # under the same word: a claim carries only those two, and a name that
    # is not unique resolves to nothing.
    def self.refuse_ambiguity(definitions)
      seen = {}
      definitions.each do |definition|
        definition.statements.each do |interface|
          name = Name.new(namespace_of(definition, interface), interface.key)
          where = seen[name]
          unless where.nil?
            # Spoken under the marker rather than under what it was told apart
            # by: a reader is being sent to two places that spell one name, and
            # the language it was read as is not what they have to choose
            # between.
            said = Name.new(marker_of(definition), interface.key).spoken
            raise Error, "#{said} is declared twice, at #{where} and #{at(interface)}"
          end

          seen[name] = at(interface)
        end
      end
    end

    # Each of a group answers once, naming the next one round, so two of them
    # read as two lines pointing at each other rather than as every pairing of
    # the places involved.
    # Whether every definition of one name describes the same call. What a
    # reading answers is a value, so two shapes asking a caller for the same
    # thing are the same shape — a scope carrying no parameters at all agrees
    # with itself, and one taking none does not agree with it.
    # What a claim can resolve against. Only the marker reading makes claims,
    # so only its definitions are here.
    def self.at(interface)
      Place.of(interface.path, interface.line).spoken
    end
  end
end
