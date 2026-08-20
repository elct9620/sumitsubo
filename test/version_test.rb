require "sumitsubo"

cli = Sumitsubo::CLI.new
# @behavior S-001
puts "exit=#{cli.run(["-v"])}"
puts "exit=#{cli.run(["--version"])}"
