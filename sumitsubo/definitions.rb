require "sumitsubo/error"
require "sumitsubo/where"
require "sumitsubo/grammar"

module Sumitsubo
  # What a piece of source declares, read from the syntax tree. Marker exists
  # because a route is not a Ruby construct and nothing but a comment can point
  # at one; a method is a construct, so it is found without being written down.
  #
  # A name is spelled the way Ruby spells it — `Sumitsubo::Where.of` for a
  # singleton method, `#` for an instance one, the bare path for a class or
  # module — because that is what a contract is named by.
  module Definitions
    class Error < Sumitsubo::Error; end

    # One parameter of a method: what it is called, how a caller has to pass
    # it, and whether it may be left out. A name is absent where Ruby lets the
    # parameter go unnamed.
    #
    # The kind words are Ruby's own and they stay on this side. A contract
    # compares them as text without knowing what any of them means, so a
    # second language brings its own vocabulary in its own reading rather than
    # negotiating a shared one with the specification.
    Param = Struct.new(:name, :kind, :optional)

    # A declaration and, where it is a method, the parameters it takes. A scope
    # carries none at all, which is not the same as a method that takes none.
    Name = Struct.new(:path, :line, :name, :params)

    # One match of the query below: what kind of node it was, what it is
    # called, and the lines it spans.
    Node = Struct.new(:kind, :text, :first, :last)

    NAME = "name"
    SCOPE = "scope"
    SINGLETON = "singleton"
    # `class << self` holds methods that belong to the class rather than to an
    # instance of it. It contributes no name of its own — what it changes is
    # how the methods inside it are spelled.
    REOPENED = "reopened"

    # The method a parameter belongs to, and the two captures that qualify one:
    # the name where Ruby gave it one, and the default that makes it optional.
    OF = "of"
    NAMED = "named"
    DEFAULT = "default"
    POSITIONAL = "positional"

    # Kinds a caller may always leave out: a splat gathers whatever is there,
    # a block is passed or not, and forwarding says nothing about what has to
    # arrive. Optionality is a fact about the call rather than about how Ruby
    # spells the definition, which is why these carry it without a default.
    OMISSIBLE = ["splat", "hash_splat", "block", "forward"]

    # `**nil` declares that no keyword argument is accepted rather than naming
    # a parameter, so nothing below reaches it and a method carrying one
    # answers only the parameters it takes.
    PARAMETERS = <<~PARAMETERS
      [(identifier) @positional
       (optional_parameter name: (_) @named value: (_) @default) @positional
       (keyword_parameter name: (_) @named value: (_)? @default) @keyword
       (splat_parameter name: (_)? @named) @splat
       (hash_splat_parameter name: (_)? @named) @hash_splat
       (block_parameter name: (_)? @named) @block
       (destructured_parameter) @destructured
       (forward_parameter) @forward]*
    PARAMETERS

    # A pattern reaches only its direct children and there is no operator for a
    # deeper one, so nesting is recovered from where the nodes sit rather than
    # from the query. That is what the whole node is captured for: its text is
    # the source slice, so its last line is the newlines in it.
    #
    # The quantifier below sits on the alternation while its branches carry
    # none, so tree-sitter answers one match per parameter rather than one
    # match whose captures vary in number. Each names the method it belongs to.
    QUERY = <<~QUERY
      (module name: (_) @name) @scope
      (class name: (_) @name) @scope
      (method name: (_) @name) @instance
      (singleton_method object: (self) name: (_) @name) @singleton
      (singleton_class value: (self) @name) @reopened
      (method name: (_) @of parameters: (method_parameters #{PARAMETERS}))
      (singleton_method object: (self) name: (_) @of
        parameters: (method_parameters #{PARAMETERS}))
    QUERY

    # Every name the file declares. Only Ruby has declarations to read, so
    # anything else in scope declares nothing rather than failing: the scope is
    # a filter, and a declaration is either there or not.
    def self.names_in(path)
      return [] unless path.end_with?(".rb")

      where = Where.of(path)
      matches = matches_in(path, where)
      nodes = nodes_in(matches)
      taken = params_in(matches)

      scopes = []
      reopened = []
      nodes.each do |node|
        scopes.push(node) if node.kind == SCOPE
        reopened.push(node) if node.kind == REOPENED
      end

      found = []
      nodes.each do |node|
        next if node.kind == REOPENED

        found.push(Name.new(
          where, node.first, qualified(scopes, reopened, node), params_for(taken, node)
        ))
      end
      found
    end

    # The name a contract would have to use to reach this node, its enclosing
    # scopes included.
    def self.qualified(scopes, reopened, node)
      holding = enclosing(scopes, node)
      return holding.push(node.text).join("::") if node.kind == SCOPE
      # A definition outside every scope is reached by its bare name: there is
      # no path to put in front of it.
      return node.text if holding.empty?

      "#{holding.join("::")}#{singleton?(reopened, node) ? "." : "#"}#{node.text}"
    end

    # Whether the method belongs to the class rather than to an instance of it,
    # by how it was written or by sitting inside a `class << self`.
    def self.singleton?(reopened, node)
      return true if node.kind == SINGLETON

      inside = false
      reopened.each do |scope|
        inside = true if scope.first <= node.first && node.last <= scope.last
      end
      inside
    end

    # The scopes holding this node, outermost first — which is also earliest
    # first, since one scope inside another opens after it.
    #
    # Two nodes spanning the same lines hold each other or are the same node,
    # and neither can be told from the other at this resolution. Answering with
    # no scope loses a prefix where a one-line `class A; class B; end; end`
    # nests; answering with both would invent one.
    def self.enclosing(scopes, node)
      holding = []
      scopes.each do |scope|
        next if scope.first == node.first && scope.last == node.last

        holding.push(scope) if scope.first <= node.first && node.last <= scope.last
      end
      holding.sort_by { |scope| scope.first }.map { |scope| scope.text }
    end

    # The captures of one match, grouped and left in the order the parser met
    # them: they arrive in node position rather than pattern order, which is
    # why the name each carries is what tells them apart.
    def self.matches_in(path, where)
      grouped = {}
      order = []
      captures_in(path, where).each do |capture|
        holding = grouped[capture.match]
        if holding.nil?
          holding = []
          grouped[capture.match] = holding
          order.push(capture.match)
        end
        holding.push(capture)
      end

      found = []
      order.each { |key| found.push(grouped[key]) }
      found
    end

    def self.nodes_in(matches)
      found = []
      matches.each do |captures|
        node = node_from(captures)
        found.push(node) unless node.nil?
      end
      found
    end

    # A match that declares nothing answers nothing: a parameter names the
    # method it belongs to rather than a name of its own, so it is passed over
    # here and read below.
    def self.node_from(captures)
      kind = nil
      text = nil
      first = 0
      last = 0
      captures.each do |capture|
        if capture.name == NAME
          text = capture.text
        else
          kind = capture.name
          first = capture.line
          last = capture.line + capture.text.count("\n")
        end
      end
      return nil if kind.nil? || text.nil?

      Node.new(kind, text, first, last)
    end

    # The parameters each method takes, in the order the source wrote them,
    # kept under the method they belong to.
    def self.params_in(matches)
      found = {}
      matches.each do |captures|
        of = named(captures, OF)
        next if of.nil?

        key = owner(of.line, of.text)
        holding = found[key]
        if holding.nil?
          holding = []
          found[key] = holding
        end
        param = param_from(captures)
        holding.push(param) unless param.nil?
      end
      found
    end

    # What a caller has to write for this parameter. A plain one is its own
    # name; every other kind carries the name in a capture of its own, or goes
    # unnamed where Ruby allows it.
    #
    # The guard on that fallback is what makes it hold either way round: a
    # parameter with a default is captured both as a kind and by name, and the
    # two arrive in node position rather than in the order they are written
    # above.
    def self.param_from(captures)
      kind = nil
      name = nil
      defaulted = false
      captures.each do |capture|
        next if capture.name == OF

        if capture.name == NAMED
          name = capture.text
        elsif capture.name == DEFAULT
          defaulted = true
        else
          kind = capture.name
          name = capture.text if capture.name == POSITIONAL && name.nil?
        end
      end
      return nil if kind.nil?

      Param.new(name, kind, defaulted || OMISSIBLE.include?(kind))
    end

    # What a declaration answers for its parameters: none at all for a scope,
    # and the list for a method, which is empty where it takes nothing.
    def self.params_for(taken, node)
      return nil if node.kind == SCOPE

      found = taken[owner(node.first, node.text)]
      found.nil? ? [] : found
    end

    # A method's name sits on the same line as `def`, so the line and the name
    # together are what tell two methods apart at the resolution the captures
    # carry.
    def self.owner(line, name)
      "#{line}\t#{name}"
    end

    def self.named(captures, name)
      found = nil
      captures.each { |capture| found = capture if capture.name == name }
      found
    end

    def self.captures_in(path, where)
      TreeSitter.capture(Grammar::RUBY, File.read(path), QUERY, where)
    rescue TreeSitter::ParseError => e
      # Source the grammar cannot read is not a difference between the two
      # sides: half a file declares names the rest of it never did.
      raise Error, e.message
    end
  end
end
