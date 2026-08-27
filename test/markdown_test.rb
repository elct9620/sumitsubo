require "sumitsubo/parser/markdown"

# Reading a Markdown specification into a feature and its scenarios: the part
# of that work no grammar owns.
#
# The grammar is handed in, so this test hands in one that answers with what it
# was given. Nothing here reaches the binding, which is what lets `--regen`
# write the snapshot beside it. Each case below is one way a document drifts
# out of shape, written on its own so what it pins can be read off it.

Capture = Struct.new(:match, :name, :line, :text)

# A grammar that answers whatever a case handed it. What a real one answers for
# a real document is pinned where the binding is, and this file is free of it.
class Canned
  def initialize(captures)
    @captures = captures
  end

  def captures_in(grammar, path, query, where)
    @captures
  end
end

def h1(line, text) = Capture.new(0, "h1", line, text)
def h2(line, text) = Capture.new(0, "h2", line, text)
def h3(line, text) = Capture.new(0, "h3", line, text)
def paragraph(line, text) = Capture.new(0, "paragraph", line, text)
def item(line, text) = Capture.new(0, "item", line, text)
def row(line, text) = Capture.new(0, "row", line, text)
def cell(line, text) = Capture.new(0, "cell", line, text)

def steps_of(scenario)
  steps = scenario.attributes
  steps.keys.each { |name| said(name, steps[name]) }
end

def said(name, holding)
  holding.each { |one| puts "    #{name} #{one}" }
end

def read(captures)
  Sumitsubo::Parser::Markdown.new(Canned.new(captures)).behavior("init.md")
rescue Sumitsubo::Unreadable => e
  puts "  refused: #{e.message}"
  nil
end

# @behavior MD-001
puts "--- a feature, its scope, and one scenario ---"
feature = read([
  h1(1, "Init"),
  paragraph(3, "What init lays down\nto start a reference line from."),
  h2(5, "Includes"),
  item(7, "`test/init_test.rb`"),
  item(8, "`test/other_test.rb`"),
  h2(10, "`I-001` The first run lays down an empty glossary"),
  row(14, "| Given | a directory with no specification |"),
  cell(14, "Given "),
  cell(14, "a directory with no specification "),
  row(15, "| When | `sumi init` runs |"),
  cell(15, "When "),
  cell(15, "`sumi init` runs "),
  row(16, "| Then | an empty glossary is written |"),
  cell(16, "Then "),
  cell(16, "an empty glossary is written ")
])
puts "#{feature.key} #{feature.includes.inspect}"
puts "  #{feature.text}"
feature.statements.each do |scenario|
  puts "  #{scenario.path}:#{scenario.line} #{scenario.key} #{scenario.text}"
  steps_of(scenario)
end

# A paragraph wrapped for a reader says what an unwrapped one says, which is
# what lets the same words be written either way in either format.
# @behavior MD-002
puts "--- a soft line break is a space ---"
puts read([h1(1, "Init"), paragraph(3, "one\n  two\nthree")]).text

# Two Given rows are two states, and a step nobody wrote is no step rather than
# an empty one.
# @behavior MD-003
puts "--- a scenario stating two Givens and no Then ---"
read([
  h1(1, "Init"),
  h2(3, "`I-002` A second run"),
  row(5, "| Given | a directory |"), cell(5, "Given "), cell(5, "a directory "),
  row(6, "| Given | a glossary already there |"),
  cell(6, "Given "), cell(6, "a glossary already there "),
  row(7, "| When | `sumi init` runs |"), cell(7, "When "), cell(7, "`sumi init` runs ")
]).statements.each { |scenario| puts "  #{scenario.attributes.inspect}" }

# The title is the whole heading, so a scenario's own title is whatever follows
# its id — and a scenario with nothing after the id has none.
# @behavior MD-004
puts "--- an id with no title after it ---"
read([h1(1, "Init"), h2(3, "`I-003`")]).statements.each do |scenario|
  puts "  #{scenario.key} #{scenario.text.inspect}"
end

# Prose under a scenario is prose. Only the paragraph under the title says what
# the feature is for, so a note written further down does not replace it.
# @behavior MD-005
puts "--- a paragraph under a scenario is passed over ---"
noted = read([
  h1(1, "Init"),
  paragraph(3, "What init lays down."),
  h2(5, "`I-004` A run"),
  paragraph(7, "Something a reader wanted said.")
])
puts "  #{noted.text}"

# A level this reading has no use for is prose, the same as a paragraph under a
# scenario. Three readings meet in one query, so a feature is handed the levels
# a vocabulary states its terms at and passes over the ones it does not read.
# @behavior MD-018
puts "--- a level this reading does not read is prose ---"
read([
  h1(1, "Contract"),
  paragraph(3, "What the mechanism establishes."),
  h3(5, "Verification runs one way"),
  paragraph(7, "An interface nothing claims is a difference."),
  h2(9, "`T-001` An interface nothing claims")
]).statements.each { |scenario| puts "  #{scenario.key} #{scenario.text}" }

# @behavior MD-006
puts "--- a heading that does not open with an id ---"
read([h1(1, "Init"), h2(3, "The first run")])

# @behavior MD-007
puts "--- an id in backticks that is empty ---"
read([h1(1, "Init"), h2(3, "`` the first run")])

# @behavior MD-008
puts "--- an include that is not a glob in backticks ---"
read([h1(1, "Init"), h2(3, "Includes"), item(5, "test/init_test.rb")])

# @behavior MD-009
puts "--- a step row that lost a separator ---"
read([
  h1(1, "Init"), h2(3, "`I-005` A run"),
  row(5, "| Given a directory |"), cell(5, "Given a directory ")
])

# @behavior MD-010
puts "--- a step row carrying an unescaped separator ---"
read([
  h1(1, "Init"), h2(3, "`I-006` A run"),
  row(5, "| Given | a directory | and a glossary |"),
  cell(5, "Given "), cell(5, "a directory "), cell(5, "and a glossary ")
])

# @behavior MD-011
puts "--- a row naming something that is not a step ---"
read([
  h1(1, "Init"), h2(3, "`I-007` A run"),
  row(5, "| Where | a directory |"), cell(5, "Where "), cell(5, "a directory ")
])

# @behavior MD-012
puts "--- a step before any scenario ---"
read([
  h1(1, "Init"),
  row(3, "| Given | a directory |"), cell(3, "Given "), cell(3, "a directory ")
])

# @behavior MD-013
puts "--- a document with no title ---"
read([paragraph(1, "What init lays down.")])

# @behavior MD-014
puts "--- a document with two titles ---"
read([h1(1, "Init"), h1(3, "Verify")])

# The extension is the whole of what says a file is written this way, so a
# parser is asked rather than told.
# @behavior MD-016
puts "--- which files this parser answers for ---"
parser = Sumitsubo::Parser::Markdown.new(Canned.new([]))
p [parser.reads?("init.md"), parser.reads?("init.json"), parser.reads?(".spec/behavior/init.md")]
