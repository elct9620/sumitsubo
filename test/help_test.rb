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
puts "--- what each topic opens with ---"
help = Sumitsubo::Command::Help.new
["glossary", "contract", "behavior", "config"].each do |name|
  puts "  #{name}: #{help.topic(name).split("\n").first}"
end
