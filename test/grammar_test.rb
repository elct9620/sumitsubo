# Reading real source, and a real specification, through the grammars linked
# into this build.
#
# This test crosses into the binding, so it can never be regenerated: `spin test
# --regen` produces its snapshot by running the file under CRuby, which has no
# ffi_func. The snapshot below is written by hand and stays that way.
require "sumitsubo/grammar"

SOURCE = "# A Customer is billed here.\n" \
         "class Charge\n" \
         "  # Not an Invoice.\n" \
         "  def customer = nil\n" \
         "end\n"

# The query is written out here rather than borrowed from the reading that
# uses it: what this file pins is the binding, and a reading is free to ask a
# different question of the same grammar.
def comments(source, where = "source")
  TreeSitter.capture(Sumitsubo::Grammar::RUBY, source, "(comment) @text", where)
end

# Every capture carries the line it was found on, counted from one as a reader
# counts — a finding nobody can go and look at costs them the search.
p comments(SOURCE).map { |capture| "#{capture.line}:#{capture.text}" }

# An identifier spelling a concept is not a comment, so the scan never sees it:
# `customer` is in the source above and in none of the captures.

# A comment spanning lines arrives whole, separators and all.
p comments("=begin\nA Customer.\n=end\n").map { |capture| "#{capture.line}:#{capture.text}" }

# A file that says nothing is not a failure.
p comments("class Charge\nend\n")

# Source the grammar cannot read is refused rather than half-read: the captures
# it did recover would read exactly like a file that never mentioned the rest.
begin
  comments("class Charge\n  def (((\n", "broken.rb")
rescue TreeSitter::ParseError => e
  puts e.message
end

# A second grammar is carried the same way, and spells its nodes its own way:
# what Ruby calls a `comment` Rust splits into two.
p TreeSitter.capture(
  Sumitsubo::Grammar::RUST,
  "// A Customer is billed here.\nstruct Charge;\n",
  "(line_comment) @text",
  "charge.rs"
).map { |capture| "#{capture.line}:#{capture.text}" }

# A grammar this build does not carry fails where it is asked for.
begin
  TreeSitter.capture("cobol", "IDENTIFICATION DIVISION.\n", "(comment) @text")
rescue TreeSitter::ParseError => e
  puts e.message
end

# Markdown is carried for the specification rather than for source, and what it
# is carried for is the structure: a section nests by heading level, and a table
# is cells. What a heading holds arrives as one unparsed run of text — the block
# grammar leaves inline content alone, and taking the backticks verbatim out of
# that run is what the reading does instead of asking a second grammar for them.
DOCUMENT = "# Init\n" \
           "\n" \
           "Laying down a reference line.\n" \
           "\n" \
           "## `I-001` The first run\n" \
           "\n" \
           "| Step | Statement |\n" \
           "| --- | --- |\n" \
           "| Given | a directory with no specification |\n"

def markdown(query)
  TreeSitter.capture(Sumitsubo::Grammar::MARKDOWN, DOCUMENT, query, "init.md")
end

p markdown("(atx_heading (inline) @text)").map { |capture| "#{capture.line}:#{capture.text}" }
p markdown("(pipe_table_row (pipe_table_cell) @cell)").map { |capture| capture.text }

# What the grammar answers and what the parser makes of it meet here, because
# this is the side that can ask a real one. The parser is handed the grammars
# this build carries, the way a run of `sumi` hands them to it.
require "sumitsubo/parser/markdown"

# The query lives with the parser that writes it, and the name of the grammar
# it is written against travels with it: a name the binding does not know
# answers nothing rather than failing, so the two are pinned to each other.
p Sumitsubo::Parser::Markdown::GRAMMAR == Sumitsubo::Grammar::MARKDOWN

reading = Sumitsubo::Parser::Markdown.new(Sumitsubo::Grammar)

def steps_of(scenario)
  steps = scenario.attributes
  steps.keys.each { |name| said(name, steps[name]) }
end

def said(name, holding)
  holding.each { |one| puts "    #{name} #{one}" }
end

# @behavior MD-015
feature = reading.behavior("test/fixtures/reading/init.md")

puts "#{feature.key} #{feature.includes.inspect}"
puts "  #{feature.text}"
feature.statements.each do |scenario|
  puts "  #{scenario.path}:#{scenario.line} #{scenario.key} #{scenario.text}"
  steps_of(scenario)
end

# The same specification written both ways reads into the same shape. This is
# what says the format changed and nothing else did: path and line are what a
# document carries rather than what it says, so they are the only two fields
# the two sides are allowed to differ in.
require "sumitsubo/parser/json"

def agree(said, one, other)
  puts "  #{one == other ? "same" : "DIFFER"} #{said}#{one == other ? "" : " #{one.inspect} / #{other.inspect}"}"
end

def agree_on_steps(taken, given)
  agree("#{taken.key} steps", taken.attributes, given.attributes)
end

# @behavior MD-017
puts "--- the same specification, written both ways ---"
written = reading.behavior("test/fixtures/reading/init.md")
structured = Sumitsubo::Parser::Json.new.behavior("test/fixtures/reading/init.json")

agree("key", written.key, structured.key)
agree("text", written.text, structured.text)
agree("includes", written.includes, structured.includes)
agree("scenario count", written.statements.length, structured.statements.length)
agree("ids", written.statements.map { |one| one.key }, structured.statements.map { |one| one.key })
agree("titles", written.statements.map { |one| one.text }, structured.statements.map { |one| one.text })

index = 0
while index < written.statements.length
  agree_on_steps(written.statements[index], structured.statements[index])
  index += 1
end

# What they are allowed to differ in, said out loud so the exception is not a
# silent one: a line is where a reader goes, and the two formats write the same
# declaration in different places.
puts "  path #{written.statements[0].path} / #{structured.statements[0].path}"
puts "  line #{written.statements[0].line} / #{structured.statements[0].line}"
