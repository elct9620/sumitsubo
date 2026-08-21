require "sumitsubo"

cli = Sumitsubo::CLI.new
# @behavior S-001
puts "exit=#{cli.run(["-v"])}"
puts "exit=#{cli.run(["--version"])}"
# A revision the executable would hand in, so the seam is exercised where
# `spin test` can see it.
puts "exit=#{Sumitsubo::CLI.new("9bc91f3").run(["-v"])}"
