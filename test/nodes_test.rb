require "sumitsubo/source/language/nodes"

# The part of reading a syntax tree that no language owns: captures grouped by
# the match they came from, made into nodes, and nested by where they sit.
#
# Nothing here reaches the binding — this file makes its own captures — so
# `--regen` can write the snapshot beside it.

Capture = Struct.new(:match, :name, :line, :last, :start, :finish, :text)

# A capture as the binding hands one over. The lines a node spans are what the
# tree measured, stood in for here by the newlines in the slice; the byte it
# begins at is what tells two captures of one file apart, so it is written out
# where a case turns on it and stands at zero where none does.
def capture(match, name, line, text, start = 0)
  Capture.new(match, name, line, line + text.count("\n"), start, start + text.length, text)
end

def node(kind, text, first, last)
  Sumitsubo::Source::Language::Nodes::Node.new(kind, text, first, last)
end

# Captures arrive in node position rather than pattern order, so the two
# matches below interleave and each still answers whole.
# @behavior D-016
puts "--- captures grouped by the match they came from ---"
Sumitsubo::Source::Language::Nodes.matches_in([
  capture(1, "scope", 1, "class A\nend"),
  capture(2, "instance", 4, "def go\nend"),
  capture(1, "name", 1, "A"),
  capture(2, "name", 4, "go")
]).each do |captures|
  spelled = captures.map { |capture| "#{capture.name}=#{capture.text.split("\n")[0]}" }
  puts "  #{spelled.join(" ")}"
end

# A match with no `name` capture declares nothing: a parameter names the method
# it belongs to rather than a name of its own. The node's last line is the
# newlines in the text it was captured with.
# @behavior D-017
puts "--- what those matches declare ---"
Sumitsubo::Source::Language::Nodes.nodes_in([
  [capture(1, "scope", 1, "class A\n  def go\n  end\nend"), capture(1, "name", 1, "A")],
  [capture(2, "of", 2, "go"), capture(2, "positional", 2, "at")]
]).each { |found| puts "  #{found.kind} #{found.text} #{found.first}-#{found.last}" }

# Nesting is recovered from where the nodes sit, because a pattern reaches only
# its direct children. Two spanning the same lines hold each other or are the
# same node, and neither can be told from the other here — so `Same` answers no
# scope rather than an invented one.
# @behavior D-018
puts "--- the nodes holding one, outermost first ---"
scopes = [node("scope", "Inner", 2, 5), node("scope", "Outer", 1, 8), node("scope", "Same", 3, 3)]
[node("instance", "go", 3, 3), node("instance", "away", 6, 6)].each do |held|
  holding = Sumitsubo::Source::Language::Nodes.enclosing(scopes, held).map { |scope| scope.text }
  puts "  #{held.text}: #{holding.join(" > ")}"
end

# A query has no way to ask what a node is not, so which neighbours are
# themselves comments is answered by the set of comments the same query found —
# the byte each begins at being what says whether a neighbour is one of them.
# A comment with no neighbour captured at all ends its parent.
# @behavior D-021
puts "--- what each comment stands next to ---"
COMMENTS = [
  [capture(1, "any", 1, "# one", 0)],
  [capture(2, "any", 2, "# two", 10)],
  [capture(3, "any", 4, "# three", 40)],
  [capture(4, "text", 1, "# one", 0), capture(4, "next", 2, "# two", 10)],
  [capture(5, "text", 2, "# two", 10), capture(5, "next", 3, "def go", 20)]
]
standing = Sumitsubo::Source::Language::Nodes.following(COMMENTS)
standing.keys.sort.each { |at| puts "  #{at}: #{standing[at]}" }

# A match that qualifies a declaration rather than making one is gathered under
# it. The one naming no declaration is passed over; two naming one on the same
# line are below the resolution the captures carry, so their qualifiers merge —
# which is where this invents rather than loses.
# @behavior D-022
puts "--- the matches gathered under the declaration each names ---"
GROUPED = Sumitsubo::Source::Language::Nodes.grouped_by([
  [capture(1, "of", 2, "settle"), capture(1, "positional", 2, "at")],
  [capture(2, "scope", 1, "class A\nend"), capture(2, "name", 1, "A")],
  [capture(3, "of", 6, "settle"), capture(3, "keyword", 6, "note")],
  [capture(4, "of", 2, "settle"), capture(4, "block", 2, "held")]
], "of")
GROUPED.keys.sort.each do |key|
  spelled = GROUPED[key].map { |captures| captures.map { |one| one.name }.join("+") }
  puts "  #{key.split("\t").join(":")} #{spelled.join(" ")}"
end
