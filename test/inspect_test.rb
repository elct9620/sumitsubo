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

# The comment begins a line before its first claim, and the line asked for
# is neither of the claims, so only the comment's own span can answer it.
# @behavior IN-005
puts "--- a line inside a comment ---"
puts "exit=#{cli.run(["inspect", "test/order_test.rb:1"])}"

# @behavior IN-006
puts "--- a whole file ---"
puts "exit=#{cli.run(["inspect", "test/refund_test.rb"])}"

# @behavior IN-007
puts "--- a place claiming nothing ---"
puts "exit=#{cli.run(["inspect", "test/other_test.rb:1"])}"

Dir.chdir(back)
