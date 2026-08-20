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
  # Nothing here names the grammar. That is what lets this file's test run
  # under CRuby — see the Build section of CLAUDE.md for what --regen cannot
  # reach.
  module Contract
    DIRECTORY = "contract"

    # An interface's name as it sits in the raw text. JSON carries no line
    # numbers, and the finding for an interface nothing claims answers at the
    # specification that declares it.
    NAME = /"name"\s*:\s*"([^"]*)"/

    class Error < Sumitsubo::Error; end

    Interface = Struct.new(:name, :description, :path, :line)
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
      (Pathname.new(root) / DIRECTORY).to_s
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

    # Interpolated to settle the element type, as Glossary's globbing is.
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

    # The words source claims these contracts with, read in one pass.
    def self.keywords(definitions)
      found = []
      definitions.each { |definition| found.push(definition.marker) }
      found.uniq.sort
    end

    # An interface nothing claims: the specification registers it and no source
    # in scope says it was implemented, which is a difference between the two
    # sides.
    def self.unclaimed(definitions, claims)
      claimed = {}
      claims.each { |claim| claimed[key(claim.keyword, claim.name)] = true }

      found = []
      definitions.each do |definition|
        definition.interfaces.each do |interface|
          next unless claimed[key(definition.marker, interface.name)].nil?

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
      declared = declared_in(definitions)

      found = []
      claims.each { |claim| found.push(claim) if declared[key(claim.keyword, claim.name)].nil? }
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
      declared = declared_in(definitions)

      seen = {}
      claims.each do |claim|
        name = key(claim.keyword, claim.name)
        next if declared[name].nil?

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
    # shape. See the Output section of CLAUDE.md.
    def self.describe_unclaimed(finding)
      "#{finding.name} is claimed nowhere in #{finding.scope.join(", ")}"
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

    # The mechanism words its own document, as it words its own findings. An
    # interface is a name and what it is for, which is a table; the marker and
    # the include globs stay out, because they say how to find things rather
    # than what the contract means.
    def self.render(definition)
      lines = ["# #{definition.name || document_name(definition)}", ""]
      lines.push(definition.description, "") unless definition.description.nil?
      lines.push("| Contract | Description |", "| --- | --- |")
      definition.interfaces.each do |interface|
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

      marker = document["marker"]
      # Without a word to look for there is nothing to compare the contracts
      # against, which is a reference line that cannot be read rather than a
      # difference to report.
      raise Error, "#{Where.of(path)} declares no \"marker\"" if marker.nil?

      interfaces = []
      (document["contracts"] || []).each do |raw|
        name = raw["name"]
        raise Error, "#{Where.of(path)} declares a contract with no \"name\"" if name.nil?

        interfaces.push(Interface.new(name, raw["description"], path, lines[name]))
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
            raise Error, "#{name} is declared twice, at #{where} and #{at(interface)}"
          end

          seen[name] = at(interface)
        end
      end
    end

    def self.declared_in(definitions)
      declared = {}
      definitions.each do |definition|
        definition.interfaces.each { |interface| declared[key(definition.marker, interface.name)] = true }
      end
      declared
    end

    # What a claim resolves against. The marker is part of it because it is the
    # namespace: `@command verify` and `@route verify` name different things.
    def self.key(marker, name)
      "#{marker} #{name}"
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
