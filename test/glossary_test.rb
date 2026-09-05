require "pathname"
require "sumitsubo/glossary"
require "sumitsubo/check/region"
require "sumitsubo/mechanism"
require "sumitsubo/specification/repository"
require "sumitsubo/grammar"
require "sumitsubo/specification/parser/markdown"

# Nothing under sumitsubo/ names a format, so a test says which it reads. This
# one reaches a grammar to read a real document, which is what its snapshot is
# written by hand for: the mechanism is checked against the shape a person
# actually wrote rather than one assembled here.
PARSERS = [Sumitsubo::Specification::Parser::Markdown.new(Sumitsubo::Grammar)]

# A vocabulary comes from the repository the way a run's does, read as the
# mechanism that keeps it reads it.
def reads(path)
  Sumitsubo::Specification::Repository.new(PARSERS, nil)
    .one(Sumitsubo::Glossary.at(path), Sumitsubo::Mechanism::Glossary.new)
end

# What a vocabulary could not be read as, however it was refused: a form points
# at the line that broke it, and a document nothing could open answers for the
# file. The two are named apart because Spinel gives one name one type across
# both clauses. Reported 2026-09-05.
def refused(path)
  reads(path)
  nil
rescue Sumitsubo::Misshapen => misshapen
  misshapen.refusals.each { |one| puts "#{one.place.spoken} #{one.message}" }
rescue Sumitsubo::Error => wider
  puts wider.message
end

back = Dir.pwd
Dir.chdir("test/fixtures/project/glossary")

vocabulary = reads(".spec/glossary.md")

# Which files a section reaches is half of what the laying rule means, so the
# scope is printed rather than inferred from the merged result.
# @behavior G-001
puts "--- what each section covers ---"
vocabulary.statements.each do |section|
  globs = section.includes.map { |one| one.key }
  puts "#{section.key} #{globs.inspect} -> #{Sumitsubo::Glossary.paths_for(section, Pathname.pwd, []).inspect}"
end

# Two sections naming one glob are one mistake rather than two, so the walk is
# asked about it once and the first to write it is where a reader is sent. The
# vocabulary is built here because no document a person would keep has one.
# @behavior G-012
puts "--- one glob two sections share ---"
WHERE = ".spec/glossary.md"

def section(name, line, glob, at)
  Sumitsubo::Statement.new(name, nil, [
    Sumitsubo::Statement.new(glob, nil, [], WHERE, at, {}, [])
  ], WHERE, line, {}, [])
end

shared = Sumitsubo::Specification.new("Glossary", nil, [], WHERE, {}, [
  section("Everywhere", 5, "app/**/*.rb", 7),
  section("Billing", 11, "app/**/*.rb", 13)
])
Sumitsubo::Glossary.covers(shared, WHERE).each do |cover|
  puts "#{cover.path} #{cover.includes.map { |one| "#{one.line} #{one.key}" }.inspect}"
end

# @behavior G-002
puts "--- effective vocabulary per file ---"
scope = Sumitsubo::Glossary.scope(vocabulary, Pathname.pwd, [])
scope.keys.sort.each do |path|
  terms = scope[path]
  terms.keys.sort.each do |name|
    term = terms[name]
    puts "#{path} #{name}: #{term.text}"
    term.statements.each do |entry|
      puts "#{path} #{name} rejects #{entry.key}: #{entry.text}"
    end
  end
end

# Order is the whole of the rule, so reading the same sections backwards is
# what shows nothing else decides which vocabulary lands on top.
# @behavior G-007
puts "--- read backwards, the first section lands on top ---"
reversed = Sumitsubo::Specification.new(
  vocabulary.key, vocabulary.text, vocabulary.includes,
  vocabulary.path, vocabulary.attributes, vocabulary.statements.reverse
)
backwards = Sumitsubo::Glossary.scope(reversed, Pathname.pwd, [])
puts "app/billing/charge.rb Order: #{backwards["app/billing/charge.rb"]["Order"].text}"

# A mention is built here rather than read out of a run: what is being shown
# is which of two the rule sets aside, and the specification is what says
# which line declares.
# @behavior G-008
puts "--- what the specification spells is not a use of it ---"
spelled = Sumitsubo::Glossary::Mention.new(path: ".spec/glossary.md", line: 18, term: "Order", used: "Purchase", reason: "Order is what the domain calls it.")
used = Sumitsubo::Glossary::Mention.new(path: "app/order.rb", line: 2, term: "Order", used: "Purchase", reason: "Order is what the domain calls it.")
Sumitsubo::Glossary.uses([spelled, used], vocabulary).each do |mention|
  puts "#{mention.path}:#{mention.line} #{mention.term} rejects #{mention.used}: #{mention.reason}"
end

# Mentions are built here rather than read out of a run for the same reason
# as above: what is being shown is which of them the specification set aside.
# @behavior G-009 G-010
puts "--- a mention the specification set aside, and one it did not ---"
ignored = reads("ignored.md")
aside = Sumitsubo::Glossary::Mention.new(path: "app/order.rb", line: 2, term: "Order", used: "Purchase", reason: "Order is what the domain calls it.")
kept = Sumitsubo::Glossary::Mention.new(path: "app/other.rb", line: 3, term: "Order", used: "Purchase", reason: "Order is what the domain calls it.")
set_aside = Sumitsubo::Glossary.set_aside(ignored)
Sumitsubo::Check::Region::Rejected.new(Sumitsubo::Mechanism::Glossary::REJECTED)
  .run([aside, kept], set_aside, Pathname.pwd).each do |finding|
  puts "#{finding.place.spoken} #{finding.message}"
end
Sumitsubo::Check::Region::Stale.new(Sumitsubo::Mechanism::Glossary::STALE)
  .run([aside, kept], set_aside, ignored.path).each do |finding|
  puts "#{finding.place.spoken} #{finding.message}"
end

Dir.chdir(back)

# @behavior G-003
puts "--- a missing glossary is a broken reference line, not a difference ---"
refused("test/fixtures/specification/glossary/absent.md")

# A vocabulary is what a title says a document is. Without one there is
# nothing saying this was meant to be read as a vocabulary at all.
# @behavior G-005
puts "--- and so is one that never says it is a vocabulary ---"
refused("test/fixtures/specification/glossary/titleless.md")

# @behavior G-011
puts "--- an ignore that could not be written down is a broken reference line ---"
["test/fixtures/specification/glossary/noat.md", "test/fixtures/specification/glossary/noreason.md"].each do |path|
  refused(path)
end

# Which container a name stands for one thing inside is the whole of the rule:
# the document holds its sections, a section its terms, a term the words it
# turns down, and a word the lines it sets aside. Each fixture writes the name
# outside that container as well, so the line a refusal names is what says
# where the boundary was drawn.
# @behavior G-013 G-014 G-015 G-016
puts "--- a name the vocabulary spells twice where it stands for one thing ---"
["test/fixtures/specification/glossary/secondsection.md",
 "test/fixtures/specification/glossary/secondterm.md",
 "test/fixtures/specification/glossary/secondword.md",
 "test/fixtures/specification/glossary/secondignore.md"].each do |path|
  refused(path)
end

# The root arrives absolute at runtime, so a message composed from the path
# itself would answer somewhere no reader can go.
# @behavior G-006
puts "--- and one named absolutely still answers where the run started ---"
refused(Pathname.new("test/fixtures/specification/glossary/absent.md").expand_path.to_s)
