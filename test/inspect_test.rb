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
Dir.chdir("test/fixtures/project/stats")

# @behavior IN-001
puts "--- a scenario claimed from a busy place ---"
puts "exit=#{cli.run(["inspect", "O-001"])}"

# @behavior IN-002
puts "--- a scenario nothing claims ---"
puts "exit=#{cli.run(["inspect", "R-003"])}"

# @behavior IN-003
puts "--- an id nothing knows ---"
puts "exit=#{cli.run(["inspect", "X-999"])}"

# @behavior IN-004
puts "--- nothing to look at ---"
puts "exit=#{cli.run(["inspect"])}"

Dir.chdir(back)
