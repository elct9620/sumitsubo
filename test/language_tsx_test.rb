require "sumitsubo/source/language"
require "sumitsubo/source/language/tsx"
require "sumitsubo/source/language/typescript"
require "sumitsubo/grammar"

# JavaScript alone, which is what these answers are about. Which reading answers
# for a file at all is the seam's question, in `language_test`.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.
LANGUAGES = Sumitsubo::Source::Language.new([
  Sumitsubo::Source::Language::Tsx.new(Sumitsubo::Grammar)
])

SAMPLE = "test/fixtures/source/tsx/sample.tsx"

def spell(regions)
  regions.map { |region| "#{region.line}:#{region.text}" }
end

# JavaScript spells `//`, `/* */` and JSDoc with one node, so all three answer
# without the reading telling them apart, and the closing delimiter comes off
# the text. The block comment at the end of the file stands in front of nothing.
# @behavior TSX-001
puts "--- and what a person wrote in a file of its own ---"
p spell(LANGUAGES.comments_in(SAMPLE, "sample.tsx")).length
p spell(LANGUAGES.comments_in(SAMPLE, "sample.tsx")).find { |said| said.include?("—") }
p LANGUAGES.comments_in(SAMPLE, "sample.tsx").last.followed_by

# A `.tsx` file is TypeScript, so it declares what TypeScript declares and
# spells it the same way. What the other grammar cannot read is the markup: a
# component returning `<div />` answers as the function it is.
# @behavior TSX-002
puts "--- a component is the function it is ---"
LANGUAGES.declarations_in(SAMPLE, "sample.tsx", "tsx").each do |name|
  puts "  #{name.line} #{name.name}"
end

# A destructured prop is a parameter with parts rather than a name, which is
# how a component usually takes them, and a `?` still says a caller may leave
# one out.
# @behavior TSX-003
puts "--- with the parameters a caller has to satisfy ---"
LANGUAGES.declarations_in(SAMPLE, "sample.tsx", "tsx").each do |name|
  next if name.shape.nil? || name.shape.params.empty?

  spelled = name.shape.params.map do |param|
    "#{param.name.nil? ? "-" : param.name}:#{param.kind}#{param.optional ? "?" : ""}"
  end
  puts "  #{name.name}(#{spelled.join(", ")})"
end

BROKEN = "test/fixtures/source/tsx/broken.tsx"

# @behavior TSX-004
puts "--- source the grammar cannot read ---"
begin
  LANGUAGES.comments_in(BROKEN, "broken.tsx")
rescue Sumitsubo::Source::Language::Error => e
  puts e.message
end

# @behavior TSX-005
puts "--- and the reading of what it declares refuses it too ---"
begin
  LANGUAGES.declarations_in(BROKEN, "broken.tsx", "tsx")
rescue Sumitsubo::Source::Language::Error => e
  puts "  #{e.message}"
end

# Why this is a reading of its own rather than an extension the one beside it
# claims: the other grammar is handed the same file and cannot make a parse of
# it. Which of the two reads a `.tsx` is decided by its name, and a
# specification naming the wrong one is refused rather than half-read.
# @behavior TSX-006
puts "--- and the grammar beside it cannot read the same file ---"
begin
  OTHER = Sumitsubo::Source::Language.new([
    Sumitsubo::Source::Language::Typescript.new(Sumitsubo::Grammar)
  ])
  p OTHER.declarations_in(SAMPLE, "sample.tsx", "typescript").length
rescue Sumitsubo::Source::Language::Error => e
  puts "  #{e.message}"
end
