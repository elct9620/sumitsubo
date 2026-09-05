require "pathname"
require "sumitsubo/error"
require "sumitsubo/place"
require "sumitsubo/finding"
require "sumitsubo/source/scope"
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
  module Contract
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

    # A claim as this mechanism reads it. Marker hands back what follows the
    # keyword unread, and a contract is named by the interface itself, so the
    # whole of that is the name it carries.
    class Claim < Data.define(:path, :line, :contract, :reaches_code)
      def key
        contract
      end

      def place
        Place.new(path: path, line: line)
      end

      def said
        contract.spoken
      end
    end

    # The mechanism names its own directory; where the root sits is the tool's
    # to say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / DIRECTORY
    end

    # The files each definition reaches, held under the specification that
    # wrote them. As with Behavior, an `include` is the boundary of what a
    # definition answers for: a contract is implemented by the files its own
    # definition covers, and a claim from anywhere else names it without being
    # able to implement it. That boundary is what tells one component's
    # interfaces from another's under a single root, the way a glossary
    # subdomain tells one vocabulary from another.
    def self.reach(definitions, base, exclusion)
      found = {}
      definitions.each { |definition| found[definition.path] = covered(definition, base, exclusion) }
      found
    end

    # One definition's files as a set: what is asked of a claim is whether it
    # sits in there, once per claim.
    def self.covered(definition, base, exclusion)
      found = {}
      globs = definition.includes.map { |one| one.key }
      Source::Scope.of(base, globs, exclusion).each { |path| found[Place.file(base / path)] = true }
      found
    end

    # Every file any definition reaches, which is what gets read. One file
    # answering for two definitions is read once and asked about twice.
    def self.scope(reach)
      found = []
      reach.keys.each { |spec| found.concat(reach[spec].keys) }
      found.uniq.sort
    end

    # What each definition's includes cover, each answering at the definition
    # that wrote them.
    def self.covers(definitions)
      definitions.map { |one| Check::Covers.new(path: one.path, includes: one.includes) }
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

    # Every file to read and the language to read it as. A definition
    # registering contracts in two languages reaches files of both, and each is
    # read as the one that claims it — a file no reading claims for a language
    # holds no name spelled that way, and reading it as that language is a
    # parse that fails rather than an answer.
    Reading = Data.define(:path, :language)

    def self.readings_in(definitions, reach, source)
      found = []
      defined(definitions).each do |definition|
        paths = reached(reach, definition)
        languages_of(definition).each do |language|
          spelled(source, paths, language).each { |one| found.push(one) }
        end
      end
      found
    end

    # The files among these that could carry a name spelled as this language
    # spells it. Which files a definition reaches is its include's to say, and
    # which of them a language could have written is the file's own.
    def self.spelled(source, paths, language)
      found = []
      paths.each do |path|
        found.push(Reading.new(path, language)) if source.spelled_in?(path, language)
      end
      found
    end

    # The definitions whose interfaces source claims in a comment, and the ones
    # read from the syntax tree. Each reading searches only its own files: a
    # marker nobody wrote is not worth parsing for, and a definition nobody
    # claims is not worth reading comments for.
    # Every word every definition claims, read as this mechanism reads them:
    # a contract is named by the interface itself, so the whole of what follows
    # the marker is the name it carries.
    def self.claimed_in(definitions, reach, source)
      found = []
      source.claims(scope(reach), keywords(definitions)).each do |claim|
        found.push(Claim.new(
          path: claim.path, line: claim.line,
          contract: Name.new(claim.keyword, claim.text), reaches_code: claim.reaches_code
        ))
      end
      found
    end

    # What the source in scope defines, held under the language it was read as.
    # A definition registering contracts in two languages has its files read
    # once per language, and one file read twice answers twice: which reading
    # each came back from is what tells the two apart, so it is the answers
    # that are held apart rather than each answer that says which.
    def self.defined_in(definitions, reach, source)
      found = {}
      readings_in(definitions, reach, source).each do |reading|
        holding = found[reading.language]
        if holding.nil?
          holding = []
          found[reading.language] = holding
        end
        source.declarations(reading.path, reading.language).each { |name| holding.push(name) }
      end
      found
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

    # Every contract a claim could name, said the way a claim says it. Only
    # the definitions source claims are here: the other reading makes none.
    def self.stated_in(definitions)
      found = []
      claimed(definitions).each do |definition|
        definition.statements.each do |interface|
          name = Name.new(marker_of(definition), interface.key)
          found.push(Check::Stated.new(
            key: name, place: Place.of(interface.path, interface.line), said: name.spoken
          ))
        end
      end
      found
    end

    # A claim carrying nothing after the marker names nothing at all, which is
    # a different thing to say than a name that resolves to none, so the two
    # are answered apart.
    def self.nameless(claims)
      found = []
      claims.each do |claim|
        next unless claim.contract.bare.empty?

        found.push(Check::Made.new(
          key: claim.key, place: claim.place, said: claim.contract.namespace
        ))
      end
      found
    end

    def self.named(claims)
      found = []
      claims.each { |claim| found.push(claim) unless claim.contract.bare.empty? }
      found
    end

    # The claims that can implement what they name: each sitting among the
    # files the definition registering it answers for. Filtering once is what
    # leaves the readings below unchanged — an interface is claimed, or
    # claimed twice, by the claims that count.
    # A claim naming a contract the definition registering it does not reach.
    # The name resolves, so neither side is wrong about the interface; what
    # could not be made is the comparison, since nothing among the files that
    # definition answers for says the interface was implemented.
    #
    # Saying nothing about it would leave the interface reported as claimed
    # nowhere with the claim in plain sight.
    # Which specification registers each contract, so a claim can be asked
    # whether it sits where that specification can see it. One pair belongs to
    # one definition, which is what refuse_ambiguity guarantees.
    def self.registering_claims(definitions)
      found = {}
      claimed(definitions).each do |definition|
        spec = definition.path
        definition.statements.each { |interface| found[Name.new(marker_of(definition), interface.key)] = spec }
      end
      found
    end

    # An interface nothing claims: the specification registers it and no source
    # the definition reaches says it was implemented, which is a difference
    # between the two sides.
    # The declarations that can define what they name: each sitting among the
    # files the definition registering that name answers for. Filtering once
    # is what leaves the three readings below unchanged.
    #
    # Nothing is reported about the ones left out, which is where this reading
    # parts from the other: a claim asserts that a contract was implemented
    # and is wrong where it cannot be, while a class merely sharing a
    # registered name asserts nothing at all.
    def self.defining(definitions, declared, reach)
      registering = registering_names(definitions)
      found = {}
      declared.keys.each do |language|
        found[language] = defining_in(declared[language], language, registering, reach)
      end
      found
    end

    # One language's declarations, filtered the same way. The language comes
    # from the group holding them rather than from each of them: what a file
    # read twice answers twice is told apart by which reading it came back
    # from, so nothing has to be carried on the answers themselves.
    def self.defining_in(declarations, language, registering, reach)
      found = []
      declarations.each do |declared|
        spec = registering[Name.new(language, declared.name)]
        next if spec.nil?
        next if reach[spec][declared.path].nil?

        found.push(declared)
      end
      found
    end

    # Which specification registers each name the syntax tree answers for.
    # The language is part of the key, so one of them belongs to one
    # definition — which refuse_ambiguity is what guarantees.
    def self.registering_names(definitions)
      found = {}
      defined(definitions).each do |definition|
        spec = definition.path
        definition.statements.each do |interface|
          found[Name.new(language_of(definition, interface), interface.key)] = spec
        end
      end
      found
    end

    # The files one definition reached, in a fixed order.
    def self.reached(reach, definition)
      reach[definition.path].keys.sort
    end

    # An interface the syntax tree does not define. The specification
    # registers it and no source that definition reaches defines it, which is
    # the same difference an unclaimed interface is — the other reading of it.
    # A registered interface defined twice with two shapes. A language that
    # lets a type be reopened or implemented in pieces says nothing while only
    # the name is compared: the
    # name is the way in, and there was one of them. A shape is part of the
    # way in, so two shapes are an entrance the specification does not
    # describe — the same difference a contract claimed in two places is.
    #
    # Definitions agreeing on their shape are one way in, which is what leaves
    # ordinary reopening saying nothing still.
    # The shape a contract registers, read out of the signature it was written
    # with. The reading that answers what source declares is the one that
    # answers this, so a shape no definition could have is a shape no
    # specification can register.
    #
    # A scope registers no shape at all, which is not the same as a call taking
    # nothing: `class Store` says how the name is reached and describes no call.
    def self.shape_of(definition, interface, source)
      signature = interface.attributes["signature"]
      return nil if signature.nil?

      found = source.declarations_of(
        signature[0], interface.path, language_of(definition, interface)
      )
      declared = found.find { |one| one.name == interface.key }
      declared.nil? ? nil : declared.shape
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

    # The shape a contract registers. A kind nobody named is the one a bare
    # name says, which keeps the common parameter down to what it is called.
    # Every definition of each name, kept in the order source declared them. A
    # name may be defined more than once, and which of those a contract
    # describes is not this reading's to decide.
    def self.declared_in(declared)
      found = {}
      declared.keys.each do |language|
        declared[language].each do |one|
          spelled = Name.new(language, one.name)
          holding = found[spelled]
          if holding.nil?
            holding = []
            found[spelled] = holding
          end
          holding.push(one)
        end
      end
      found
    end

    # What the syntax tree reading registers: the name each interface is held
    # under, and the shape the signature says a caller writes. A signature no
    # definition could have is a shape no specification can register, so a
    # contract without one registers nothing to compare.
    def self.registered_in(definitions, source)
      found = []
      defined(definitions).each do |definition|
        definition.statements.each do |interface|
          shape = shape_of(definition, interface, source)
          next if shape.nil?

          found.push(Check::Registered.new(
            key: Name.new(language_of(definition, interface), interface.key),
            place: Place.of(interface.path, interface.line),
            said: interface.key, shape: shape
          ))
        end
      end
      found
    end

    # Every name the syntax tree reading registers, said the way the other
    # reading says one.
    def self.stated_names(definitions)
      found = []
      defined(definitions).each do |definition|
        definition.statements.each do |interface|
          name = Name.new(language_of(definition, interface), interface.key)
          found.push(Check::Stated.new(
            key: name, place: Place.of(interface.path, interface.line), said: name.spoken
          ))
        end
      end
      found
    end

    # The names the syntax tree reading registers, each under the language
    # spelling it, in an order that leaves no ties.
    def self.spelled_names(definitions)
      found = []
      defined(definitions).each do |definition|
        definition.statements.each do |interface|
          found.push(Name.new(language_of(definition, interface), interface.key))
        end
      end
      found.uniq.sort
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
