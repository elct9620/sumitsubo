require "sumitsubo/specification/parser/markdown"
require "sumitsubo/source"

# Reading a Markdown specification into a feature and its scenarios: the part
# of that work no grammar owns.
#
# The grammar is handed in, so this test hands in one that answers with what it
# was given. Nothing here reaches the binding, which is what lets `--regen`
# write the snapshot beside it. Each case below is one way a document drifts
# out of shape, written on its own so what it pins can be read off it.

Capture = Struct.new(:match, :name, :line, :last, :start, :finish, :text)

# A capture as the binding hands one over. What the tree measures is stood in
# for here: the lines a block spans are its own newlines, and the bytes are the
# text's own extent, since a case hands over one block rather than a document.
def capture(name, line, text)
  Capture.new(0, name, line, line + text.count("\n"), 0, text.length, text)
end

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

def h1(line, text) = capture("h1", line, text)
def h2(line, text) = capture("h2", line, text)
def h3(line, text) = capture("h3", line, text)
def h4(line, text) = capture("h4", line, text)
def paragraph(line, text) = capture("paragraph", line, text)
def item(line, text) = capture("item", line, text)
def nested(line, text) = capture("nested", line, text)
def row(line, text) = capture("row", line, text)
def cell(line, text) = capture("cell", line, text)

def steps_of(scenario)
  steps = scenario.attributes
  steps.keys.each { |name| said(name, steps[name]) }
end

def said(name, holding)
  holding.each { |one| puts "    #{name} #{one}" }
end

def read(captures)
  Sumitsubo::Specification::Parser::Markdown.new(Canned.new(captures)).behavior("init.md")
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
puts "#{feature.key} #{feature.includes.map { |one| one.key }.inspect}"
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
parser = Sumitsubo::Specification::Parser::Markdown.new(Canned.new([]))
p [parser.reads?("init.md"), parser.reads?("init.json"), parser.reads?(".spec/behavior/init.md")]

# --- a vocabulary --------------------------------------------------------
#
# One file is one specification here as it is for the other two forms; the
# tree under it is deeper, which is the whole of the difference. The path names
# a file that is really there, because a vocabulary nobody wrote is refused
# before any block is read.

VOCABULARY = "test/fixtures/reading/glossary.md"

def vocabulary(captures)
  Sumitsubo::Specification::Parser::Markdown.new(Canned.new(captures)).glossary(VOCABULARY)
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

# @behavior MD-019
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
# @behavior MD-020
puts "--- two sections declaring one term ---"
p vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"),
  h2(7, "Billing"), h3(9, "Order")
]).statements.map { |section| [section.key, section.statements.map { |term| term.key }] }

# The separator is what a reader puts there and `fmt` is what keeps it there,
# so the reason reads the same whether or not it was written.
# @behavior MD-021
puts "--- a rejected word written with and without the separator ---"
vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"), h4(7, "Rejected"),
  item(9, "`Purchase` — Order is what the domain calls it."),
  item(10, "`Buy` Order is what the domain calls it."),
  item(11, "`Acquire`")
]).statements[0].statements[0].statements.each { |word| puts "  #{word.key} #{word.text.inspect}" }

# @behavior MD-022
puts "--- a term written under no section ---"
vocabulary([h1(1, "Glossary"), h3(3, "Order")])

# A title is what says the document is a vocabulary at all, so one declaring
# no section is a vocabulary that checks nothing rather than a document read
# as the wrong kind.
# @behavior MD-052
puts "--- a vocabulary declaring no section checks nothing ---"
said_of(vocabulary([h1(1, "Glossary"), paragraph(3, "Prose and nothing else.")]))

# @behavior MD-023
puts "--- a document that never says it is a vocabulary ---"
vocabulary([h2(1, "Everywhere"), h3(3, "Order")])

# @behavior MD-024
puts "--- a heading under a term that is not Rejected ---"
vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"), h4(7, "Rejcted")
])

# @behavior MD-025
puts "--- Rejected written under no term ---"
vocabulary([h1(1, "Glossary"), h2(3, "Everywhere"), h4(5, "Rejected")])

# @behavior MD-026
puts "--- a rejected word that is not in backticks ---"
vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"), h4(7, "Rejected"),
  item(9, "Purchase — Order is what the domain calls it.")
])

# @behavior MD-027
puts "--- an ignore written under no rejected word ---"
vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"), h4(7, "Rejected"),
  nested(9, "`app/order.rb:2` — Quotes the upstream column name.")
])

# @behavior MD-028
puts "--- an ignore with nothing to say why ---"
vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"), h4(7, "Rejected"),
  item(9, "`Purchase` — Order is what the domain calls it."),
  nested(10, "`app/order.rb:2`")
])

# A list under a term but above Rejected is prose, the same as a paragraph
# under a scenario: only the reserved heading says a list declares something.
# @behavior MD-029
puts "--- a list a reserved heading does not open is prose ---"
p vocabulary([
  h1(1, "Glossary"), h2(3, "Everywhere"), h3(5, "Order"),
  item(7, "one the definition wanted to list"),
  nested(8, "and one under it")
]).statements[0].statements[0].statements

# A vocabulary is refused before any block is read, because a file nobody
# wrote is a reference line to compare against rather than a document out of
# shape.
# @behavior MD-030
puts "--- a vocabulary nobody wrote ---"
begin
  Sumitsubo::Specification::Parser::Markdown.new(Canned.new([])).glossary("nowhere.md")
