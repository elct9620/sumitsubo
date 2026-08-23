require "pathname"
require "sumitsubo/glossary"

back = Dir.pwd
Dir.chdir("test/fixtures/glossary")

sections = Sumitsubo::Glossary.load(".spec/glossary.json")

# Which files an entry reaches is half of what the laying rule means, so the
# scope is printed rather than inferred from the merged result.
# @behavior G-001
puts "--- what each entry covers ---"
sections.each do |section|
  puts "#{section.name} #{section.includes.inspect} -> #{Sumitsubo::Glossary.paths_for(section, Pathname.pwd, []).inspect}"
end

# @behavior G-002
puts "--- effective vocabulary per file ---"
scope = Sumitsubo::Glossary.scope(sections, Pathname.pwd, [])
scope.keys.sort.each do |path|
  terms = scope[path]
  terms.keys.sort.each do |name|
    term = terms[name]
    puts "#{path} #{name}: #{term.definition}"
    term.disallowed.each do |entry|
      puts "#{path} #{name} rejects #{entry.term}: #{entry.reason}"
    end
  end
end

# Order is the whole of the rule, so reading the same glossary backwards is
# what shows nothing else decides which vocabulary lands on top.
# @behavior G-007
puts "--- read backwards, Global lands on top ---"
backwards = Sumitsubo::Glossary.scope(sections.reverse, Pathname.pwd, [])
puts "app/billing/charge.rb Order: #{backwards["app/billing/charge.rb"]["Order"].definition}"

# A finding is built here rather than read out of a run: what is being shown
# is which of two the rule sets aside, and reaching a grammar to get them
# would cost this file its snapshot.
# @behavior G-008
puts "--- what the specification spells is not a use of it ---"
spelled = Sumitsubo::Glossary::Finding.new(".spec/glossary.json", 10, "Order", "Purchase", "Order is what the domain calls it.")
used = Sumitsubo::Glossary::Finding.new("app/order.rb", 2, "Order", "Purchase", "Order is what the domain calls it.")
Sumitsubo::Glossary.uses([spelled, used], ".spec/glossary.json", Pathname.pwd).each do |finding|
  puts "#{finding.path}:#{finding.line} #{Sumitsubo::Glossary.describe(finding)}"
end

# Findings are built here rather than read out of a run for the same reason
# as above: what is being shown is which of them the specification set aside.
# @behavior G-009 G-010
puts "--- a finding the specification set aside, and one it did not ---"
ignored = Sumitsubo::Glossary.load("ignored.json")
aside = Sumitsubo::Glossary::Finding.new("app/order.rb", 2, "Order", "Purchase", "Order is what the domain calls it.")
kept = Sumitsubo::Glossary::Finding.new("app/other.rb", 3, "Order", "Purchase", "Order is what the domain calls it.")
Sumitsubo::Glossary.standing([aside, kept], ignored).each do |finding|
  puts "#{finding.path}:#{finding.line} #{Sumitsubo::Glossary.describe(finding)}"
end
Sumitsubo::Glossary.unresolved([aside, kept], ignored).each do |stale|
  puts "ignored.json:#{stale.line} #{Sumitsubo::Glossary.describe_unresolved(stale)}"
end

Dir.chdir(back)

# @behavior G-003
puts "--- a missing glossary is a broken reference line, not a difference ---"
begin
  Sumitsubo::Glossary.load("test/fixtures/glossary/absent.json")
rescue Sumitsubo::Glossary::Error => e
  puts e.message
end

# @behavior G-004
puts "--- so is one that will not parse ---"
begin
  Sumitsubo::Glossary.load("test/fixtures/glossary/broken.json")
rescue Sumitsubo::Glossary::Error => e
  puts e.message
end

# @behavior G-005
puts "--- and so is one with no glossary in it ---"
begin
  Sumitsubo::Glossary.load("test/fixtures/glossary/shapeless.json")
rescue Sumitsubo::Glossary::Error => e
  puts e.message
end

# @behavior G-011
puts "--- an ignore that could not be written down is a broken reference line ---"
["test/fixtures/glossary/noat.json", "test/fixtures/glossary/noreason.json"].each do |path|
  begin
    Sumitsubo::Glossary.load(path)
  rescue Sumitsubo::Glossary::Error => e
    puts e.message
  end
end

# The root arrives absolute at runtime, so a message composed from the path
# itself would answer somewhere no reader can go.
# @behavior G-006
puts "--- and one named absolutely still answers where the run started ---"
begin
  Sumitsubo::Glossary.load(Pathname.new("test/fixtures/glossary/absent.json").expand_path.to_s)
rescue Sumitsubo::Glossary::Error => e
  puts e.message
end
