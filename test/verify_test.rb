require "pathname"
require "sumitsubo"

cli = Sumitsubo::CLI.new
back = Dir.pwd

puts "--- code that drifted from its glossary ---"
Dir.chdir("test/fixtures/glossary")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

puts "--- source the grammar cannot read is not a difference either ---"
Dir.chdir("test/fixtures/unparseable")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

root = Pathname.new("/tmp/sumi_verify_test_#{Process.pid}")
root.rmtree if root.exist?
root.mkpath
Dir.chdir(root.to_s)

puts "--- no specification at all ---"
puts "exit=#{cli.run(["verify"])}"

puts "--- what init lays down verifies clean ---"
puts "exit=#{cli.run(["init"])}"
puts "exit=#{cli.run(["verify"])}"

Dir.chdir(back)
root.rmtree
