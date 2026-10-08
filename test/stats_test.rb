require "pathname"
require "sumitsubo"
require "sumitsubo/source/language"
require "sumitsubo/source/language/ruby"
require "sumitsubo/grammar"
require "sumitsubo/specification/parser/markdown"

# What this test carries, built the way `bin/sumi.rb` builds it: a reading is
# handed the grammar it puts its queries to.
cli = Sumitsubo::CLI.new(
  Sumitsubo::BUILD_REV,
  Sumitsubo::Source::Language.new([Sumitsubo::Source::Language::Ruby.new(Sumitsubo::Grammar)]),
  [Sumitsubo::Specification::Parser::Markdown.new(Sumitsubo::Grammar)]
)
back = Dir.pwd

# One run answers all four: the fixture holds a comment naming three
# scenarios, a scenario of each kind set apart, and a file claiming nothing —
# its one marker ends the file, so it dangles rather than claims.
# @behavior SA-001 SA-002 SA-003 SA-004
puts "--- how each specification is witnessed ---"
Dir.chdir("test/fixtures/project/stats")
puts "exit=#{cli.run(["stats"])}"
Dir.chdir(back)

# One refusal is raised and the other kept beside a feature that reads, so
# a count leaving the second out would otherwise pass for a whole one.
# @behavior SA-005
puts "--- a feature that cannot be read ---"
Dir.chdir("test/fixtures/project/twice")
puts "exit=#{cli.run(["stats"])}"
Dir.chdir(back)
Dir.chdir("test/fixtures/project/beside")
puts "exit=#{cli.run(["stats"])}"
Dir.chdir(back)

root = Pathname.new("/tmp/sumi_stats_test_#{Process.pid}")
root.rmtree if root.exist?
root.mkpath
Dir.chdir(root)

# @behavior SA-006
puts "--- no specification at all ---"
puts "exit=#{cli.run(["stats"])}"

Dir.chdir(back)
root.rmtree
