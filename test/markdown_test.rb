require "sumitsubo/specification/builder/behavior"
require "sumitsubo/specification/builder/contract"
require "sumitsubo/specification/builder/glossary"
require "sumitsubo/source"

# What a form makes of the blocks a document is made of: the part of reading a
# specification that no grammar owns.
#
# The blocks are written out here rather than read from a file, which is what
# lets `--regen` write the snapshot beside it — nothing reaches the binding.
# Each case below is one way a document drifts out of shape, written on its own
# so what it pins can be read off it.

BLOCK = Sumitsubo::Specification::Block
SPAN = Sumitsubo::Specification::Span

# The runs a document marked as taken letter for letter, stood in for the way a
# canned grammar stood in for the tree: a case writes the text a reader wrote,
# and the marks in it say where the runs are. The offsets count bytes, since
# that is what a block is sliced by.
def spans_in(text)
  found = []
  at = 0
  while true
    opened = text.index("`", at)
    break if opened.nil?

    closed = text.index("`", opened + 1)
    break if closed.nil?

    found.push(SPAN.new(text[(opened + 1)...closed], text[0...opened].bytesize,
                        text[0...(closed + 1)].bytesize))
    at = closed + 1
  end
  found
end

# A soft line break is a space before a form ever sees it, so a case may wrap a
# paragraph the way a reader would and still hand over what the parser hands
# over. That folding is pinned where a real document is read.
def block(kind, level, line, text)
  said = text.split("\n").map { |one| one.strip }.join(" ")
  BLOCK.new(kind, level, line, said, nil, spans_in(said), [])
end

def h1(line, text) = block(BLOCK::HEADING, 1, line, text)
def h2(line, text) = block(BLOCK::HEADING, 2, line, text)
def h3(line, text) = block(BLOCK::HEADING, 3, line, text)
def h4(line, text) = block(BLOCK::HEADING, 4, line, text)
def paragraph(line, text) = block(BLOCK::PARAGRAPH, 0, line, text)
def item(line, text) = block(BLOCK::ITEM, 1, line, text)
def nested(line, text) = block(BLOCK::ITEM, 2, line, text)
def row(line, text) = block(BLOCK::ROW, 0, line, text)
def cell(line, text) = block(BLOCK::CELL, 0, line, text)

# A row carries its cells and a fenced block its language and content, so a case
# writes them in the order a reader would and this gathers them the way a parser
# hands them over.
def document(blocks)
  found = []
  blocks.each { |one| gathered(found, one) }
  found
end

def gathered(found, one)
  return found.push(one) if found.empty?

  holding = found[-1]
  return holding.cells.push(one) if one.kind == BLOCK::CELL && holding.kind == BLOCK::ROW
  return holding.language = one.text if one.kind == "language" && holding.kind == BLOCK::CODE
  return holding.text = one.text if one.kind == "content" && holding.kind == BLOCK::CODE

  found.push(one)
end

def steps_of(scenario)
  steps = scenario.attributes
  steps.keys.each { |name| printed(name, steps[name]) }
end

def printed(name, holding)
  holding.each { |one| puts "    #{name} #{one}" }
end

def read(blocks)
  Sumitsubo::Specification::Builder::Behavior.new("init.md").build(document(blocks))
rescue Sumitsubo::Unreadable => e
  puts "  refused: #{e.message}"
  nil
end

# @behavior F-001
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
puts "#{feature.key} #{feature.includes.map { |one| one.key }.inspect}"
puts "  #{feature.text}"
feature.statements.each do |scenario|
  puts "  #{scenario.path}:#{scenario.line} #{scenario.key} #{scenario.text}"
  steps_of(scenario)
end

# Two Given rows are two states, and a step nobody wrote is no step rather than
# an empty one.
# @behavior F-002
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
# @behavior F-003
puts "--- an id with no title after it ---"
read([h1(1, "Init"), h2(3, "`I-003`")]).statements.each do |scenario|
  puts "  #{scenario.key} #{scenario.text.inspect}"
end

# Prose under a scenario is prose. Only the paragraph under the title says what
# the feature is for, so a note written further down does not replace it.
# @behavior F-004
puts "--- a paragraph under a scenario is passed over ---"
noted = read([
  h1(1, "Init"),
  paragraph(3, "What init lays down."),
  h2(5, "`I-004` A run"),
  paragraph(7, "Something a reader wanted said.")
])
puts "  #{noted.text}"

# @behavior F-005
puts "--- a heading that does not open with an id ---"
read([h1(1, "Init"), h2(3, "The first run")])

