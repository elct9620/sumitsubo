require "sumitsubo/source/language"
require "sumitsubo/source/language/python"
require "sumitsubo/grammar"

# Python alone, which is what these answers are about. Which reading answers for
# a file at all is the seam's question, in `language_test`.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.
LANGUAGES = Sumitsubo::Source::Language.new([
  Sumitsubo::Source::Language::Python.new(Sumitsubo::Grammar)
])

SAMPLE = "test/fixtures/source/python/sample.py"

def spell(regions)
  regions.map { |region| "#{region.line}:#{region.text}" }
end

# Python writes a comment one way and has no block form. A docstring is a
# string the language evaluates rather than a comment, so it is not among what
# a person wrote here — which is what keeps this reading's answer narrower than
# its neighbours'.
# @behavior PY-001
puts "--- a comment, and the docstring that is not one ---"
p spell(LANGUAGES.comments_in(SAMPLE, "sample.py")).length
p spell(LANGUAGES.comments_in(SAMPLE, "sample.py")).find { |said| said.include?("docstring") }
p LANGUAGES.comments_in(SAMPLE, "sample.py").last.followed_by

# A name is the dotted path the scopes holding it spell, and a class inside a
# class puts both in front. Nothing marks a method as the class's rather than
# an instance's: Python spells neither.
# @behavior PY-002
puts "--- and spells a name as the dotted path holding it ---"
LANGUAGES.declarations_in(SAMPLE, "sample.py", "python").each do |name|
  puts "  #{name.line} #{name.name}"
end

# The separators say what the parameters around them are rather than naming one
# of their own, so `a` answers positional-only and `c` keyword — neither of
# which can be read off the parameter itself.
# @behavior PY-003
puts "--- with the kind each separator gives the parameters around it ---"
LANGUAGES.declarations_in(SAMPLE, "sample.py", "python").each do |name|
  next if name.shape.nil? || name.shape.params.empty?

  spelled = name.shape.params.map do |param|
    "#{param.name.nil? ? "-" : param.name}:#{param.kind}#{param.optional ? "?" : ""}"
  end
  puts "  #{name.name}(#{spelled.join(", ")})"
end

BROKEN = "test/fixtures/source/python/broken.py"

# @behavior PY-004
puts "--- source the grammar cannot read ---"
begin
  LANGUAGES.comments_in(BROKEN, "broken.py")
rescue Sumitsubo::Source::Language::Error => e
  puts e.message
end

# @behavior PY-005
puts "--- and the reading of what it declares refuses it too ---"
begin
  LANGUAGES.declarations_in(BROKEN, "broken.py", "python")
rescue Sumitsubo::Source::Language::Error => e
  puts "  #{e.message}"
end
