require "sumitsubo/source/language"
require "sumitsubo/source/language/prose"

# Prose alone, which is what it answers for: whatever no language claimed. Which
# reading a file falls to is the seam's question rather than this one's, so
# nothing else is registered here.
#
# Nothing reaches the grammar — prose has none — so `--regen` can write the
# snapshot beside it. It is the one reading a build carries where that is true.
LANGUAGES = Sumitsubo::Source::Language.new([Sumitsubo::Source::Language::Prose.new])

PROSE = "test/fixtures/source/prose/overview.md"

# What each region stands next to, which is the reading's other answer about a
# comment and the one a claim turns on.
def standing(regions)
  regions.map { |region| "#{region.line}:#{region.followed_by}" }
end

# Prose has no code for a comment to sit in front of, so saying it puts a claim
# written here on the same footing as one at the end of a source file.
# @behavior L-003
puts "--- where every line stands in front of more of the same ---"
p standing(LANGUAGES.comments_in(PROSE, "overview.md")).uniq
