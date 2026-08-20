# A linear snapshot script, which is how this project writes its own tests.
# There is no method for a claim to attach to, so it attaches to the statement.
require "sumitsubo"

cli = Sumitsubo::CLI.new

# @behavior G-001
puts "exit=#{cli.run(["verify"])}"

# @behavior G-002 I-001
puts "exit=#{cli.run(["verify"])}"

# @behavior G-404
puts "a claim resolving to nothing is still read"

# @behavior G-999