rescue Sumitsubo::Unreadable => e
  puts "  refused: #{e.message}"
end

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

def fence(line, text) = capture("fence", line, text)
def language(line, text) = capture("language", line, text)
def content(line, text) = capture("content", line, text)

def definition(captures, answers = {})
  Sumitsubo::Specification::Parser::Markdown.new(Canned.new(captures)).contract("cli.md", Spelling.new(answers))
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

# @behavior MD-031
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
# @behavior MD-032
puts "--- a definition whose contracts the syntax tree declares ---"
WHERE = "module Sumitsubo::Place\n  def self.of(path)\n  end\nend\n"
HANDLE = "mod store {\n    pub struct Handle;\n}\n"

registered_by(definition([
  h1(1, "Internal seams"),
  paragraph(3, "The places this project keeps to one implementation."),
  h2(5, "`Sumitsubo::Place.of` `internal`"),
  paragraph(7, "The one place a path a reader is handed is made."),
  fence(9, "```ruby\n#{WHERE}```"),
  language(9, "ruby"),
  content(10, WHERE),
  h2(14, "`store::Handle`"),
  fence(16, "```rust\n#{HANDLE}```"),
  language(16, "rust"),
  content(17, HANDLE)
], {
  WHERE => [scope("Sumitsubo::Place"), declares("Sumitsubo::Place.of")],
  HANDLE => [scope("store"), declares("store::Handle")]
}))

# @behavior MD-033
puts "--- a contract heading that does not open with a name ---"
definition([h1(1, "CLI"), h2(3, "the first command")])

# @behavior MD-034
puts "--- a flag a contract does not carry ---"
definition([h1(1, "CLI"), h2(3, "`init` `hidden`")])

# @behavior MD-035
puts "--- prose written after a name where only a flag is read ---"
definition([h1(1, "CLI"), h2(3, "`init` lays down a specification")])

# @behavior MD-036
puts "--- a marker named after a contract has already been registered ---"
definition([h1(1, "CLI"), h2(3, "`init`"), h2(5, "Marker"), paragraph(7, "`@command`")])

# @behavior MD-037
puts "--- a marker heading with no word under it ---"
definition([h1(1, "CLI"), h2(3, "Marker"), h2(5, "`init`")])

# @behavior MD-038
puts "--- a contract the syntax tree reading is given no signature for ---"
definition([h1(1, "Seams"), h2(3, "`Store.open`"), paragraph(5, "A seam.")])

# @behavior MD-039
puts "--- a signature whose fence names no language ---"
definition([
  h1(1, "Seams"), h2(3, "`Store.open`"),
  fence(5, "```\ndef self.open(path)\n```"), content(6, "def self.open(path)\n")
])

# @behavior MD-040
puts "--- a signature in a language this build does not carry ---"
definition([
  h1(1, "Seams"), h2(3, "`Store.open`"),
  fence(5, "```cobol\nOPEN INPUT STORE.\n```"), language(5, "cobol"), content(6, "OPEN INPUT STORE.\n")
])

# The signature is what says the name is one a definition could carry, so the
# name it declares is the name being registered. A fence writing its nesting out
# is what makes `Store.open` that name rather than `open`.
# @behavior MD-041
puts "--- a signature declaring another name ---"
definition([
  h1(1, "Seams"), h2(3, "`Store.open`"),
  fence(5, "```ruby\ndef open(path)\nend\n```"), language(5, "ruby"),
  content(6, "def open(path)\nend\n")
], { "def open(path)\nend\n" => [declares("open")] })

# A signature declares the one contract and the scopes holding it, so anything
# else in the fence is a second contract nothing registers.
# @behavior MD-053
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

# @behavior MD-054
puts "--- a signature the reading cannot read ---"
definition([
  h1(1, "Seams"), h2(3, "`Store.open`"),
  fence(5, "```ruby\ndef self.open(path\n```"), language(5, "ruby"),
  content(6, "def self.open(path\n")
], { "def self.open(path\n" => :unreadable })

# @behavior MD-042
puts "--- a document that names nothing ---"
definition([h2(1, "`init`")])

# Under a marker every fence is prose, so a second one under a contract is too
# — and under the other reading only the first is the signature.
# @behavior MD-043
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

# @behavior MD-044
puts "--- includes written at the level a feature writes them ---"
p globs_of(read([
  h1(1, "Init"), h2(3, "Includes"), item(5, "`test/init_test.rb`"), item(6, "`test/other_test.rb`"),
  h2(8, "`I-001` A run"), item(10, "`not an include`")
]))

# @behavior MD-045
puts "--- includes written at the level a vocabulary writes them ---"
sections_of(vocabulary([
  h1(1, "Glossary"),
  h2(3, "Everywhere"), h3(5, "Includes"), item(7, "`app/**/*.rb`"),
  h3(9, "Order"), item(11, "`not an include`"),
  h2(13, "Billing"), h3(15, "Includes"), item(17, "`app/billing/*.rb`")
]))

# Two sections naming one glob each keep their own: a boundary is the section's,
# and a reader sent to fix one has to be sent to the section that wrote it.
# @behavior MD-046
puts "--- one glob written twice ---"
sections_of(vocabulary([
  h1(1, "Glossary"),
  h2(3, "Everywhere"), h3(5, "Includes"), item(7, "`app/**/*.rb`"),
  h2(9, "Billing"), h3(11, "Includes"), item(13, "`app/**/*.rb`")
]))
