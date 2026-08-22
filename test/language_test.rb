require "sumitsubo/language"

# How a file is read for what a person put in it, and what a file no language
# claims answers instead.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.

RUBY = "test/fixtures/definitions/sample.rb"
PROSE = "test/fixtures/behavior/test/overview.md"

def spell(regions)
  spelled = []
  regions.each { |region| spelled.push("#{region.line}:#{region.text}") }
  spelled
end

# An identifier is a spelling of a concept rather than the concept's name, so
# `Signed` is declared in this file and appears in none of the regions.
# @behavior L-001
puts "--- what a person wrote in a source file ---"
p spell(Sumitsubo::Language.comments_in("test/fixtures/glossary/app/order.rb", "order.rb"))

# @behavior L-002
puts "--- a file no language claims answers entire ---"
p spell(Sumitsubo::Language.comments_in(PROSE, "overview.md")).length

# @behavior L-003
puts "--- and offers nowhere for a claim to sit ---"
p Sumitsubo::Language.attached_comments_in(PROSE, "overview.md")

# A name is spelled the way one language spells it, so which reads the file is
# the specification's to say rather than the filename's to imply.
# @behavior L-004
puts "--- source is read as the language a specification named ---"
p Sumitsubo::Language.declarations_in(RUBY, RUBY, "ruby").length

# What an executable can read is decided when it is built, and a name it does
# not answer to is a run that cannot compare rather than one that guesses.
# @behavior L-008
puts "--- what this build carries ---"
p Sumitsubo::Language.carries?("ruby")
p Sumitsubo::Language.carries?("cobol")

# A shape judgement and nothing more: it says the name is spellable there,
# never that anything defines it.
# @behavior L-009
puts "--- and how that language spells what it defines ---"
p Sumitsubo::Language.definable?("ruby", "Sumitsubo::Where.of")
p Sumitsubo::Language.definable?("ruby", "GET /users/:id")

# The claims sit in a class body, a method body and a block comment, and all
# three are offered — while the comment at the end of `verify_test.rb`, with
# nothing after it, is not.
# @behavior L-005 L-006
puts "--- where a claim could sit ---"
p spell(Sumitsubo::Language.attached_comments_in(
  "test/fixtures/behavior/test/init_test.rb", "init_test.rb"
)).length
p spell(Sumitsubo::Language.attached_comments_in(
  "test/fixtures/behavior/test/verify_test.rb", "verify_test.rb"
))

# @behavior L-007
puts "--- source the grammar cannot read ---"
begin
  Sumitsubo::Language.attached_comments_in("test/fixtures/behavior/test/broken.rb", "broken.rb")
rescue Sumitsubo::Language::Error => e
  puts e.message
end


RUST = "test/fixtures/definitions/sample.rs"

# What Ruby spells with one node Rust splits into two, and a doc comment is a
# line comment carrying a marker. The block comment at the end of the file has
# nothing after it, so it is a comment and not somewhere a claim could sit.
# @behavior L-010
puts "--- a second language reads its own comments ---"
p spell(Sumitsubo::Language.comments_in(RUST, "sample.rs")).length
p spell(Sumitsubo::Language.attached_comments_in(RUST, "sample.rs")).length

# A name is the path the file itself carries: an `impl` says how what is inside
# it is reached without declaring the type, a `mod` and a `trait` do both.
# @behavior L-011
puts "--- and spells a name the way it writes a path ---"
Sumitsubo::Language.declarations_in(RUST, "sample.rs", "rust").each do |name|
  puts "  #{name.line} #{name.name}"
end

# The receiver is a parameter like any other, carrying the kind word Rust uses
# for it — which is what tells a method from an associated function.
# @behavior L-012
puts "--- with the receiver among its parameters ---"
Sumitsubo::Language.declarations_in(RUST, "sample.rs", "rust").each do |name|
  next if name.params.nil? || name.params.empty?

  spelled = []
  name.params.each { |param| spelled.push("#{param.kind}#{param.name.nil? ? "" : " #{param.name}"}") }
  puts "  #{name.name}(#{spelled.join(", ")})"
end
