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

    Name = Struct.new(:path, :line, :name)

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

    # A pattern reaches only its direct children and there is no operator for a
    # deeper one, so nesting is recovered from where the nodes sit rather than
    # from the query. That is what the whole node is captured for: its text is
    # the source slice, so its last line is the newlines in it.
    QUERY = <<~QUERY
      (module name: (_) @name) @scope
      (class name: (_) @name) @scope
      (method name: (_) @name) @instance
      (singleton_method object: (self) name: (_) @name) @singleton
      (singleton_class value: (self) @name) @reopened
    QUERY

    # Every name the file declares. Only Ruby has declarations to read, so
    # anything else in scope declares nothing rather than failing: the scope is
    # a filter, and a declaration is either there or not.
    def self.names_in(path)
      return [] unless path.end_with?(".rb")

      where = Where.of(path)
      nodes = nodes_in(path, where)

      scopes = []
      reopened = []
      nodes.each do |node|
        scopes.push(node) if node.kind == SCOPE
        reopened.push(node) if node.kind == REOPENED
      end

      found = []
      nodes.each do |node|
        next if node.kind == REOPENED

        found.push(Name.new(where, node.first, qualified(scopes, reopened, node)))
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

    # The captures of one match describe one node, so they are read together:
    # they arrive in node position rather than pattern order, which is why the
    # name each carries is what tells them apart.
    def self.nodes_in(path, where)
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
      order.each do |key|
        node = node_from(grouped[key])
        found.push(node) unless node.nil?
      end
      found
    end

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

    def self.captures_in(path, where)
      TreeSitter.capture(Grammar::RUBY, File.read(path), QUERY, where)
    rescue TreeSitter::ParseError => e
      # Source the grammar cannot read is not a difference between the two
      # sides: half a file declares names the rest of it never did.
      raise Error, e.message
    end
  end
end
