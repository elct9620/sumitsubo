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
Dir.chdir("test/fixtures/project/relations")

# The center relates to a contract and a key nobody declares, refines a
# scenario, and is claimed beside another. Each of those is related further
# out, and one of them is reached twice.
# @behavior RL-004 RL-005 RL-006 RL-007
puts "--- a statement and what it is related to ---"
puts "exit=#{cli.run(["relate", "IN-001"])}"

# The contracts are switched off and answer all the same.
# @behavior RL-008
puts "--- a statement another mechanism keeps ---"
puts "exit=#{cli.run(["relate", "contract inspect"])}"

# @behavior RL-009
puts "--- a refinement read from the statement it narrows ---"
puts "exit=#{cli.run(["relate", "SA-002"])}"

# @behavior RL-010
puts "--- a key nothing declares ---"
puts "exit=#{cli.run(["relate", "IN-999"])}"

# @behavior RL-011
puts "--- nothing to relate ---"
puts "exit=#{cli.run(["relate"])}"
Dir.chdir(back)

# @behavior RL-012
puts "--- a switched-off mechanism the answer names and cannot read ---"
Dir.chdir("test/fixtures/project/related-unread")
puts "exit=#{cli.run(["relate", "X-003"])}"

# Nothing is found, and the one place it could stand was refused, so the
# answer is not left as a plain no.
# @behavior RL-013
puts "--- a key asked for where its document was refused ---"
puts "exit=#{cli.run(["relate", "contract inspect"])}"
Dir.chdir(back)