# @behavior F-006
puts "--- an id in backticks that is empty ---"
read([h1(1, "Init"), h2(3, "`` the first run")])

# @behavior F-007
puts "--- an include that is not a glob in backticks ---"
read([h1(1, "Init"), h2(3, "Includes"), item(5, "test/init_test.rb")])

# @behavior F-008
puts "--- a step row that lost a separator ---"
read([
  h1(1, "Init"), h2(3, "`I-005` A run"),
  row(5, "| Given a directory |"), cell(5, "Given a directory ")
])

# @behavior F-009
puts "--- a step row carrying an unescaped separator ---"
read([
  h1(1, "Init"), h2(3, "`I-006` A run"),
  row(5, "| Given | a directory | and a glossary |"),
  cell(5, "Given "), cell(5, "a directory "), cell(5, "and a glossary ")
])

# @behavior F-010
puts "--- a row naming something that is not a step ---"
read([
  h1(1, "Init"), h2(3, "`I-007` A run"),
  row(5, "| Where | a directory |"), cell(5, "Where "), cell(5, "a directory ")
])

# @behavior F-011
puts "--- a step before any scenario ---"
read([
  h1(1, "Init"),
  row(3, "| Given | a directory |"), cell(3, "Given "), cell(3, "a directory ")
])

# @behavior F-012
puts "--- a document with no title ---"
read([paragraph(1, "What init lays down.")])

# @behavior F-013
puts "--- a document with two titles ---"
read([h1(1, "Init"), h1(3, "Verify")])

# --- a vocabulary --------------------------------------------------------
#
# One file is one specification here as it is for the other two forms; the
# tree under it is deeper, which is the whole of the difference.

VOCABULARY = "test/fixtures/specification/forms/glossary.md"

def vocabulary(blocks)
  Sumitsubo::Specification::Builder::Glossary.new(VOCABULARY).build(document(blocks))
rescue Sumitsubo::Unreadable => e
  puts "  refused: #{e.message}"
  nil
end

# A rejected word answers a line of its own, which is what the mechanism sets
# a finding aside by: the specification spelling a word is not a use of it.
def said_of(spec)
  puts "#{spec.key} #{spec.text.inspect}"
  spec.statements.each do |section|
    puts "  #{section.key} #{section.includes.map { |one| one.key }.inspect} #{section.text.inspect}"
    section.statements.each do |term|
      puts "    #{term.path}:#{term.line} #{term.key} — #{term.text}"
      term.statements.each do |word|
        puts "      #{word.line} rejects #{word.key} — #{word.text}"
        word.statements.each { |ignore| puts "        #{ignore.line} #{ignore.key} — #{ignore.text}" }
      end
    end
  end
end

# @behavior F-014
puts "--- a vocabulary read into sections, terms and the words they reject ---"
said_of(vocabulary([
  h1(1, "Glossary"),
  paragraph(3, "Prose above every section."),
  h2(5, "Everywhere"),
  paragraph(7, "What this section is for."),
  h3(9, "Includes"),
  item(11, "`app/**/*.rb`"),
  h3(13, "Order"),
  paragraph(15, "What a customer asks us to fulfil."),
  h4(17, "Rejected"),
  item(19, "`Purchase` — Order is what the domain calls it."),
  nested(20, "`app/legacy_import.rb:88` — Quotes the upstream column name."),
  h2(22, "Billing"),
  h3(24, "Includes"),
  item(26, "`app/billing/*.rb`"),
  h3(28, "Order"),
  paragraph(30, "The billable set of lines.")
]))

# A subdomain is a section like any other, so two of them declaring one term is
# what the mechanism lays over rather than an ambiguity to refuse.
# @behavior F-015
puts "--- two sections declaring one term ---"
p vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"),
  h2(7, "Billing"), h3(9, "Order")
]).statements.map { |section| [section.key, section.statements.map { |term| term.key }] }

# The separator is what a reader puts there and `fmt` is what keeps it there,
# so the reason reads the same whether or not it was written.
# @behavior F-016
puts "--- a rejected word written with and without the separator ---"
vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"), h4(7, "Rejected"),
  item(9, "`Purchase` — Order is what the domain calls it."),
  item(10, "`Buy` Order is what the domain calls it."),
  item(11, "`Acquire`")
]).statements[0].statements[0].statements.each { |word| puts "  #{word.key} #{word.text.inspect}" }

# @behavior F-017
puts "--- a term written under no section ---"
vocabulary([h1(1, "Glossary"), h3(3, "Order")])

