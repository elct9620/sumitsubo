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
  # What a definition hands the Contract mechanism's checks.
  module Definition
    # Every contract a claim could name, said the way a claim says it. Only
    # the definitions source claims are here: the other reading makes none.
    def self.stated_in(definitions)
      found = []
      claimed(definitions).each do |definition|
        definition.statements.each do |interface|
          name = Name.new(marker_of(definition), interface.key)
          found.push(Check::Stated.new(
            key: name, place: Place.of(interface.path, interface.line), said: name.spoken,
            unverifiable: Check.unverifiable(interface.attributes)
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
        next unless claim.key.bare.empty?

        found.push(Check::Made.new(
          key: claim.key, place: claim.place, said: claim.key.namespace
        ))
      end
      found
    end

    def self.named(claims)
      found = []
      claims.each { |claim| found.push(claim) unless claim.key.bare.empty? }
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
            key: name, place: Place.of(interface.path, interface.line), said: name.spoken,
            unverifiable: Check.unverifiable(interface.attributes)
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
  end
end
