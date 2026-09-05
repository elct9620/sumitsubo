require "sumitsubo"

cli = Sumitsubo::CLI.new
# @behavior S-002
puts "--- no arguments ---"
puts "exit=#{cli.run([])}"
puts "--- -h ---"
puts "exit=#{cli.run(["-h"])}"
# @behavior S-003
puts "--- unknown flag ---"
puts "exit=#{cli.run(["--nope"])}"
puts "--- known flag followed by an unknown one ---"
puts "exit=#{cli.run(["-v", "--nope"])}"
# @behavior S-004
puts "--- a word that is no command ---"
puts "exit=#{cli.run(["verfiy"])}"
puts "--- help with no topic ---"
puts "exit=#{cli.run(["help"])}"
# @behavior S-005
puts "--- a topic ---"
puts "exit=#{cli.run(["help", "config"])}"
# @behavior S-006
puts "--- a word that is no topic ---"
puts "exit=#{cli.run(["help", "nope"])}"
# @behavior S-007
puts "--- a command given a flag it does not take ---"
puts "exit=#{cli.run(["verify", "--nonsense"])}"
puts "--- a command given a word it does not take ---"
puts "exit=#{cli.run(["init", "wat"])}"
puts "--- a topic followed by a word help does not take ---"
puts "exit=#{cli.run(["help", "config", "extra"])}"
puts "--- what each topic opens with ---"
help = Sumitsubo::Command::Help.new
["glossary", "contract", "behavior", "config"].each do |name|
  puts "  #{name}: #{help.topic(name).split("\n").first}"
end

# Help is built as strings, so where a line ends is the author's. What a run
# prints cannot be wrapped without misquoting it, so the wide lines are listed
# rather than refused: the ones standing here are messages, and a paragraph
# that grew past the width arrives as one more of them.
WRAPPED_AT = 72
puts "--- lines wider than a topic wraps its prose to ---"
["glossary", "contract", "behavior", "config"].each do |name|
  help.topic(name).split("\n").each do |line|
    puts "  #{name} #{line.length}: #{line.strip}" if line.length > WRAPPED_AT
  end
end
