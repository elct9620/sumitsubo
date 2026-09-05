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
puts "exit=#{cli.run(["fmt"])}"
Dir.chdir(back)

# @behavior FM-002
puts "--- a document its form refused, beside one that reads ---"
Dir.chdir("test/fixtures/project/beside")
puts "exit=#{cli.run(["fmt"])}"
Dir.chdir(back)

# The project keeps no glossary file and switched the glossary off, so nothing
# is said about the one that is not there.
# @behavior FM-003 FM-005
puts "--- one name declared twice, and a specification the project does not keep ---"
Dir.chdir("test/fixtures/project/twice")
puts "exit=#{cli.run(["fmt"])}"
Dir.chdir(back)

root = Pathname.new("/tmp/sumi_fmt_test_#{Process.pid}")
root.rmtree if root.exist?
root.mkpath
Dir.chdir(root)

# @behavior FM-004
puts "--- no specification at all ---"
puts "exit=#{cli.run(["fmt"])}"

puts "--- what init lays down is written the way one is ---"
puts "exit=#{cli.run(["init"])}"
puts "exit=#{cli.run(["fmt"])}"

Dir.chdir(back)
root.rmtree
