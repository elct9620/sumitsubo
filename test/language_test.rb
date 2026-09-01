require "sumitsubo/source/language"
require "sumitsubo/source/language/prose"
require "sumitsubo/source/language/ruby"
require "sumitsubo/source/language/rust"
require "sumitsubo/grammar"

# What this test carries, built the way `bin/sumi.rb` builds it: a reading is
# handed the grammar it puts its queries to.
LANGUAGES = Sumitsubo::Source::Language.new([
  Sumitsubo::Source::Language::Ruby.new(Sumitsubo::Grammar),
  Sumitsubo::Source::Language::Rust.new(Sumitsubo::Grammar),
  Sumitsubo::Source::Language::Prose.new
])

# How a file is read for what a person put in it, and what a file no language
# claims answers instead.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.

RUBY = "test/fixtures/definitions/sample.rb"
PROSE = "test/fixtures/behavior/test/overview.md"

def spell(regions)
  regions.map { |region| "#{region.line}:#{region.text}" }
end

# What each region stands next to, which is the reading's other answer about a
# comment and the one a claim turns on.
def standing(regions)
  regions.map { |region| "#{region.line}:#{region.followed_by}" }
end

# An identifier is a spelling of a concept rather than the concept's name, so
# `Signed` is declared in this file and appears in none of the regions.
# @behavior L-001
puts "--- what a person wrote in a source file ---"
p spell(LANGUAGES.comments_in("test/fixtures/glossary/app/order.rb", "order.rb"))

# @behavior L-002
puts "--- a file no language claims answers entire ---"
p spell(LANGUAGES.comments_in(PROSE, "overview.md")).length

# @behavior L-003
puts "--- where every line stands in front of more of the same ---"
p standing(LANGUAGES.comments_in(PROSE, "overview.md")).uniq

# A name is spelled the way one language spells it, so which reads the file is
# the specification's to say rather than the filename's to imply.
# @behavior L-004
puts "--- source is read as the language a specification named ---"
p LANGUAGES.declarations_in(RUBY, RUBY, "ruby").length

# What an executable can read is decided when it is built, and a name it does
# not answer to is a run that cannot compare rather than one that guesses.
# @behavior L-008
puts "--- what this build carries ---"
p LANGUAGES.carries?("ruby")
p LANGUAGES.carries?("cobol")

# The claims sit in a class body, a method body and a block comment, and every
# one of them stands in front of code — while the comment at the end of
# `verify_test.rb` stands in front of nothing.
# @behavior L-005 L-006
puts "--- what each comment stands next to ---"
p standing(LANGUAGES.comments_in(
  "test/fixtures/behavior/test/init_test.rb", "init_test.rb"
))
p standing(LANGUAGES.comments_in(
  "test/fixtures/behavior/test/verify_test.rb", "verify_test.rb"
))

# @behavior L-007
puts "--- source the grammar cannot read ---"
begin
  LANGUAGES.comments_in("test/fixtures/behavior/test/broken.rb", "broken.rb")
rescue Sumitsubo::Source::Language::Error => e
  puts e.message
end


RUST = "test/fixtures/definitions/sample.rs"

# What Ruby spells with one node Rust splits into two, and a doc comment is a
# line comment carrying a marker. The block comment at the end of the file
# stands in front of nothing, so it is a comment and nowhere a claim could sit.
# @behavior L-010
puts "--- a second language reads its own comments ---"
p spell(LANGUAGES.comments_in(RUST, "sample.rs")).length
p standing(LANGUAGES.comments_in(RUST, "sample.rs")).last

# A block comment ends with the delimiter Rust required rather than with
# something a person wrote, so a region stops before it. The em dash is what
# holds that to characters: counted in bytes it would cut two short, which is
# why the one carrying it is the region asked for rather than the last.
# @behavior L-015
puts "--- a block comment stops before its own closing delimiter ---"
p spell(LANGUAGES.comments_in(RUST, "sample.rs")).find { |said| said.include?("—") }

# A name is the path the file itself carries: an `impl` says how what is inside
# it is reached without declaring the type, a `mod` and a `trait` do both.
# @behavior L-011
puts "--- and spells a name the way it writes a path ---"
LANGUAGES.declarations_in(RUST, "sample.rs", "rust").each do |name|
  puts "  #{name.line} #{name.name}"
end

# The receiver is a parameter like any other, carrying the kind word Rust uses
# for it — which is what tells a method from an associated function.
# @behavior L-012
puts "--- with the receiver among its parameters ---"
LANGUAGES.declarations_in(RUST, "sample.rs", "rust").each do |name|
  next if name.shape.nil? || name.shape.params.empty?

  spelled = name.shape.params.map { |param| "#{param.kind}#{param.name.nil? ? "" : " #{param.name}"}" }
  puts "  #{name.name}(#{spelled.join(", ")})"
end

DEFS = "test/fixtures/definitions"

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
declares("#{DEFS}/sample.rb")

# @behavior D-006
puts "--- and the reading of what it declares refuses it too ---"
begin
  declares("test/fixtures/behavior/test/broken.rb")
rescue Sumitsubo::Source::Language::Error => e
  puts "  #{e.message}"
end

# A specification registers a contract by writing the declaration it means, so
# the same reading answers both sides and a shape no definition could have is a
# shape no specification can register. The nesting is written out: it is what
# makes the name `Sumitsubo::Place.of` rather than `of`.
SIGNATURE = "module Sumitsubo::Place\n" \
            "  def self.of(path, line)\n" \
            "  end\n" \
            "end\n"

# @behavior L-013
puts "--- what a piece of text declares ---"
LANGUAGES.declarations_of(SIGNATURE, ".spec/contract/internal.md", "ruby").each do |name|
  puts "  #{name.path}:#{name.line} #{name.name}#{signature(name)}"
end

# It answers where the caller said rather than where a file sits, because the
# text came out of a specification and that is where a reader has to be sent.
# @behavior L-014
puts "--- and text the grammar cannot read is refused ---"
begin
  LANGUAGES.declarations_of("def of(path", ".spec/contract/internal.md", "ruby")
rescue Sumitsubo::Source::Language::Error => e
  puts "  #{e.message}"
end
