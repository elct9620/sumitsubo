require "sumitsubo"

cli = Sumitsubo::CLI.new
puts "exit=#{cli.run(["-v"])}"
puts "exit=#{cli.run(["--version"])}"
