require "sumitsubo/source/language"
require "sumitsubo/source/language/javascript"
require "sumitsubo/grammar"

# JavaScript alone, which is what these answers are about. Which reading answers
# for a file at all is the seam's question, in `language_test`.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.
LANGUAGES = Sumitsubo::Source::Language.new([
  Sumitsubo::Source::Language::Javascript.new(Sumitsubo::Grammar)
])

SAMPLE = "test/fixtures/source/javascript/sample.js"

def spell(regions)
  regions.map { |region| "#{region.line}:#{region.text}" }
end

# JavaScript spells `//`, `/* */` and JSDoc with one node, so all three answer
# without the reading telling them apart, and the closing delimiter comes off
# the text. The block comment at the end of the file stands in front of nothing.
# @behavior JS-001
puts "--- a fifth language reads its own comments ---"
p spell(LANGUAGES.comments_in(SAMPLE, "sample.js")).length
p spell(LANGUAGES.comments_in(SAMPLE, "sample.js")).find { |said| said.include?("—") }
p LANGUAGES.comments_in(SAMPLE, "sample.js").last.followed_by

# The grammar says which of the two a method is — `static` is a node a query
# can ask for — and JSDoc says how to write that down. A private method carries
# its own `#`, so the mark and the name meet.
# @behavior JS-002
puts "--- and marks a member the way JSDoc does ---"
LANGUAGES.declarations_in(SAMPLE, "sample.js", "javascript").each do |name|
  puts "  #{name.line} #{name.name}"
end

# `const f = () => {}` is how a module writes most of its functions, so the
# name it is assigned to is the name it declares. What it was assigned decides
# it either way: an arrow nobody assigned is a callback, and a name holding a
# plain value declares nothing.
# @behavior JS-003
puts "--- with the parameters a caller has to satisfy ---"
LANGUAGES.declarations_in(SAMPLE, "sample.js", "javascript").each do |name|
  next if name.shape.nil? || name.shape.params.empty?

  spelled = name.shape.params.map do |param|
    "#{param.name.nil? ? "-" : param.name}:#{param.kind}#{param.optional ? "?" : ""}"
  end
  puts "  #{name.name}(#{spelled.join(", ")})"
end

BROKEN = "test/fixtures/source/javascript/broken.js"

# @behavior JS-004
puts "--- source the grammar cannot read ---"
begin
  LANGUAGES.comments_in(BROKEN, "broken.js")
rescue Sumitsubo::Source::Language::Error => e
  puts e.message
end

# @behavior JS-005
puts "--- and the reading of what it declares refuses it too ---"
begin
  LANGUAGES.declarations_in(BROKEN, "broken.js", "javascript")
rescue Sumitsubo::Source::Language::Error => e
  puts "  #{e.message}"
end
