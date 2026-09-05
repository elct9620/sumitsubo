require "sumitsubo/source/language"
require "sumitsubo/source/language/typescript"
require "sumitsubo/grammar"

# JavaScript alone, which is what these answers are about. Which reading answers
# for a file at all is the seam's question, in `language_test`.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.
LANGUAGES = Sumitsubo::Source::Language.new([
  Sumitsubo::Source::Language::Typescript.new(Sumitsubo::Grammar)
])

SAMPLE = "test/fixtures/source/typescript/sample.ts"

def spell(regions)
  regions.map { |region| "#{region.line}:#{region.text}" }
end

# JavaScript spells `//`, `/* */` and JSDoc with one node, so all three answer
# without the reading telling them apart, and the closing delimiter comes off
# the text. The block comment at the end of the file stands in front of nothing.
# @behavior TS-001
puts "--- and what a person wrote in a file of its own ---"
p spell(LANGUAGES.comments_in(SAMPLE, "sample.ts")).length
p spell(LANGUAGES.comments_in(SAMPLE, "sample.ts")).find { |said| said.include?("—") }
p LANGUAGES.comments_in(SAMPLE, "sample.ts").last.followed_by

# An interface, an enum, a namespace and an abstract class each declare a name,
# and an abstract class is a node of its own rather than a class carrying a
# word — a query asking only for `class_declaration` passes one over in
# silence. A namespace puts its name in front the way a scope does.
# @behavior TS-002
puts "--- what TypeScript declares beyond what JavaScript does ---"
LANGUAGES.declarations_in(SAMPLE, "sample.ts", "typescript").each do |name|
  puts "  #{name.line} #{name.name}"
end

# A `?` says outright that a caller may leave a parameter out, where a default
# only implies it. A rest parameter is a required one holding a rest pattern,
# so the two are asked for separately — one pattern reaching both would answer
# the same parameter twice.
# @behavior TS-003
puts "--- with the parameters a caller has to satisfy ---"
LANGUAGES.declarations_in(SAMPLE, "sample.ts", "typescript").each do |name|
  next if name.shape.nil? || name.shape.params.empty?

  spelled = name.shape.params.map do |param|
    "#{param.name.nil? ? "-" : param.name}:#{param.kind}#{param.optional ? "?" : ""}"
  end
  puts "  #{name.name}(#{spelled.join(", ")})"
end

BROKEN = "test/fixtures/source/typescript/broken.ts"

# @behavior TS-004
puts "--- source the grammar cannot read ---"
begin
  LANGUAGES.comments_in(BROKEN, "broken.ts")
rescue Sumitsubo::Source::Language::Error => e
  puts e.message
end

# @behavior TS-005
puts "--- and the reading of what it declares refuses it too ---"
begin
  LANGUAGES.declarations_in(BROKEN, "broken.ts", "typescript")
rescue Sumitsubo::Source::Language::Error => e
  puts "  #{e.message}"
end
