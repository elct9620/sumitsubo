require "pathname"
require "sumitsubo/error"
require "sumitsubo/where"
require "sumitsubo/parser"
require "sumitsubo/scope"
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
  # Nothing here names the grammar, which is what keeps this file's test on the
  # side that --regen can still write a snapshot for.
  module Contract
    DIRECTORY = "contract"

    class Error < Sumitsubo::Error; end

    # A definition is a Specification and its contracts are Statements: a
    # name is the key a claim names, and the description is what it says.
    #
    # The marker and the language are attributes of the definition, and a
    # definition carries one or the other: the marker is the word source
    # claims its contracts with, the language is what the other reading
    # spells names in. Parameters and `internal` are attributes of the
    # contract. Parameters are absent where none are registered, which is not
    # the same as registering that it takes none, and `internal` is the empty
    # list — it says its one thing by being there.

    # An interface its reading did not find. It answers at the specification
    # that registers it, which is also where the include that bounded the
    # search is written, so the finding names neither. The marker is carried so
    # it can say the word to claim it with; the syntax tree reading has none,
    # so its wording carries the name alone.
    Finding = Struct.new(:path, :line, :marker, :name)
    # An interface defined with a shape other than the one registered. Both
    # are carried, because what a reader chooses between is the two of them.
    Mismatch = Struct.new(:path, :line, :name, :registered, :taken)
    # A claim as this mechanism reads it. Marker hands back what follows the
    # keyword unread, and a contract is named by the interface itself, so the
    # whole of it is the name.
    Claim = Struct.new(:path, :line, :keyword, :name)
    # A claim naming a contract that is really registered, from a file the
    # definition registering it does not include. What it carries is that
    # definition rather than its includes: the fix is written there, and a
    # definition reaching dozens of files would otherwise spell all of them
    # at the reader.
    Misplaced = Struct.new(:path, :line, :marker, :name, :spec)

    # The mechanism names its own directory; where the root sits is the tool's
    # to say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / DIRECTORY
    end

    # Every definition the directory holds. A directory nobody wrote registers
    # no contracts, and a project that has said nothing is not misconfigured,
    # so that answers empty rather than failing.
    #
    # The parsers are handed in the way the languages are: which formats a
    # build carries is decided when it is built, so nothing here names one.
    def self.load(directory, languages, parsers)
      path = Pathname.new(directory)
      return [] unless path.directory?

      definitions = files_in(path).map { |file| definition_from(file, languages, parsers) }
      refuse_ambiguity(definitions)
      definitions
    end

    # A found path is a String: it is what a definition answers with, and what
    # a finding about one of its interfaces points at.
    def self.files_in(path)
      path.glob("*.json").map { |file| "#{file}" }.sort
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
      Scope.of(base, definition.includes, exclusion).each { |path| found[Where.of(base / path)] = true }
      found
    end

    # Every file any definition reaches, which is what gets read. One file
    # answering for two definitions is read once and asked about twice.
    def self.scope(reach)
      found = []
      reach.keys.each { |spec| found.concat(reach[spec].keys) }
      found.uniq.sort
    end

    # Every include a definition writes that covers no file. Its interfaces
    # are then compared against nothing, and every one of them answers as
    # claimed nowhere — which is why saying so is worth a finding of its own.
    #
    # Where an include was written is asked of the parser that read the
    # specification, since only that one knows how its format spells a glob.
    def self.barren(definitions, base, exclusion, parsers)
      found = []
      definitions.each do |definition|
        empty = Scope.barren(base, definition.includes, exclusion)
        next if empty.empty?

        spelled = Parser.of(definition.path, parsers).spelled_in(definition.path)
        where = Where.of(definition.path)
        empty.each { |pattern| found.push(Scope::Barren.new(where, pattern, spelled[pattern])) }
      end
      found
    end

    # The word source claims this definition's contracts with, or nil where
    # the definition names a language and is read from the syntax tree
    # instead. Attributes answer lists, so the one word a definition carries
    # is the first of one.
    def self.marker_of(definition)
      words = definition.attributes["marker"]
      words.nil? ? nil : words[0]
    end

    # The language the other reading spells names in, under the same rule.
    def self.language_named(definition)
      named = definition.attributes["language"]
      named.nil? ? nil : named[0]
    end

    # The definitions whose interfaces source claims in a comment, and the ones
    # read from the syntax tree. Each reading searches only its own files: a
    # marker nobody wrote is not worth parsing for, and a definition nobody
    # claims is not worth reading comments for.
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

    # The claims that can implement what they name: each sitting among the
    # files the definition registering it answers for. Filtering once is what
    # leaves the readings below unchanged — an interface is claimed, or
    # claimed twice, by the claims that count.
    def self.witnessing(definitions, claims, reach)
      registering = registering_claims(definitions)
      found = []
      claims.each do |claim|
        spec = registering[key(claim.keyword, claim.name)]
        next if spec.nil?
        next if reach[spec][claim.path].nil?

        found.push(claim)
      end
      found
    end

    # A claim naming a contract the definition registering it does not reach.
    # The name resolves, so neither side is wrong about the interface; what
    # could not be made is the comparison, since nothing among the files that
    # definition answers for says the interface was implemented.
    def self.misplaced(definitions, claims, reach)
      registering = registering_claims(definitions)
      found = []
      claims.each do |claim|
        spec = registering[key(claim.keyword, claim.name)]
        next if spec.nil?
        next unless reach[spec][claim.path].nil?

        found.push(Misplaced.new(claim.path, claim.line, claim.keyword, claim.name, Where.of(spec)))
      end
      found
    end

    # Which specification registers each contract, so a claim can be asked
    # whether it sits where that specification can see it. One pair belongs to
    # one definition, which is what refuse_ambiguity guarantees.
    def self.registering_claims(definitions)
      found = {}
      claimed(definitions).each do |definition|
        spec = definition.path
        definition.statements.each { |interface| found[key(marker_of(definition), interface.key)] = spec }
      end
      found
    end

    # An interface nothing claims: the specification registers it and no source
    # the definition reaches says it was implemented, which is a difference
    # between the two sides.
    def self.unclaimed(definitions, claims)
      made = {}
      claims.each { |claim| made[key(claim.keyword, claim.name)] = true }

      found = []
      claimed(definitions).each do |definition|
        definition.statements.each do |interface|
          next unless made[key(marker_of(definition), interface.key)].nil?

          found.push(Finding.new(
            Where.of(interface.path), interface.line, marker_of(definition), interface.key
          ))
        end
      end
      found
    end

    # The declarations that can define what they name: each sitting among the
    # files the definition registering that name answers for. Filtering once
    # is what leaves the three readings below unchanged.
    #
    # Nothing is reported about the ones left out, which is where this reading
    # parts from the other: a claim asserts that a contract was implemented
    # and is wrong where it cannot be, while a class merely sharing a
    # registered name asserts nothing at all.
    def self.defining(definitions, names, reach)
      registering = registering_names(definitions)
      found = []
      names.each do |name|
        spec = registering[name.name]
        next if spec.nil?
        next if reach[spec][name.path].nil?

        found.push(name)
      end
      found
    end

    # Which specification registers each name the syntax tree answers for.
    # The reading has one namespace, the source's, so the name is the whole
    # key; one of them belongs to one definition, which refuse_ambiguity is
    # what guarantees.
    def self.registering_names(definitions)
      found = {}
      defined(definitions).each do |definition|
        spec = definition.path
        definition.statements.each { |interface| found[interface.key] = spec }
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
    def self.undefined(definitions, names)
      declared = declared_in(names)

      found = []
      defined(definitions).each do |definition|
        definition.statements.each do |interface|
          next unless declared[interface.key].nil?

          found.push(Finding.new(
            Where.of(interface.path), interface.line, marker_of(definition), interface.key
          ))
        end
      end
      found
    end

    # A registered interface defined twice with two shapes. A language that
    # lets a type be reopened or implemented in pieces says nothing while only
    # the name is compared: the
    # name is the way in, and there was one of them. A shape is part of the
    # way in, so two shapes are an entrance the specification does not
    # describe — the same difference a contract claimed in two places is.
    #
    # Definitions agreeing on their shape are one way in, which is what leaves
    # ordinary reopening saying nothing still.
    def self.conflicting(definitions, names)
      declared = declared_in(names)

      found = []
      spelled_names(definitions).each do |name|
        group = declared[name]
        next if group.nil? || group.length < 2 || agreed?(group)

        # Each definition answers once, naming the next one round, so two
        # shapes read as two lines pointing at each other.
        index = 0
        while index < group.length
          found.push([group[index], group[(index + 1) % group.length]])
          index += 1
        end
      end
      found
    end

    # An interface defined with a shape other than the one registered. Where
    # the definitions disagree among themselves that is already answered, and
    # comparing the contract against one of them would add nothing.
    def self.mismatched(definitions, names)
      declared = declared_in(names)

      found = []
      defined(definitions).each do |definition|
        definition.statements.each do |interface|
          registered = interface.attributes["params"]
          next if registered.nil?

          group = declared[interface.key]
          next if group.nil? || !agreed?(group)
          next if agree?(registered, group[0].params)

          found.push(Mismatch.new(
            Where.of(interface.path), interface.line, interface.key,
            registered, group[0].params
          ))
        end
      end
      found
    end

    # A claim resolving to no interface. Nothing on the specification side can
    # confirm it, which is a comparison that could not be made rather than a
    # difference.
    def self.unresolved(definitions, claims)
      registered = registered_in(definitions)

      found = []
      claims.each { |claim| found.push(claim) if registered[key(claim.keyword, claim.name)].nil? }
      found
    end

    # One interface claimed in two places. A contract is the way in, so a
    # second way in is a difference about the code: the specification is
    # unambiguous and the code grew an entrance it does not describe.
    #
    # Only resolved claims are compared. Two claims on a name nothing declares
    # are already two findings, and saying they agree with each other adds
    # nothing.
    def self.duplicated(definitions, claims)
      registered = registered_in(definitions)

      seen = {}
      claims.each do |claim|
        name = key(claim.keyword, claim.name)
        next if registered[name].nil?

        group = seen[name]
        if group.nil?
          group = []
          seen[name] = group
        end
        group.push(claim)
      end

      # Each claim answers once, naming the next one round, so a contract
      # claimed twice reads as two lines pointing at each other rather than as
      # every pairing of the places that claim it.
      found = []
      seen.keys.sort.each do |name|
        group = seen[name]
        next if group.length < 2

        index = 0
        while index < group.length
          found.push([group[index], group[(index + 1) % group.length]])
          index += 1
        end
      end
      found
    end

    def self.describe_misplaced(claim)
      "#{spoken(claim.marker, claim.name)} is claimed outside what #{claim.spec} includes"
    end

    # The mechanism words its own findings; where each points is the tool's to
    # shape.
    def self.describe_unclaimed(finding)
      "#{spoken(finding.marker, finding.name)} is claimed nowhere this specification includes"
    end

    # The caveat rides every one of these because the tree cannot tell the two
    # cases apart: a definition a macro or a mixin brings into being is missing
    # from it exactly as an unwritten one is, and rewriting that one fixes
    # nothing. Which constructs those are is each language's own, so the
    # message names the shape and `sumi help contract` names them.
    def self.describe_undefined(finding)
      "#{spoken(finding.marker, finding.name)} is defined nowhere this specification " \
        "includes, and one the reading cannot see never is"
    end

    def self.describe_conflicting(pair)
      one = pair[0]
      other = pair[1]
      "#{one.name} takes #{spell(one.params)} here and " \
        "#{spell(other.params)} at #{other.path}:#{other.line}"
    end

    def self.describe_mismatched(mismatch)
      "#{mismatch.name} takes #{spell(mismatch.taken)} " \
        "where the specification registers #{spell(mismatch.registered)}"
    end

    # What a caller would have to write. The kind is left out where a bare
    # name already says it, and a dash stands where the parameter has none of
    # its own. A scope has no call to describe at all, which is not the same
    # as a method taking nothing.
    def self.spell(params)
      return "nothing" if params.nil?

      spelled = params.map { |param| spelled_as(param) }
      "(#{spelled.join(", ")})"
    end

    def self.spelled_as(param)
      name = param.name.nil? ? "-" : param.name
      kind = param.kind == POSITIONAL ? "" : ":#{param.kind}"
      "#{name}#{kind}#{param.optional ? "?" : ""}"
    end

    def self.describe_unresolved(claim)
      return "#{claim.keyword} names no contract" if claim.name.empty?

      "#{claim.keyword} #{claim.name} resolves to no contract"
    end

    def self.describe_duplicated(pair)
      claim = pair[0]
      other = pair[1]
      "#{claim.keyword} #{claim.name} is claimed at #{other.path}:#{other.line} as well"
    end

    # What a mechanism could not read is its own to report, so the parser's
    # refusal is answered here under this mechanism's own name.
    def self.definition_from(path, languages, parsers)
      Parser.of(path, parsers).contract(path, languages)
    rescue Sumitsubo::Unreadable => e
      raise Error, e.message
    end

    # The marker is the namespace, so two files may share one word and one
    # name may sit under two words. What cannot happen is the same name twice
    # under the same word: a claim carries only those two, and a referent that
    # is not unique resolves to nothing.
    def self.refuse_ambiguity(definitions)
      seen = {}
      definitions.each do |definition|
        definition.statements.each do |interface|
          name = key(marker_of(definition), interface.key)
          where = seen[name]
          unless where.nil?
            raise Error, "#{spoken(marker_of(definition), interface.key)} is declared twice, " \
                         "at #{where} and #{at(interface)}"
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
    def self.declared_in(names)
      found = {}
      names.each do |name|
        holding = found[name.name]
        if holding.nil?
          holding = []
          found[name.name] = holding
        end
        holding.push(name)
      end
      found
    end

    # The names the syntax tree reading registers, in an order that leaves no
    # ties.
    def self.spelled_names(definitions)
      found = []
      defined(definitions).each do |definition|
        definition.statements.each { |interface| found.push(interface.key) }
      end
      found.uniq.sort
    end

    # Whether every definition of one name describes the same call.
    def self.agreed?(group)
      index = 1
      while index < group.length
        return false unless agree?(group[0].params, group[index].params)

        index += 1
      end
      true
    end

    # Whether two shapes ask a caller for the same thing. A scope carries no
    # parameters at all, so a class reopened agrees with itself.
    def self.agree?(one, other)
      return true if one.nil? && other.nil?
      return false if one.nil? || other.nil? || one.length != other.length

      index = 0
      while index < one.length
        return false unless same?(one[index], other[index])

        index += 1
      end
      true
    end

    # The kind is compared as text. This file never learns what any of those
    # words means, which is what keeps the specification free of the language
    # its included files happen to be written in.
    def self.same?(one, other)
      one.name == other.name && one.kind == other.kind && one.optional == other.optional
    end

    # What a claim can resolve against. Only the marker reading makes claims,
    # so only its definitions are here.
    def self.registered_in(definitions)
      registered = {}
      claimed(definitions).each do |definition|
        definition.statements.each { |interface| registered[key(marker_of(definition), interface.key)] = true }
      end
      registered
    end

    # What a claim resolves against. The marker is part of it because it is the
    # namespace: `@command verify` and `@route verify` name different things.
    # The syntax tree reading has one namespace, the source's, which is what a
    # definition naming no marker shares with every other one.
    def self.key(marker, name)
      "#{marker} #{name}"
    end

    # The same pair said to a reader. A key carries the empty namespace the
    # syntax tree reading shares, and a message should not read as though a
    # word were missing from it.
    def self.spoken(marker, name)
      marker.nil? ? name : key(marker, name)
    end

    def self.at(interface)
      "#{Where.of(interface.path)}:#{interface.line}"
    end
  end
end
