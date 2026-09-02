require "sumitsubo/source/language"
require "sumitsubo/source/language/rust"
require "sumitsubo/grammar"

# Rust alone, which is what these answers are about. Which reading answers for
# a file at all is the seam's question, in `language_test`.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.
LANGUAGES = Sumitsubo::Source::Language.new([
  Sumitsubo::Source::Language::Rust.new(Sumitsubo::Grammar)
])

SAMPLE = "test/fixtures/source/rust/sample.rs"

def spell(regions)
  regions.map { |region| "#{region.line}:#{region.text}" }
end

# What each region stands next to, which is the reading's other answer about a
# comment and the one a claim turns on.
def standing(regions)
  regions.map { |region| "#{region.line}:#{region.followed_by}" }
end

# What Ruby spells with one node Rust splits into two, and a doc comment is a
# line comment carrying a marker. The block comment at the end of the file
# stands in front of nothing, so it is a comment and nowhere a claim could sit.
# @behavior RS-001
puts "--- a second language reads its own comments ---"
p spell(LANGUAGES.comments_in(SAMPLE, "sample.rs")).length
p standing(LANGUAGES.comments_in(SAMPLE, "sample.rs")).last

# A block comment ends with the delimiter Rust required rather than with
# something a person wrote, so a region stops before it. The em dash is what
# holds that to characters: counted in bytes it would cut two short, which is
# why the one carrying it is the region asked for rather than the last.
# @behavior RS-004
puts "--- a block comment stops before its own closing delimiter ---"
p spell(LANGUAGES.comments_in(SAMPLE, "sample.rs")).find { |said| said.include?("—") }

# A name is the path the file itself carries: an `impl` says how what is inside
# it is reached without declaring the type, a `mod` and a `trait` do both.
# @behavior RS-002
puts "--- and spells a name the way it writes a path ---"
LANGUAGES.declarations_in(SAMPLE, "sample.rs", "rust").each do |name|
  puts "  #{name.line} #{name.name}"
end

# The receiver is a parameter like any other, carrying the kind word Rust uses
# for it — which is what tells a method from an associated function.
# @behavior RS-003
puts "--- with the receiver among its parameters ---"
LANGUAGES.declarations_in(SAMPLE, "sample.rs", "rust").each do |name|
  next if name.shape.nil? || name.shape.params.empty?

  spelled = name.shape.params.map { |param| "#{param.kind}#{param.name.nil? ? "" : " #{param.name}"}" }
  puts "  #{name.name}(#{spelled.join(", ")})"
end

BROKEN = "test/fixtures/source/rust/broken.rs"

# @behavior RS-005
puts "--- source the grammar cannot read ---"
begin
  LANGUAGES.comments_in(BROKEN, "broken.rs")
rescue Sumitsubo::Source::Language::Error => e
  puts e.message
end

# @behavior RS-006
puts "--- and the reading of what it declares refuses it too ---"
begin
  LANGUAGES.declarations_in(BROKEN, "broken.rs", "rust")
rescue Sumitsubo::Source::Language::Error => e
  puts "  #{e.message}"
end
