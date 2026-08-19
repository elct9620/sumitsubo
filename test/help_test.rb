require "sumitsubo"

cli = Sumitsubo::CLI.new
puts "--- no arguments ---"
puts "exit=#{cli.run([])}"
puts "--- -h ---"
puts "exit=#{cli.run(["-h"])}"
puts "--- unknown flag ---"
puts "exit=#{cli.run(["--nope"])}"
puts "--- known flag followed by an unknown one ---"
puts "exit=#{cli.run(["-v", "--nope"])}"
