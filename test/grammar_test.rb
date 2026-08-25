# Reading real Ruby through the grammar linked into this build.
#
# This test crosses into the binding, so it can never be regenerated: `spin test
# --regen` produces its snapshot by running the file under CRuby, which has no
# ffi_func. The snapshot below is written by hand and stays that way.
require "sumitsubo/language/grammar"

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
