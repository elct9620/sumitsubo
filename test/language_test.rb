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

# @behavior L-004
puts "--- and declares nothing ---"
p Sumitsubo::Language.declarations_in(PROSE, "overview.md")

puts "--- while source declares what it declares ---"
p Sumitsubo::Language.declarations_in(RUBY, RUBY).length
