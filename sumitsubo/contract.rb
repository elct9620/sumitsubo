require "json"
require "pathname"
require "sumitsubo/error"
require "sumitsubo/where"
require "sumitsubo/locations"

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
  # none and is read from the syntax tree instead. The marker is what a route
  # needs because no Ruby construct points at one; a method is a construct, so
  # its absence is what says which reading applies.
  #
  # Nothing here names the grammar, which is what keeps this file's test on the
  # side that --regen can still write a snapshot for.
  module Contract
    DIRECTORY = "contract"

    # An interface's name as it sits in the raw text. JSON carries no line
    # numbers, and the finding for an interface nothing claims answers at the
    # specification that declares it.
    NAME = /"name"\s*:\s*"([^"]*)"/

    # A constant path, and a method name. What the check exists for is a file
    # that meant to register routes and lost its marker: read as Ruby, every
    # one of its names would answer as undefined, which is a finding about the
    # code where the truth is a specification that cannot be read.
    CONSTANT = /\A[A-Z][A-Za-z0-9_]*(::[A-Z][A-Za-z0-9_]*)*\z/
    METHOD = /\A([A-Za-z_][A-Za-z0-9_]*[?!=]?|\[\]=?|[<>=!+\-*\/%&|^~]+)\z/

    class Error < Sumitsubo::Error; end

    # The kind a parameter carries when the specification names none. It is
    # the only one of these words this file knows, and it knows it as the
    # value to fill in rather than as anything about Ruby.
    POSITIONAL = "positional"

    # One parameter a contract registers. The kind is carried as text and
    # never read: what these words mean belongs to the reading that answers
    # them, which is what lets a specification stay silent about the language
    # it is about — it speaks whatever the reading of its included files
    # speaks.
    Param = Struct.new(:name, :kind, :optional)

    # The kinds of block a note carries. A closed set, because each is a
    # shape the mechanism has to word, and a word it does not know is a
    # specification it cannot read rather than one to pass through.
    HEADING = "heading"
    PARAGRAPH = "paragraph"
    CODE = "code"

    # How deep a heading may sit under its anchor. Four reaches `######` from
    # a contract, which is as far as the page goes.
    DEEPEST = 4

    # A block of prose the specification carries for the document alone. It
    # says what no mechanism can check — why a rule is the way it is — so
    # nothing here is compared against source.
    #
    # A note names none of its parts, which is what keeps it out of the walk
    # over `"name"` that gives each contract its line.
    Note = Struct.new(:type, :level, :language, :text)

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
    Definition = Struct.new(:name, :description, :marker, :includes, :interfaces, :path, :notes)
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
    def self.load(directory)
      path = Pathname.new(directory)
      return [] unless path.directory?

      definitions = []
      files_in(path).each { |file| definitions.push(definition_from(file)) }
      refuse_ambiguity(definitions)
      definitions
    end

    # A found path is a String: it is what a definition answers with, and what
    # a finding about one of its interfaces points at.
    def self.files_in(path)
      found = []
      path.glob("*.json").each { |file| found.push("#{file}") }
      found.sort
    end

    # Every file any definition reaches. As with Behavior, `include` narrows
    # the search rather than tying an interface to one place: the union is what
    # gets scanned, so a claim written outside the file that declared it is
    # still found — and still counted when two places claim one contract.
    def self.scope(definitions, base)
      found = []
      definitions.each do |definition|
        definition.includes.each do |pattern|
          base.glob(pattern).each { |path| found.push(Where.of(path)) }
        end
      end
      found.uniq.sort
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
      found = []
      claimed(definitions).each { |definition| found.push(definition.marker) }
      found.uniq.sort
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

    # A registered interface defined twice with two shapes. Ruby lets a class
    # be reopened, and while only the name was compared that said nothing: the
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
    # cases apart: a method made by a call or mixed in is missing from it
    # exactly as an unwritten one is, and rewriting that one fixes nothing.
    def self.describe_undefined(finding)
      "#{spoken(finding.marker, finding.name)} is defined nowhere in " \
        "#{finding.scope.join(", ")}, and a method made by a call " \
        "or mixed in never is"
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

      spelled = []
      params.each { |param| spelled.push(spelled_as(param)) }
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
      spell_notes(definition.notes, 1).each { |line| lines.push(line) }

      # An internal interface is still verified; what it is kept out of is the
      # half of the specification a reader outside the project is handed.
      definition.interfaces.each do |interface|
        next if interface.internal

        lines.push("## #{interface.name}", "")
        lines.push(interface.description, "") unless interface.description.nil?
        # The shape sits under the name rather than in it: a reader looking up
        # the interface finds the name, and one about to call it finds this.
        lines.push("`#{signature(interface)}`", "") unless interface.params.nil?
        spell_notes(interface.notes, 2).each { |line| lines.push(line) }
      end
      lines.join("\n")
    end

    # A heading answers relative to where its notes hang, so a specification
    # says how deep a block sits and the mechanism says under what. Absolute
    # levels would have every author work out the anchor for themselves, and
    # get it wrong wherever the page above them moved.
    def self.spell_notes(notes, anchor)
      lines = []
      (notes || []).each do |note|
        case note.type
        when HEADING
          lines.push("#{"#" * (anchor + note.level)} #{note.text}", "")
        when CODE
          lines.push("```#{note.language}", note.text, "```", "")
        else
          lines.push(note.text, "")
        end
      end
      lines
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

    def self.definition_from(path)
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

      interfaces = []
      (document["contracts"] || []).each do |raw|
        name = raw["name"]
        if name.nil?
          raise Error, "#{Where.of(path)} declares a contract with no \"name\"; " \
                       "sumi help contract has the form"
        end

        if marker.nil? && !resolvable?(name)
          raise Error, "#{Where.of(path)} names #{name}, which no Ruby definition can be; " \
                       "sumi help contract has the two readings"
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
          notes_from(path, raw["notes"])
        ))
      end

      Definition.new(
        document["name"],
        document["description"],
        marker,
        document["include"] || [],
        interfaces,
        path,
        notes_from(path, document["notes"])
      )
    end

    # The prose a specification carries so a reader learns what it meant, in
    # the blocks it wrote them as. A block's text arrives as lines and is
    # joined here, because how they close up is what tells the two apart:
    # prose reflows and code does not.
    def self.notes_from(path, raw)
      return [] if raw.nil?

      found = []
      raw.each do |note|
        type = note["type"]
        text = note["text"]
        # Lines rather than one string, so a paragraph reworded a word at a
        # time shows which sentence moved.
        unless text.is_a?(Array)
          raise Error, "#{Where.of(path)} writes a note whose \"text\" is not lines; " \
                       "sumi help contract has the form"
        end

        case type
        when HEADING
          found.push(Note.new(type, depth_of(path, note["level"]), nil, text.join(" ")))
        when PARAGRAPH
          found.push(Note.new(type, nil, nil, text.join(" ")))
        when CODE
          found.push(Note.new(type, nil, note["language"], text.join("\n")))
        else
          # A word this mechanism cannot word is a specification it could not
          # read, not a block to pass through unrendered.
          raise Error, "#{Where.of(path)} writes a note of type #{type}, " \
                       "which is none this document has; " \
                       "sumi help contract has the form"
        end
      end
      found
    end

    # A heading deeper than the page reaches would answer as text where it
    # stood, so the specification is refused rather than quietly flattened.
    def self.depth_of(path, level)
      return 1 if level.nil?
      return level if level >= 1 && level <= DEEPEST

      raise Error, "#{Where.of(path)} writes a heading at level #{level}, " \
                   "which is deeper than a page carries; " \
                   "sumi help contract has the form"
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

    # Whether the syntax tree reading could ever answer this name: a constant
    # path, a method, or one qualified by the other.
    def self.resolvable?(name)
      at = name.index("#")
      at = name.index(".") if at.nil?
      return named?(CONSTANT, name) || named?(METHOD, name) if at.nil?

      named?(CONSTANT, "#{name[0, at]}") && named?(METHOD, "#{name[(at + 1)..-1]}")
    end

    def self.named?(pattern, text)
      !pattern.match(text).nil?
    end

    # What a claim resolves against. The marker is part of it because it is the
    # namespace: `@command verify` and `@route verify` name different things.
    # The syntax tree reading has one namespace, Ruby's, which is what a
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