# A title is what says the document is a vocabulary at all, so one declaring
# no section is a vocabulary that checks nothing rather than a document read
# as the wrong kind.
# @behavior F-019
puts "--- a vocabulary declaring no section checks nothing ---"
said_of(vocabulary([h1(1, "Glossary"), paragraph(3, "Prose and nothing else.")]))

# @behavior F-018
puts "--- a document that never says it is a vocabulary ---"
vocabulary([h2(1, "Everywhere"), h3(3, "Order")])

# @behavior F-020
puts "--- a heading under a term that is not Rejected ---"
vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"), h4(7, "Rejcted")
])

# @behavior F-021
puts "--- Rejected written under no term ---"
vocabulary([h1(1, "Glossary"), h2(3, "Everywhere"), h4(5, "Rejected")])

# @behavior F-022
puts "--- a rejected word that is not in backticks ---"
vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"), h4(7, "Rejected"),
  item(9, "Purchase — Order is what the domain calls it.")
])

# A word with nothing between the marks is nothing taken letter for letter, so
# it would match everywhere or nowhere; the mechanism must never be handed one.
# @behavior F-023
puts "--- a rejected word with nothing between the marks ---"
vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"), h4(7, "Rejected"),
  item(9, "`` — Order is what the domain calls it.")
])

# @behavior F-024
puts "--- an ignore written under no rejected word ---"
vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"), h4(7, "Rejected"),
  nested(9, "`app/order.rb:2` — Quotes the upstream column name.")
])

# @behavior F-025
puts "--- an ignore with nothing to say why ---"
vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"), h4(7, "Rejected"),
  item(9, "`Purchase` — Order is what the domain calls it."),
  nested(10, "`app/order.rb:2`")
])

# A list under a term but above Rejected is prose, the same as a paragraph
# under a scenario: only the reserved heading says a list declares something.
# @behavior F-026
puts "--- a list a reserved heading does not open is prose ---"
p vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"),
  item(7, "one the definition wanted to list"),
  nested(8, "and one under it")
]).statements[0].statements[0].statements

# --- a definition --------------------------------------------------------
#
# A definition is read one of two ways and the reserved heading naming a marker
# is the only thing telling them apart. What the languages answer is the kind
# of specification's to ask, so a stand-in carries just enough to be asked.

#
# What a signature declares is a reading's answer, so it is handed in the way
# the captures are: a real reading is put to a real fence where the binding is,
# and what the rules below turn on is what came back.
# A scope carries no parameters at all, which is how a signature's nesting is
# told from the contract it holds. Where a fence's declaration sits is not
# what these rules turn on, so the two the builder reads are the two written.
def scope(name) = Sumitsubo::Source::Declaration.new(nil, nil, name, nil)
def declares(name) = Sumitsubo::Source::Declaration.new(nil, nil, name, [])

class Spelling
  def initialize(answers)
    @answers = answers
  end

  def carries?(language)
    language == "ruby" || language == "rust"
  end

  def declarations_of(source, where, language)
    found = @answers[source]
    raise Sumitsubo::Error, "#{where}: cannot be parsed by the #{language} grammar" if found == :unreadable

    found.nil? ? [] : found
  end
end

def fence(line, text) = BLOCK.new(BLOCK::CODE, 0, line, "", nil, [], [])
def language(line, text) = BLOCK.new("language", 0, line, text, nil, [], [])
def content(line, text) = BLOCK.new("content", 0, line, text, nil, [], [])

def definition(blocks, answers = {})
  Sumitsubo::Specification::Builder::Contract.new("cli.md", Spelling.new(answers)).build(document(blocks))
rescue Sumitsubo::Unreadable => e
  puts "  refused: #{e.message}"
  nil
end

def registered_by(spec)
  puts "#{spec.key} #{spec.attributes.inspect} #{spec.includes.map { |one| one.key }.inspect}"
  puts "  #{spec.text}"
  spec.statements.each do |contract|
    puts "  #{contract.path}:#{contract.line} #{contract.key} #{contract.attributes.inspect}"
    puts "    #{contract.text}"
  end
end

# @behavior F-027
puts "--- a definition whose contracts source claims in a comment ---"
registered_by(definition([
  h1(1, "CLI"),
  paragraph(3, "The commands `sumi` answers."),
  h2(5, "Includes"),
  item(7, "`sumitsubo/command/*.rb`"),
  h2(9, "Marker"),
  paragraph(11, "`@command`"),
  h2(13, "`init`"),
  paragraph(15, "Lay down an empty specification."),
  fence(17, "```console\n$ sumi init\n```"),
  language(17, "console"),
  content(18, "$ sumi init\n")
]))

