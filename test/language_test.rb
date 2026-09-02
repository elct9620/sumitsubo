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

# The seam: which reading answers for a file, and what a build carries at all.
# What each reading makes of what it was handed is its own test, beside its own
# material under `test/fixtures/source/`.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.

RUBY = "test/fixtures/source/ruby/sample.rb"
PROSE = "test/fixtures/source/prose/overview.md"

# The readings are offered in the order they were handed over, which is what
# puts Prose last: a file the languages before it declined falls to it rather
# than to nothing.
# @behavior L-002
puts "--- a file no language claims answers entire ---"
p LANGUAGES.comments_in(PROSE, "overview.md").length

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

# The parameters as a caller would have to satisfy them: the name, the kind,
# and a `?` where the caller may leave it out.
def signature(name)
  return "" if name.shape.nil?

  spelled = name.shape.params.map do |param|
    "#{param.name.nil? ? "-" : param.name}:#{param.kind}#{param.optional ? "?" : ""}"
  end
  " (#{spelled.join(", ")})"
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
