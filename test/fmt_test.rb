require "pathname"
require "sumitsubo"
require "sumitsubo/source/language"
require "sumitsubo/source/language/prose"
require "sumitsubo/source/language/ruby"
require "sumitsubo/source/language/rust"

# What this test carries, built the way `bin/sumi.rb` builds it. A signature is
# read as the language it names, so `fmt` is handed the readings even though it
# opens no file a specification covers.
LANGUAGES = Sumitsubo::Source::Language.new([
  Sumitsubo::Source::Language::Ruby.new(Sumitsubo::Grammar),
  Sumitsubo::Source::Language::Rust.new(Sumitsubo::Grammar),
  Sumitsubo::Source::Language::Prose.new
])
require "sumitsubo/grammar"
require "sumitsubo/specification/parser/markdown"

cli = Sumitsubo::CLI.new(
  Sumitsubo::BUILD_REV, LANGUAGES,
  [Sumitsubo::Specification::Parser::Markdown.new(Sumitsubo::Grammar)]
)
back = Dir.pwd

# The same project answers three differences under `verify`, so the silence
# here is what says the source was never opened.
# @behavior FM-001
puts "--- source that drifted from its glossary says nothing here ---"
Dir.chdir("test/fixtures/project/glossary")
puts "exit=#{cli.run(["fmt", "--check"])}"
Dir.chdir(back)

# @behavior FM-002
puts "--- a document its form refused, beside one that reads ---"
Dir.chdir("test/fixtures/project/beside")
puts "exit=#{cli.run(["fmt", "--check"])}"
Dir.chdir(back)

# The project keeps no glossary file and switched the glossary off, so nothing
# is said about the one that is not there.
# @behavior FM-003 FM-005
puts "--- one name declared twice, and a specification the project does not keep ---"
Dir.chdir("test/fixtures/project/twice")
puts "exit=#{cli.run(["fmt", "--check"])}"
Dir.chdir(back)

root = Pathname.new("/tmp/sumi_fmt_test_#{Process.pid}")
root.rmtree if root.exist?
root.mkpath
Dir.chdir(root)

# @behavior FM-004
puts "--- no specification at all ---"
puts "exit=#{cli.run(["fmt", "--check"])}"

puts "--- what init lays down is written the way one is ---"
puts "exit=#{cli.run(["init"])}"
puts "exit=#{cli.run(["fmt", "--check"])}"

# The reference line is what is being rewritten, so the run that changes it is
# asked for by name and the run that only says so leaves the file alone.
WIDE = <<~GLOSSARY
  # Glossary

  ## Everywhere

  ### Includes

  - `app/**/*.rb`

  ### Order

  What a customer asks us to fulfil — the whole of it, never a line of one.

  #### Rejected

  - `Purchase` — Order is what the domain calls it — never what the ledger does.
    - `app/legacy.rb:9` — Quotes the upstream column name.
GLOSSARY

# @behavior FM-006
puts "--- a word set off with a wide dash, and the run that only says so ---"
File.write(".spec/glossary.md", WIDE)
puts "exit=#{cli.run(["fmt", "--check"])}"
puts "still written that way: #{File.read(".spec/glossary.md").include?("—")}"

# @behavior FM-007
puts "--- and the run that writes it ---"
puts "exit=#{cli.run(["fmt"])}"
File.read(".spec/glossary.md").split("\n").each do |line|
  puts "  #{line}" if line.include?("`Purchase`") || line.include?("legacy.rb:9")
end
puts "the dashes in the prose beside them stand: " \
     "#{File.read(".spec/glossary.md").include?("fulfil — the whole")} " \
     "#{File.read(".spec/glossary.md").include?("calls it — never")}"

puts "--- which leaves nothing to say ---"
puts "exit=#{cli.run(["fmt", "--check"])}"

Dir.chdir(back)
root.rmtree
