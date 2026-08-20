require "pathname"
require "sumitsubo"

back = Dir.pwd
Dir.chdir("test/fixtures/glossary")

sections = Sumitsubo::Glossary.load(".spec/glossary.json")

# Which files a section reaches is half of what the merge rule means, so the
# scope is printed rather than inferred from the merged result.
# @behavior G-001
puts "--- what each section covers ---"
sections.each do |section|
  puts "#{section.name} #{section.includes.inspect} -> #{Sumitsubo::Glossary.paths_for(section, Pathname.pwd).inspect}"
end

# @behavior G-002
puts "--- effective vocabulary per file ---"
scope = Sumitsubo::Glossary.scope(sections, Pathname.pwd)
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

# The root arrives absolute at runtime, so a message composed from the path
# itself would answer somewhere no reader can go.
# @behavior G-006
puts "--- and one named absolutely still answers where the run started ---"
begin
  Sumitsubo::Glossary.load(Pathname.new("test/fixtures/glossary/absent.json").expand_path.to_s)
rescue Sumitsubo::Glossary::Error => e
  puts e.message
end
