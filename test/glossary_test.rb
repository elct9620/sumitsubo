require "pathname"
require "sumitsubo/glossary"
require "sumitsubo/grammar"
require "sumitsubo/parser/markdown"

# Nothing under sumitsubo/ names a format, so a test says which it reads. This
# one reaches a grammar to read a real document, which is what its snapshot is
# written by hand for: the mechanism is checked against the shape a person
# actually wrote rather than one assembled here.
PARSERS = [Sumitsubo::Parser::Markdown.new(Sumitsubo::Grammar)]

back = Dir.pwd
Dir.chdir("test/fixtures/glossary")

vocabulary = Sumitsubo::Glossary.load(".spec/glossary.md", PARSERS)

# Which files a section reaches is half of what the laying rule means, so the
# scope is printed rather than inferred from the merged result.
# @behavior G-001
puts "--- what each section covers ---"
vocabulary.statements.each do |section|
  globs = section.attributes[Sumitsubo::INCLUDE]
  puts "#{section.key} #{globs.inspect} -> #{Sumitsubo::Glossary.paths_for(section, Pathname.pwd, []).inspect}"
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

# A finding is built here rather than read out of a run: what is being shown
# is which of two the rule sets aside, and the specification is what says
# which line declares.
# @behavior G-008
puts "--- what the specification spells is not a use of it ---"
spelled = Sumitsubo::Glossary::Finding.new(".spec/glossary.md", 18, "Order", "Purchase", "Order is what the domain calls it.")
used = Sumitsubo::Glossary::Finding.new("app/order.rb", 2, "Order", "Purchase", "Order is what the domain calls it.")
Sumitsubo::Glossary.uses([spelled, used], vocabulary).each do |finding|
  puts "#{finding.path}:#{finding.line} #{Sumitsubo::Glossary.describe(finding)}"
end

# Findings are built here rather than read out of a run for the same reason
# as above: what is being shown is which of them the specification set aside.
# @behavior G-009 G-010
puts "--- a finding the specification set aside, and one it did not ---"
ignored = Sumitsubo::Glossary.load("ignored.md", PARSERS)
aside = Sumitsubo::Glossary::Finding.new("app/order.rb", 2, "Order", "Purchase", "Order is what the domain calls it.")
kept = Sumitsubo::Glossary::Finding.new("app/other.rb", 3, "Order", "Purchase", "Order is what the domain calls it.")
Sumitsubo::Glossary.standing([aside, kept], ignored).each do |finding|
  puts "#{finding.path}:#{finding.line} #{Sumitsubo::Glossary.describe(finding)}"
end
Sumitsubo::Glossary.unresolved([aside, kept], ignored).each do |stale|
  puts "ignored.md:#{stale.line} #{Sumitsubo::Glossary.describe_unresolved(stale)}"
end

Dir.chdir(back)

# @behavior G-003
puts "--- a missing glossary is a broken reference line, not a difference ---"
begin
  Sumitsubo::Glossary.load("test/fixtures/glossary/absent.md", PARSERS)
rescue Sumitsubo::Glossary::Error => e
  puts e.message
end

# A vocabulary is what a title says a document is. Without one there is
# nothing saying this was meant to be read as a vocabulary at all.
# @behavior G-005
puts "--- and so is one that never says it is a vocabulary ---"
begin
  Sumitsubo::Glossary.load("test/fixtures/glossary/titleless.md", PARSERS)
rescue Sumitsubo::Glossary::Error => e
  puts e.message
end

# @behavior G-011
puts "--- an ignore that could not be written down is a broken reference line ---"
["test/fixtures/glossary/noat.md", "test/fixtures/glossary/noreason.md"].each do |path|
  begin
    Sumitsubo::Glossary.load(path, PARSERS)
  rescue Sumitsubo::Glossary::Error => e
    puts e.message
  end
end

# The root arrives absolute at runtime, so a message composed from the path
# itself would answer somewhere no reader can go.
# @behavior G-006
puts "--- and one named absolutely still answers where the run started ---"
begin
  Sumitsubo::Glossary.load(Pathname.new("test/fixtures/glossary/absent.md").expand_path.to_s, PARSERS)
rescue Sumitsubo::Glossary::Error => e
  puts e.message
end
