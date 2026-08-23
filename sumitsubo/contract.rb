require "json"
require "pathname"
require "sumitsubo/error"
require "sumitsubo/where"
require "sumitsubo/locations"
require "sumitsubo/note"
require "sumitsubo/scope"

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

    # An interface's name as it sits in the raw text. JSON carries no line
    # numbers, and the finding for an interface nothing claims answers at the
    # specification that declares it.
    NAME = /"name"\s*:\s*"([^"]*)"/

    class Error < Sumitsubo::Error; end

    # The kind a parameter carries when the specification names none, and the
    # one kind word this tool owns rather than borrows: it names the parameter
    # a caller writes with no marking of any sort, which every language has one
    # of. A reading answers it for that parameter and names the rest itself.
    POSITIONAL = "positional"

    # One parameter a contract registers. The kind is carried as text and
    # never read: what these words mean belongs to the reading that answers
    # them, so a specification writes the words its language uses and this
    # file learns none of them.
    Param = Struct.new(:name, :kind, :optional)

    # An interface is internal when the project means to keep it but not to
    # say so publicly. That is a fact about the interface, and the document it
    # stays out of follows from it — which is what makes it different from the
    # configuration switching a whole specification off.
    #
    # Parameters are absent where the contract registers none, which is not
    # the same as registering that it takes none: only a shape written down
    # asks to be compared.
    Interface = Struct.new(:name, :description, :path, :line, :internal, :params, :notes)
    # A file's worth of contracts. The marker is the word source claims them
    # with, and two files may name the same one: a project splitting its routes
    # across files is registering more of one kind, not a second kind.
    #
    # The language is what the other reading is written in, and only that
    # reading carries one: a claim is a claim in whatever the file is written
    # in, while a name is spelled the way one language spells it.
    Definition = Struct.new(
      :name, :description, :marker, :language, :includes, :interfaces, :path, :notes
    )
    # An interface its reading did not find. The scope is carried so the finding
    # says where it looked rather than that nothing implements it anywhere, and
    # the marker so it can say the word to claim it with. The syntax tree
    # reading has none, so its wording carries the name alone.
    Finding = Struct.new(:path, :line, :marker, :name, :scope)
    # An interface defined with a shape other than the one registered. Both
    # are carried, because what a reader chooses between is the two of them.
    Mismatch = Struct.new(:path, :line, :name, :registered, :taken)
    # A claim as this mechanism reads it. Marker hands back what follows the
    # keyword unread, and a contract is named by the interface itself, so the
    # whole of it is the name.
    Claim = Struct.new(:path, :line, :keyword, :name)

    # The mechanism names its own directory; where the root sits is the tool's
    # to say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / DIRECTORY
    end

    # Every definition the directory holds. A directory nobody wrote registers
    # no contracts, and a project that has said nothing is not misconfigured,
    # so that answers empty rather than failing.
    def self.load(directory, languages)
      path = Pathname.new(directory)
      return [] unless path.directory?

      definitions = files_in(path).map { |file| definition_from(file, languages) }
      refuse_ambiguity(definitions)
      definitions
    end

    # A found path is a String: it is what a definition answers with, and what
    # a finding about one of its interfaces points at.
    def self.files_in(path)
      path.glob("*.json").map { |file| "#{file}" }.sort
    end

    # Every file any definition reaches. As with Behavior, `include` narrows
    # the search rather than tying an interface to one place: the union is what
    # gets scanned, so a claim written outside the file that declared it is
    # still found — and still counted when two places claim one contract.
    def self.scope(definitions, base, exclusion)
      found = []
      definitions.each do |definition|
        Scope.of(base, definition.includes, exclusion).each { |path| found.push(Where.of(base / path)) }
      end
      found.uniq.sort
    end

    # Every include a definition writes that covers no file. Its interfaces
    # are then compared against nothing, which answers as though every one of
    # them were implemented.
    def self.barren(definitions, base)
      found = []
      definitions.each do |definition|
        Scope.barren(base, definition.includes, definition.path).each { |one| found.push(one) }
      end
      found
    end

    # The definitions whose interfaces source claims in a comment, and the ones
    # read from the syntax tree. Each reading searches only its own files: a
    # marker nobody wrote is not worth parsing for, and a definition nobody
    # claims is not worth reading comments for.
    def self.claimed(definitions)
      found = []
      definitions.each { |definition| found.push(definition) unless definition.marker.nil? }
      found
    end

    def self.defined(definitions)
      found = []
      definitions.each { |definition| found.push(definition) if definition.marker.nil? }
      found
    end

    # The words source claims these contracts with, read in one pass.
    def self.keywords(definitions)
      claimed(definitions).map { |definition| definition.marker }.uniq.sort
    end

    # An interface nothing claims: the specification registers it and no source
    # in scope says it was implemented, which is a difference between the two
    # sides.
    def self.unclaimed(definitions, claims)
      made = {}
      claims.each { |claim| made[key(claim.keyword, claim.name)] = true }

      found = []
      claimed(definitions).each do |definition|
        definition.interfaces.each do |interface|
          next unless made[key(definition.marker, interface.name)].nil?

          found.push(Finding.new(
            Where.of(interface.path), interface.line,
            definition.marker, interface.name, definition.includes
          ))
        end
      end
      found
    end

    # An interface the syntax tree does not define. The specification
    # registers it and no source in scope defines it, which is the same
    # difference an unclaimed interface is — the other reading of it.
    def self.undefined(definitions, names)
      declared = declared_in(names)

      found = []
      defined(definitions).each do |definition|
        definition.interfaces.each do |interface|
          next unless declared[interface.name].nil?

          found.push(Finding.new(
            Where.of(interface.path), interface.line,
            definition.marker, interface.name, definition.includes
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
      registered_names(definitions).each do |name|
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
        definition.interfaces.each do |interface|
          next if interface.params.nil?

          group = declared[interface.name]
          next if group.nil? || !agreed?(group)
          next if agree?(interface.params, group[0].params)

          found.push(Mismatch.new(
            Where.of(interface.path), interface.line, interface.name,
            interface.params, group[0].params
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

    # The mechanism words its own findings; where each points is the tool's to
    # shape.
    def self.describe_unclaimed(finding)
      "#{spoken(finding.marker, finding.name)} is claimed nowhere in " \
        "#{finding.scope.join(", ")}"
    end

    # The caveat rides every one of these because the tree cannot tell the two
    # cases apart: a definition a macro or a mixin brings into being is missing
    # from it exactly as an unwritten one is, and rewriting that one fixes
    # nothing. Which constructs those are is each language's own, so the
    # message names the shape and `sumi help contract` names them.
    def self.describe_undefined(finding)
      "#{spoken(finding.marker, finding.name)} is defined nowhere in " \
        "#{finding.scope.join(", ")}, and one the reading cannot see never is"
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

    # Whether a definition has anything to say on a page. A kind whose every
    # interface is internal is nothing to render rather than a heading over an
    # empty table, the way an absent specification is nothing to render at all.
    def self.published?(definition)
      found = false
      definition.interfaces.each { |interface| found = true unless interface.internal }
      found
    end

    # The mechanism words its own document, as it words its own findings. An
    # interface gets a section rather than a row, which is what leaves room
    # for the notes under it; the marker and the include globs stay out,
    # because they say how to find things rather than what the contract means.
    def self.render(definition)
      lines = ["# #{definition.name || document_name(definition)}", ""]
      lines.push(definition.description, "") unless definition.description.nil?
      Note.spell(definition.notes, 1).each { |line| lines.push(line) }

      # An internal interface is still verified; what it is kept out of is the
      # half of the specification a reader outside the project is handed.
      definition.interfaces.each do |interface|
        next if interface.internal

        lines.push("## #{interface.name}", "")
        lines.push(interface.description, "") unless interface.description.nil?
        # The shape sits under the name rather than in it: a reader looking up
        # the interface finds the name, and one about to call it finds this.
        lines.push("`#{signature(interface)}`", "") unless interface.params.nil?
        Note.spell(interface.notes, 2).each { |line| lines.push(line) }
      end
      lines.join("\n")
    end

    # How a reader reaches the interface: its name, and the shape to call it
    # with where the contract registers one. A shape says what the interface
    # is rather than where to find it, which is the line `include` and the
    # marker fall on the other side of.
    def self.signature(interface)
      return interface.name if interface.params.nil?

      "#{interface.name}#{spell(interface.params)}"
    end

    # What a definition is called on the document side: the file declaring it,
    # since one file there is one document here. It stands in for a definition
    # that named itself nothing.
    def self.document_name(definition)
      "#{Pathname.new(definition.path).basename(".json")}"
    end

    def self.definition_from(path, languages)
      text = File.read(path)
      document = parse(path, text)
      # `"name"` is a key this specification uses at three depths — the kind's
      # own, each contract's, and each parameter's — so a value is taken in
      # the order it was written rather than looked up. A contract spelled the
      # same as the kind, or as a parameter of a contract before it, would
      # otherwise answer at that one's line.
      cursor = Locations::Cursor.new(Locations.all_in(text, NAME))
      # The kind names itself first, so passing over it is what leaves the
      # contracts to be read from where they start.
      cursor.line_of(document["name"])

      # A definition naming no marker is read from the syntax tree, so there is
      # no word to look for and none is needed.
      marker = document["marker"]
      language = language_of(path, document, marker, languages)

      interfaces = []
      (document["contracts"] || []).each do |raw|
        name = raw["name"]
        if name.nil?
          raise Error, "#{Where.of(path)} declares a contract with no \"name\"; " \
                       "sumi help contract has the form"
        end

        if marker.nil? && !languages.definable?(language, name)
          raise Error, "#{Where.of(path)} names #{name}, which no #{language} definition " \
                       "can be spelled; sumi help contract has the two readings"
        end

        # Only the syntax tree answers what a definition takes. Parameters
        # registered under a marker would be a promise nobody holds, so the
        # specification is refused rather than carried unchecked.
        if !marker.nil? && !raw["params"].nil?
          raise Error, "#{Where.of(path)} gives #{name} parameters, " \
                       "which a marker leaves nothing to compare them against; " \
                       "sumi help contract has the form"
        end

        line = cursor.line_of(name)
        params = params_from(raw["params"])
        # A parameter names itself too, and passing over those is what leaves
        # a contract spelled the same as one of them answering at its own line.
        params.each { |param| cursor.line_of(param.name) } unless params.nil?

        interfaces.push(Interface.new(
          name, raw["description"], path, line, raw["internal"] == true, params,
          Note.all_in(path, raw["notes"], "contract")
        ))
      end

      Definition.new(
        document["name"],
        document["description"],
        marker,
        language,
        document["include"] || [],
        interfaces,
        path,
        Note.all_in(path, document["notes"], "contract")
      )
    end

    # The language the syntax tree reading is written in. `include` says which
    # files a reading reaches and never what they are written in — a generated
    # file may carry one language under an extension nobody knows — so a
    # definition read that way says which, and one read through a marker has
    # nothing to say it about.
    def self.language_of(path, document, marker, languages)
      named = document["language"]
      unless marker.nil?
        return nil if named.nil?

        raise Error, "#{Where.of(path)} names both a marker and a language, " \
                     "and a claim is a claim in whatever the file is written in; " \
                     "sumi help contract has the two readings"
      end

      if named.nil?
        raise Error, "#{Where.of(path)} names no marker and no language, " \
                     "so nothing says how to spell what it registers; " \
                     "sumi help contract has the two readings"
      end
      return named if languages.carries?(named)

      raise Error, "#{Where.of(path)} names #{named}, which this sumi does not carry"
    end

    # The marker is the namespace, so two files may share one word and one
    # name may sit under two words. What cannot happen is the same name twice
    # under the same word: a claim carries only those two, and a referent that
    # is not unique resolves to nothing.
    def self.refuse_ambiguity(definitions)
      seen = {}
      definitions.each do |definition|
        definition.interfaces.each do |interface|
          name = key(definition.marker, interface.name)
          where = seen[name]
          unless where.nil?
            raise Error, "#{spoken(definition.marker, interface.name)} is declared twice, " \
                         "at #{where} and #{at(interface)}"
          end

          seen[name] = at(interface)
        end
      end
    end

    # The shape a contract registers. A kind nobody named is the one a bare
    # name says, which keeps the common parameter down to what it is called.
    def self.params_from(raw)
      return nil if raw.nil?

      found = []
      raw.each do |param|
        kind = param["kind"]
        found.push(Param.new(param["name"], kind.nil? ? POSITIONAL : kind, param["optional"] == true))
      end
      found
    end

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
    def self.registered_names(definitions)
      found = []
      defined(definitions).each do |definition|
        definition.interfaces.each { |interface| found.push(interface.name) }
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
        definition.interfaces.each { |interface| registered[key(definition.marker, interface.name)] = true }
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

    def self.parse(path, text)
      JSON.parse(text)
    rescue JSON::ParserError
      # The parser's own wording is Spinel's rather than CRuby's, so it stays
      # out of a message a snapshot has to match on both.
      raise Error, "#{Where.of(path)} is not readable JSON"
    end

    def self.at(interface)
      "#{Where.of(interface.path)}:#{interface.line}"
    end
  end
end
