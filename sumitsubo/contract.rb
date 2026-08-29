require "pathname"
require "sumitsubo/error"
require "sumitsubo/where"
require "sumitsubo/parser"
require "sumitsubo/finding"
require "sumitsubo/scope"
require "sumitsubo/source"
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

    # The one kind word this tool owns rather than borrows: it names the
    # parameter a caller writes with no marking of any sort, which every
    # language has one of. A finding leaves it out, because a bare name in a
    # spelled shape already says it.
    POSITIONAL = "positional"

    # The checks this specification answers for, so a finding is told apart by
    # which one found it rather than by its wording.
    BARREN = "contract/barren"
    UNCLAIMED = "contract/unclaimed"
    UNDEFINED = "contract/undefined"
    DUPLICATED = "contract/duplicated"
    CONFLICTING = "contract/conflicting"
    MISMATCHED = "contract/mismatched"
    MISPLACED = "contract/misplaced"
    UNRESOLVED = "contract/unresolved"

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
    Claim = Data.define(:path, :line, :contract)

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

      definitions = files_in(path, parsers).map { |file| definition_from(file, languages, parsers) }
      refuse_ambiguity(definitions)
      definitions
    end

    # A found path is a String: it is what a definition answers with, and what
    # a finding about one of its interfaces points at.
    #
    # Which files are specifications is the parsers' to say rather than an
    # extension written here: a project registers one kind of contract per file
    # and this build reads whichever formats it was built with. What no parser
    # answers for is passed over, so a directory is still the project's to keep
    # other things in.
    def self.files_in(path, parsers)
      path.glob("*").select { |file| file.file? && Parser.reads?(file, parsers) }
          .map { |file| "#{file}" }.sort
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
    # registering contracts in two languages has each of its files read once
    # per language, since one file may declare a name in only one of them.
    Reading = Data.define(:path, :language)

    def self.readings_in(definitions, reach)
      found = []
      defined(definitions).each do |definition|
        paths = reached(reach, definition)
        languages_of(definition).each do |language|
          paths.each { |path| found.push(Reading.new(path, language)) }
        end
      end
      found
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
        spec = registering[claim.contract]
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
        spec = registering[claim.contract]
        next if spec.nil?
        next unless reach[spec][claim.path].nil?

        # Named by the definition that registers the contract rather than by
        # its includes: the fix is written there, and a definition reaching
        # dozens of files would otherwise spell all of them at the reader.
        found.push(Finding.new(
          rule: MISPLACED, difference: false,
          path: claim.path, line: claim.line,
          message: "#{claim.contract.spoken} is claimed outside what #{Where.of(spec)} includes"
        ))
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
        definition.statements.each { |interface| found[Name.new(marker_of(definition), interface.key)] = spec }
      end
      found
    end

    # An interface nothing claims: the specification registers it and no source
    # the definition reaches says it was implemented, which is a difference
    # between the two sides.
    def self.unclaimed(definitions, claims)
      made = {}
      claims.each { |claim| made[claim.contract] = true }

      found = []
      claimed(definitions).each do |definition|
        definition.statements.each do |interface|
          name = Name.new(marker_of(definition), interface.key)
          next unless made[name].nil?

          # It answers at the specification that registers it, which is also
          # where the include that bounded the search is written, so the
          # message names neither.
          found.push(Finding.new(
            rule: UNCLAIMED, difference: true,
            path: Where.of(interface.path), line: interface.line,
            message: "#{name.spoken} is claimed nowhere this specification includes"
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
    def self.undefined(definitions, declared)
      grouped = declared_in(declared)

      found = []
      defined(definitions).each do |definition|
        definition.statements.each do |interface|
          name = Name.new(language_of(definition, interface), interface.key)
          next unless grouped[name].nil?

          # The caveat rides every one of these because the tree cannot tell
          # two cases apart: a definition a macro or a mixin brings into being
          # is missing from it exactly as an unwritten one is, and rewriting
          # that one fixes nothing. Which constructs those are is each
          # language's own, so this names the shape and `sumi help contract`
          # names them.
          found.push(Finding.new(
            rule: UNDEFINED, difference: true,
            path: Where.of(interface.path), line: interface.line,
            message: "#{name.spoken} is defined nowhere this specification " \
                     "includes, and one the reading cannot see never is"
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
    def self.conflicting(definitions, declared)
      grouped = declared_in(declared)

      found = []
      spelled_names(definitions).each do |spelled|
        group = grouped[spelled]
        next if group.nil? || group.length < 2 || agreed?(group)

        paired(group).each do |pair|
          found.push(Finding.new(
            rule: CONFLICTING, difference: true,
            path: pair[0].path, line: pair[0].line,
            message: "#{pair[0].name} takes #{spell(pair[0].params)} here and " \
                     "#{spell(pair[1].params)} at #{pair[1].path}:#{pair[1].line}"
          ))
        end
      end
      found
    end

    # The shape a contract registers, read out of the signature it was written
    # with. The reading that answers what source declares is the one that
    # answers this, so a shape no definition could have is a shape no
    # specification can register.
    #
    # A scope registers no shape at all, which is not the same as a call taking
    # nothing: `class Store` says how the name is reached and describes no call.
    def self.shape_of(definition, interface, languages)
      signature = interface.attributes["signature"]
      return nil if signature.nil?

      found = languages.declarations_of(
        signature[0], interface.path, language_of(definition, interface)
      )
      declared = found.find { |one| one.name == interface.key }
      declared.nil? ? nil : declared.params
    end

    # An interface defined with a shape other than the one registered. Where
    # the definitions disagree among themselves that is already answered, and
    # comparing the contract against one of them would add nothing.
    def self.mismatched(definitions, declared, languages)
      grouped = declared_in(declared)

      found = []
      defined(definitions).each do |definition|
        definition.statements.each do |interface|
          registered = shape_of(definition, interface, languages)
          next if registered.nil?

          group = grouped[Name.new(language_of(definition, interface), interface.key)]
          next if group.nil? || !agreed?(group)
          next if registered == group[0].params

          # Both shapes are said, because what a reader chooses between is the
          # two of them; the name is spelled alone, since the reading this
          # comes from shows no word in front of it.
          found.push(Finding.new(
            rule: MISMATCHED, difference: true,
            path: Where.of(interface.path), line: interface.line,
            message: "#{interface.key} takes #{spell(group[0].params)} " \
                     "where the specification registers #{spell(registered)}"
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
      claims.each do |claim|
        next unless registered[claim.contract].nil?

        found.push(Finding.new(
          rule: UNRESOLVED, difference: false,
          path: claim.path, line: claim.line,
          message: unresolved_message(claim.contract)
        ))
      end
      found
    end

    # A claim carrying nothing after the marker names no contract at all,
    # which is a different thing to say than a name that resolves to none.
    def self.unresolved_message(contract)
      return "#{contract.namespace} names no contract" if contract.bare.empty?

      "#{contract.spoken} resolves to no contract"
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
        spelled = claim.contract
        next if registered[spelled].nil?

        group = seen[spelled]
        if group.nil?
          group = []
          seen[spelled] = group
        end
        group.push(claim)
      end

      found = []
      seen.keys.sort.each do |spelled|
        group = seen[spelled]
        next if group.length < 2

        paired(group).each do |pair|
          found.push(Finding.new(
            rule: DUPLICATED, difference: true,
            path: pair[0].path, line: pair[0].line,
            message: "#{pair[0].contract.spoken} is claimed at " \
                     "#{pair[1].path}:#{pair[1].line} as well"
          ))
        end
      end
      found
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

    # What a mechanism could not read is its own to report, so the parser's
    # refusal is answered here under this mechanism's own name.
    def self.definition_from(path, languages, parsers)
      Parser.of(path, parsers).contract(path, languages)
    rescue Sumitsubo::Unreadable => e
      raise Error, e.message
    end

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
    def self.paired(group)
      group.zip(group.rotate)
    end

    # Whether every definition of one name describes the same call. What a
    # reading answers is a value, so two shapes asking a caller for the same
    # thing are the same shape — a scope carrying no parameters at all agrees
    # with itself, and one taking none does not agree with it.
    def self.agreed?(group)
      shape = group[0].params
      group.all? { |declared| declared.params == shape }
    end

    # What a claim can resolve against. Only the marker reading makes claims,
    # so only its definitions are here.
    def self.registered_in(definitions)
      registered = {}
      claimed(definitions).each do |definition|
        definition.statements.each { |interface| registered[Name.new(marker_of(definition), interface.key)] = true }
      end
      registered
    end

    def self.at(interface)
      "#{Where.of(interface.path)}:#{interface.line}"
    end
  end
end
