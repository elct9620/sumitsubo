require "sumitsubo/source/language"
require "sumitsubo/source/language/go"
require "sumitsubo/grammar"

# Go alone, which is what these answers are about. Which reading answers for a
# file at all is the seam's question, in `language_test`.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.
LANGUAGES = Sumitsubo::Source::Language.new([
  Sumitsubo::Source::Language::Go.new(Sumitsubo::Grammar)
])

SAMPLE = "test/fixtures/source/go/sample.go"

def spell(regions)
  regions.map { |region| "#{region.line}:#{region.text}" }
end

# What each region stands next to, which is the reading's other answer about a
# comment and the one a claim turns on.
def standing(regions)
  regions.map { |region| "#{region.line}:#{region.followed_by}" }
end

# Go spells `//` and `/* */` with one node, the way Ruby does, so both kinds
# answer without the reading telling them apart. The block comment at the end
# of the file stands in front of nothing.
# @behavior GO-001
puts "--- a third language reads its own comments ---"
p spell(LANGUAGES.comments_in(SAMPLE, "sample.go")).length
p standing(LANGUAGES.comments_in(SAMPLE, "sample.go")).last

# The tree offers no node for the closing delimiter — a Go comment is one token
# with no children — so it comes off the text instead. A line comment carries
# no such suffix, which is what lets both spellings share the one node.
# @behavior GO-002
puts "--- a block comment stops before its own closing delimiter ---"
p spell(LANGUAGES.comments_in(SAMPLE, "sample.go")).find { |said| said.include?("—") }

# A method is reached through the type it hangs on, and the pointer is not part
# of the name: `*Charge` and `Charge` reach one declaration.
# @behavior GO-003
puts "--- and spells a method through the type it hangs on ---"
LANGUAGES.declarations_in(SAMPLE, "sample.go", "go").each do |name|
  puts "  #{name.line} #{name.name}"
end

# `a, b uint32` declares two parameters rather than one, and a declaration may
# give one no name at all.
# @behavior GO-004
puts "--- with the parameters a caller has to satisfy ---"
LANGUAGES.declarations_in(SAMPLE, "sample.go", "go").each do |name|
  next if name.shape.nil? || name.shape.params.empty?

  spelled = name.shape.params.map do |param|
    "#{param.name.nil? ? "-" : param.name}:#{param.kind}#{param.optional ? "?" : ""}"
  end
  puts "  #{name.name}(#{spelled.join(", ")})"
end

BROKEN = "test/fixtures/source/go/broken.go"

# @behavior GO-005
puts "--- source the grammar cannot read ---"
begin
  LANGUAGES.comments_in(BROKEN, "broken.go")
rescue Sumitsubo::Source::Language::Error => e
  puts e.message
end

# @behavior GO-006
puts "--- and the reading of what it declares refuses it too ---"
begin
  LANGUAGES.declarations_in(BROKEN, "broken.go", "go")
rescue Sumitsubo::Source::Language::Error => e
  puts "  #{e.message}"
end
