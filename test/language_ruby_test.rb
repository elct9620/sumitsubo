require "sumitsubo/source/language"
require "sumitsubo/source/language/ruby"
require "sumitsubo/grammar"

# Ruby alone, which is what these answers are about: the comments a person
# wrote, the names the file declares, and the shape each is reached by. Which
# reading answers for a file at all is the seam's question, in `language_test`.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.
LANGUAGES = Sumitsubo::Source::Language.new([
  Sumitsubo::Source::Language::Ruby.new(Sumitsubo::Grammar)
])

SAMPLE = "test/fixtures/source/ruby/sample.rb"
BROKEN = "test/fixtures/source/ruby/broken.rb"

def spell(regions)
  regions.map { |region| "#{region.line}:#{region.text}" }
end

# What each region stands next to, which is the reading's other answer about a
# comment and the one a claim turns on.
def standing(regions)
  regions.map { |region| "#{region.line}:#{region.followed_by}" }
end

# An identifier is a spelling of a concept rather than the concept's name, so
# `Purchase` is declared in this file and appears in none of the regions.
# @behavior L-001
puts "--- what a person wrote in a source file ---"
p spell(LANGUAGES.comments_in("test/fixtures/source/ruby/comments.rb", "comments.rb"))

# The claims sit in a class body, a method body and a block comment, and every
# one of them stands in front of code — while the comment at the end of
# `trailing.rb` stands in front of nothing.
# @behavior L-005 L-006
puts "--- what each comment stands next to ---"
p standing(LANGUAGES.comments_in(
  "test/fixtures/source/ruby/nested.rb", "nested.rb"
))
p standing(LANGUAGES.comments_in(
  "test/fixtures/source/ruby/trailing.rb", "trailing.rb"
))

# @behavior L-007
puts "--- source the grammar cannot read ---"
begin
  LANGUAGES.comments_in(BROKEN, "broken.rb")
rescue Sumitsubo::Source::Language::Error => e
  puts e.message
end

def declares(path)
  LANGUAGES.declarations_in(path, path, "ruby").each do |name|
    puts "  #{name.path}:#{name.line} #{name.name}#{signature(name)}"
  end
end

# The parameters as a caller would have to satisfy them: the name, the kind,
# and a `?` where the caller may leave it out. A dash stands where Ruby let the
# parameter go unnamed.
def signature(name)
  return "" if name.shape.nil?

  spelled = name.shape.params.map do |param|
    "#{param.name.nil? ? "-" : param.name}:#{param.kind}#{param.optional ? "?" : ""}"
  end
  " (#{spelled.join(", ")})"
end

# One file answers five: `Outer::Inner` is qualified by its nesting, `.load`
# and `#check` are told apart the way Ruby spells them, `Flat::Scoped` is
# written as a path rather than nested, `loose` sits outside every scope, and
# `Reopened.built` belongs to its class though it is written as an instance method.
#
# `Signed` then answers what each method takes: the kind Ruby's spelling gives
# each parameter, which of them a caller may leave out, the ones Ruby let go
# unnamed, and the difference between a method taking none and a scope taking
# no parameters at all. `**nil` names no parameter, so `#strict` answers one.
#
# `Boxed` is the same reading of a class body a call writes: what sits in the
# block is reached through the constant, whether the constant is bare or spelled
# as a path. `Bare` carries no block and so declares nothing.
#
# What the reading does not carry is declared here too: `Called` answers itself
# and neither of the methods its calls bring into being, and `Widget` answers
# itself without the method it mixes in.
# @behavior D-001 D-002 D-003 D-004 D-007 D-008 D-009 D-010 D-011 D-012 D-013
# @behavior D-014 D-015 D-019 D-020
puts "--- what a Ruby file declares ---"
declares(SAMPLE)

# @behavior D-006
puts "--- and the reading of what it declares refuses it too ---"
begin
  declares(BROKEN)
rescue Sumitsubo::Source::Language::Error => e
  puts "  #{e.message}"
end
