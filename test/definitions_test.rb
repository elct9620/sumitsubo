require "sumitsubo/definitions"

# The part of reading a syntax tree that no language owns: captures grouped by
# the match they came from, made into nodes, and nested by where they sit.
#
# Nothing here reaches the binding — a capture is four fields and this file
# makes its own — so `--regen` can write the snapshot beside it.

Capture = Struct.new(:match, :name, :line, :text)

def node(kind, text, first, last)
  Sumitsubo::Definitions::Node.new(kind, text, first, last)
end

# Captures arrive in node position rather than pattern order, so the two
# matches below interleave and each still answers whole.
# @behavior D-016
puts "--- captures grouped by the match they came from ---"
Sumitsubo::Definitions.matches_in([
  Capture.new(1, "scope", 1, "class A\nend"),
  Capture.new(2, "instance", 4, "def go\nend"),
  Capture.new(1, "name", 1, "A"),
  Capture.new(2, "name", 4, "go")
]).each do |captures|
  spelled = []
  captures.each { |capture| spelled.push("#{capture.name}=#{capture.text.split("\n")[0]}") }
  puts "  #{spelled.join(" ")}"
end

# A match with no `name` capture declares nothing: a parameter names the method
# it belongs to rather than a name of its own. The node's last line is the
# newlines in the text it was captured with.
# @behavior D-017
puts "--- what those matches declare ---"
Sumitsubo::Definitions.nodes_in([
  [Capture.new(1, "scope", 1, "class A\n  def go\n  end\nend"), Capture.new(1, "name", 1, "A")],
  [Capture.new(2, "of", 2, "go"), Capture.new(2, "positional", 2, "at")]
]).each { |found| puts "  #{found.kind} #{found.text} #{found.first}-#{found.last}" }

# Nesting is recovered from where the nodes sit, because a pattern reaches only
# its direct children. Two spanning the same lines hold each other or are the
# same node, and neither can be told from the other here — so `Same` answers no
# scope rather than an invented one.
# @behavior D-018
puts "--- the nodes holding one, outermost first ---"
scopes = [node("scope", "Inner", 2, 5), node("scope", "Outer", 1, 8), node("scope", "Same", 3, 3)]
[node("instance", "go", 3, 3), node("instance", "away", 6, 6)].each do |held|
  holding = []
  Sumitsubo::Definitions.enclosing(scopes, held).each { |scope| holding.push(scope.text) }
  puts "  #{held.text}: #{holding.join(" > ")}"
end
