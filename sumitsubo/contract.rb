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

    # An interface is internal when the project means to keep it but not to
    # say so publicly. That is a fact about the interface, and the document it
    # stays out of follows from it — which is what makes it different from the
    # configuration switching a whole specification off.
    Interface = Struct.new(:name, :description, :path, :line, :internal)
    # A file's worth of contracts. The marker is the word source claims them
    # with, and two files may name the same one: a project splitting its routes
    # across files is registering more of one kind, not a second kind.
    Definition = Struct.new(:name, :description, :marker, :includes, :interfaces, :path)
    # An interface nothing claims. The scope is carried so the finding can say
    # where it looked rather than claiming no implementation exists anywhere.
    Finding = Struct.new(:path, :line, :name, :scope)
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
            Where.of(interface.path), interface.line, interface.name, definition.includes
          ))
        end
      end
      found
    end

    # An interface the syntax tree does not define. The specification
    # registers it and no source in scope defines it, which is the same
    # difference an unclaimed interface is — the other reading of it.
    def self.undefined(definitions, names)
      seen = {}
      names.each { |name| seen[name.name] = true }

      found = []
      defined(definitions).each do |definition|
        definition.interfaces.each do |interface|
          next unless seen[interface.name].nil?

          found.push(Finding.new(
            Where.of(interface.path), interface.line, interface.name, definition.includes
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
      "#{finding.name} is claimed nowhere in #{finding.scope.join(", ")}"
    end

    def self.describe_undefined(finding)
      "#{finding.name} is defined nowhere in #{finding.scope.join(", ")}"
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
    # interface is a name and what it is for, which is a table; the marker and
    # the include globs stay out, because they say how to find things rather
    # than what the contract means.
    def self.render(definition)
      lines = ["# #{definition.name || document_name(definition)}", ""]
      lines.push(definition.description, "") unless definition.description.nil?
      lines.push("| Contract | Description |", "| --- | --- |")
      # An internal interface is still verified; what it is kept out of is the
      # half of the specification a reader outside the project is handed.
      definition.interfaces.each do |interface|
        next if interface.internal

        lines.push("| #{cell(interface.name)} | #{cell(interface.description)} |")
      end
      lines.push("")
      lines.join("\n")
    end

    # What a definition is called on the document side: the file declaring it,
    # since one file there is one document here. It stands in for a definition
    # that named itself nothing.
    def self.document_name(definition)
      "#{Pathname.new(definition.path).basename(".json")}"
    end

    # A bar would end the cell it sits in, so it is spelled rather than left to
    # split the table.
    def self.cell(text)
      "#{text}".split("|").join("\\|")
    end

    def self.definition_from(path)
      text = File.read(path)
      document = parse(path, text)
      lines = Locations.of(text, NAME)

      # A definition naming no marker is read from the syntax tree, so there is
      # no word to look for and none is needed.
      marker = document["marker"]

      interfaces = []
      (document["contracts"] || []).each do |raw|
        name = raw["name"]
        raise Error, "#{Where.of(path)} declares a contract with no \"name\"" if name.nil?

        if marker.nil? && !resolvable?(name)
          raise Error, "#{Where.of(path)} names #{name}, which no Ruby definition can be"
        end

        interfaces.push(Interface.new(
          name, raw["description"], path, lines[name], raw["internal"] == true
        ))
      end

      Definition.new(
        document["name"],
        document["description"],
        marker,
        document["include"] || [],
        interfaces,
        path
      )
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