# A signature says which language spells the name it registers, so one
# definition may register contracts in two of them without either being wrong.
# @behavior F-028
puts "--- a definition whose contracts the syntax tree declares ---"
WHERE = "module Sumitsubo::Place\n  def self.of(path)\n  end\nend\n"
INIT = "def init\nend\n"
HANDLE = "mod store {\n    pub struct Handle;\n}\n"

registered_by(definition([
  h1(1, "Internal seams"),
  paragraph(3, "The places this project keeps to one implementation."),
  h2(5, "`Sumitsubo::Place.of`"),
  paragraph(7, "The one place a path a reader is handed is made."),
  row(11, "| internal | yes |"), cell(11, "internal "), cell(11, "yes "),
  fence(13, "```ruby\n#{WHERE}```"),
  language(13, "ruby"),
  content(14, WHERE),
  h2(20, "`store::Handle`"),
  fence(22, "```rust\n#{HANDLE}```"),
  language(22, "rust"),
  content(23, HANDLE)
], {
  WHERE => [scope("Sumitsubo::Place"), declares("Sumitsubo::Place.of")],
  HANDLE => [scope("store"), declares("store::Handle")]
}))

# @behavior F-029
puts "--- a contract heading that does not open with a name ---"
definition([h1(1, "CLI"), h2(3, "the first command")])

# A name in backticks with a word in front of it opens with the word, so it is
# the same heading as one carrying no name at all.
# @behavior F-029
puts "--- a contract heading opening with a word before the name ---"
definition([h1(1, "CLI"), h2(3, "the `init` command")])

# A run in backticks after the name is the form this one replaced, so it is
# answered by the rule that leaves a heading carrying the name alone rather
# than by a rule of its own.
# @behavior F-031
puts "--- prose written after a contract's name ---"
definition([h1(1, "CLI"), h2(3, "`init` lays down a specification")])

# @behavior F-031
puts "--- a second run in backticks after a contract's name ---"
definition([h1(1, "CLI"), h2(3, "`init` `internal`")])

# The heading and delimiter rows a reader writes are no rows of the grammar's,
# so a table states as many attributes as it has rows under them.
# @behavior F-045
puts "--- a table stating one attribute of a contract ---"
registered_by(definition([
  h1(1, "CLI"),
  h2(3, "`init`"),
  row(7, "| internal | yes |"), cell(7, "internal "), cell(7, "yes "),
  fence(9, "```ruby\n#{INIT}```"),
  language(9, "ruby"),
  content(10, INIT)
], { INIT => [declares("init")] }))

# @behavior F-030
puts "--- an attribute a contract does not carry ---"
definition([
  h1(1, "CLI"), h2(3, "`init`"),
  row(7, "| hidden | yes |"), cell(7, "hidden "), cell(7, "yes ")
])

# @behavior F-046
puts "--- an attribute given a value it does not take ---"
definition([
  h1(1, "CLI"), h2(3, "`init`"),
  row(7, "| internal | no |"), cell(7, "internal "), cell(7, "no ")
])

# @behavior F-047
puts "--- an attribute row standing under no contract ---"
definition([
  h1(1, "CLI"),
  row(5, "| internal | yes |"), cell(5, "internal "), cell(5, "yes ")
])

# @behavior F-048
puts "--- an attribute row that lost a separator ---"
definition([
  h1(1, "CLI"), h2(3, "`init`"),
  row(7, "| internal yes |"), cell(7, "internal yes ")
])

# @behavior F-049
puts "--- one attribute written twice ---"
definition([
  h1(1, "CLI"), h2(3, "`init`"),
  row(7, "| internal | yes |"), cell(7, "internal "), cell(7, "yes "),
  row(8, "| internal | yes |"), cell(8, "internal "), cell(8, "yes ")
])

# @behavior F-032
puts "--- a marker named after a contract has already been registered ---"
definition([h1(1, "CLI"), h2(3, "`init`"), h2(5, "Marker"), paragraph(7, "`@command`")])

# @behavior F-033
puts "--- a marker heading with no word under it ---"
definition([h1(1, "CLI"), h2(3, "Marker"), h2(5, "`init`")])

# @behavior F-034
puts "--- a contract the syntax tree reading is given no signature for ---"
definition([h1(1, "Seams"), h2(3, "`Store.open`"), paragraph(5, "A seam.")])

# @behavior F-035
puts "--- a signature whose fence names no language ---"
definition([
  h1(1, "Seams"), h2(3, "`Store.open`"),
  fence(5, "```\ndef self.open(path)\n```"), content(6, "def self.open(path)\n")
])

