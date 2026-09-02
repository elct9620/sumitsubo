# Reading real source, and a real specification, through the grammars linked
# into this build.
#
# This test crosses into the binding, so it can never be regenerated: `spin test
# --regen` produces its snapshot by running the file under CRuby, which has no
# ffi_func. The snapshot below is written by hand and stays that way.
require "sumitsubo/grammar"
require "sumitsubo/source/repository"

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
require "sumitsubo/specification/parser/markdown"
require "sumitsubo/specification/builder/behavior"
require "sumitsubo/specification/builder/contract"
require "sumitsubo/specification/builder/glossary"

# The queries live with the parser that writes them, and the names of the
# grammars they are written against travel with them: a name the binding does
# not know answers nothing rather than failing, so the two are pinned to each
# other. Both are pinned, since a specification is read through the pair.
p Sumitsubo::Specification::Parser::Markdown::GRAMMAR == Sumitsubo::Grammar::MARKDOWN
p Sumitsubo::Specification::Parser::Markdown::INLINE == Sumitsubo::Grammar::MARKDOWN_INLINE

reading = Sumitsubo::Specification::Parser::Markdown.new(Sumitsubo::Grammar)

# The extension is the whole of what says a file is written this way, so a
# parser is asked rather than told.
# @behavior MD-016
puts "--- which files this parser answers for ---"
p [reading.reads?("init.md"), reading.reads?("init.json"), reading.reads?(".spec/behavior/init.md")]

# A form says which kinds it is written in and the parser answers with those,
# the way a run does through the repository. The kinds are named outright
# because a constant is reached through the name written here, not through a
# value handed over.
def feature_blocks(reading, path)
  reading.blocks([path], Sumitsubo::Specification::Builder::Behavior::KINDS)[path]
end

def vocabulary_blocks(reading, path)
  reading.blocks([path], Sumitsubo::Specification::Builder::Glossary::KINDS)[path]
end

def definition_blocks(reading, path)
  reading.blocks([path], Sumitsubo::Specification::Builder::Contract::KINDS)[path]
end

def steps_of(scenario)
  steps = scenario.attributes
  steps.keys.each { |name| said(name, steps[name]) }
end

def said(name, holding)
  holding.each { |one| puts "    #{name} #{one}" }
end

# The document breaks its description up with a subheading, and wraps that
# description over two lines. This form is not written at that level, so no
# scenario comes of the subheading; the wrapping is a space by the time the form
# sees the paragraph, which is what the one line below says.
#
# The steps are the rows the reader wrote. A table is drawn with a heading row
# and a delimiter row above them, and neither is a row the grammar answers, so
# a form reading rows has nothing to skip.
# @behavior MD-002
# @behavior MD-015
# @behavior MD-018
# @behavior MD-050
PATH = "test/fixtures/specification/forms/init.md"
feature = Sumitsubo::Specification::Builder::Behavior.new(PATH)
  .build(feature_blocks(reading, PATH))

puts "#{feature.key} #{feature.includes.map { |one| one.key }.inspect}"
puts "  #{feature.text}"
feature.statements.each do |scenario|
  puts "  #{scenario.path}:#{scenario.line} #{scenario.key} #{scenario.text}"
  steps_of(scenario)
end

# A vocabulary and a definition, read from real documents through a real
# grammar. What each builder makes of a block is pinned where a canned one can
# be handed captures; what is pinned here is that a document a person wrote
# arrives as those blocks at all.

def vocabulary_of(spec)
  puts "#{spec.key} #{spec.text.inspect}"
  spec.statements.each do |section|
    puts "  #{section.key} #{section.includes.map { |one| one.key }.inspect}"
    section.statements.each do |term|
      puts "    #{term.line} #{term.key} — #{term.text}"
      term.statements.each do |word|
        puts "      #{word.line} rejects #{word.key} — #{word.text}"
        word.statements.each { |ignore| puts "        #{ignore.line} #{ignore.key} — #{ignore.text}" }
      end
    end
  end
end

# @behavior MD-047
puts "--- a vocabulary read through the grammar ---"
VOCABULARY = "test/fixtures/specification/forms/glossary.md"
vocabulary_of(
  Sumitsubo::Specification::Builder::Glossary.new(VOCABULARY, VOCABULARY)
    .build(vocabulary_blocks(reading, VOCABULARY))
)

def definition(reading, path)
  Sumitsubo::Specification::Builder::Contract.new(path, Sumitsubo::Source::Repository.new(LANGUAGES))
    .build(definition_blocks(reading, path))
end

def definition_of(spec)
  puts "#{spec.key} #{spec.attributes.inspect} #{spec.includes.map { |one| one.key }.inspect}"
  puts "  #{spec.text}"
  spec.statements.each do |contract|
    puts "  #{contract.line} #{contract.key} #{contract.attributes.inspect}"
    puts "    #{contract.text}"
  end
end

# The languages a build carries answer here, the way a run of `sumi` hands them
# in: a signature says which one spells the name it registers.
require "sumitsubo/source/language"
require "sumitsubo/source/language/prose"
require "sumitsubo/source/language/ruby"
require "sumitsubo/source/language/rust"

# What this test carries, built the way `bin/sumi.rb` builds it: a reading is
# handed the grammar it puts its queries to.
LANGUAGES = Sumitsubo::Source::Language.new([
  Sumitsubo::Source::Language::Ruby.new(Sumitsubo::Grammar),
  Sumitsubo::Source::Language::Rust.new(Sumitsubo::Grammar),
  Sumitsubo::Source::Language::Prose.new
])

# @behavior MD-048
puts "--- a definition whose contracts source claims, read through the grammar ---"
definition_of(definition(reading, "test/fixtures/specification/forms/cli.md"))

# Two contracts in two languages under one definition, which the field this
# replaces could not carry.
# @behavior MD-049
puts "--- a definition registering contracts in two languages ---"
definition_of(definition(reading, "test/fixtures/specification/forms/seams.md"))