# @behavior F-036
puts "--- a signature in a language this build does not carry ---"
definition([
  h1(1, "Seams"), h2(3, "`Store.open`"),
  fence(5, "```cobol\nOPEN INPUT STORE.\n```"), language(5, "cobol"), content(6, "OPEN INPUT STORE.\n")
])

# The signature is what says the name is one a definition could carry, so the
# name it declares is the name being registered. A fence writing its nesting out
# is what makes `Store.open` that name rather than `open`.
# @behavior F-037
puts "--- a signature declaring another name ---"
definition([
  h1(1, "Seams"), h2(3, "`Store.open`"),
  fence(5, "```ruby\ndef open(path)\nend\n```"), language(5, "ruby"),
  content(6, "def open(path)\nend\n")
], { "def open(path)\nend\n" => [declares("open")] })

# A signature declares the one contract and the scopes holding it, so anything
# else in the fence is a second contract nothing registers.
# @behavior F-038
puts "--- a signature declaring a second contract ---"
TWO = "module Store\n  def self.open(path)\n  end\n\n  def self.close(dir)\n  end\nend\n"
definition([
  h1(1, "Seams"), h2(3, "`Store.open`"),
  fence(5, "```ruby\n#{TWO}```"), language(5, "ruby"), content(6, TWO)
], { TWO => [scope("Store"), declares("Store.open"), declares("Store.close")] })

# A scope only sharing the start of the name does not hold it, so the name has
# to end where the contract's own goes on.
NEAR = "module Store\nend\n\nmodule StoreAdmin\n  def self.open(path)\n  end\nend\n"
definition([
  h1(1, "Seams"), h2(3, "`StoreAdmin.open`"),
  fence(5, "```ruby\n#{NEAR}```"), language(5, "ruby"), content(6, NEAR)
], { NEAR => [scope("Store"), scope("StoreAdmin"), declares("StoreAdmin.open")] })

# @behavior F-039
puts "--- a signature the reading cannot read ---"
definition([
  h1(1, "Seams"), h2(3, "`Store.open`"),
  fence(5, "```ruby\ndef self.open(path\n```"), language(5, "ruby"),
  content(6, "def self.open(path\n")
], { "def self.open(path\n" => :unreadable })

# @behavior F-040
puts "--- a document that names nothing ---"
definition([h2(1, "`init`")])

# Under a marker every fence is prose, so a second one under a contract is too
# — and under the other reading only the first is the signature.
# @behavior F-041
puts "--- a second fence under one contract ---"
OPEN = "module Store\n  def self.open(path)\n  end\nend\n"
definition([
  h1(1, "Seams"), h2(3, "`Store.open`"),
  fence(5, "```ruby\n#{OPEN}```"), language(5, "ruby"), content(6, OPEN),
  fence(12, "```ruby\nStore.open('a')\n```"), language(12, "ruby"), content(13, "Store.open('a')\n")
], { OPEN => [scope("Store"), declares("Store.open")] })
  .statements.each { |contract| puts "  #{contract.key} #{contract.attributes.inspect}" }

# --- what a specification answers for ------------------------------------
#
# Every kind lists its includes under the reserved heading and they differ only
# in which level that heading sits at, so each form reads its own. A glob
# carries the line it was written on, which is where a reader goes when it
# turns out to cover nothing.

def globs_of(container)
  container.includes.map { |one| "#{one.line} #{one.key}" }
end

def sections_of(spec)
  spec.statements.each { |section| puts "  #{section.key} #{globs_of(section).inspect}" }
end

# @behavior F-042
puts "--- includes written at the level a feature writes them ---"
p globs_of(read([
  h1(1, "Init"), h2(3, "Includes"), item(5, "`test/init_test.rb`"), item(6, "`test/other_test.rb`"),
  h2(8, "`I-001` A run"), item(10, "`not an include`")
]))

# @behavior F-043
puts "--- includes written at the level a vocabulary writes them ---"
sections_of(vocabulary([
  h1(1, "Glossary"),
  h2(3, "Everywhere"), h3(5, "Includes"), item(7, "`app/**/*.rb`"),
  h3(9, "Order"), item(11, "`not an include`"),
  h2(13, "Billing"), h3(15, "Includes"), item(17, "`app/billing/*.rb`")
]))

# Two sections naming one glob each keep their own: a boundary is the section's,
# and a reader sent to fix one has to be sent to the section that wrote it.
# @behavior F-044
puts "--- one glob written twice ---"
sections_of(vocabulary([
  h1(1, "Glossary"),
  h2(3, "Everywhere"), h3(5, "Includes"), item(7, "`app/**/*.rb`"),
  h2(9, "Billing"), h3(11, "Includes"), item(13, "`app/**/*.rb`")
]))
