require "pathname"
require "sumitsubo"

cli = Sumitsubo::CLI.new
back = Dir.pwd

puts "--- code that drifted from its glossary ---"
Dir.chdir("test/fixtures/glossary")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

puts "--- the same run from a subdirectory: same findings, paths from where it started ---"
Dir.chdir("test/fixtures/glossary/app")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

puts "--- a specification switched off is not read, however far the code drifted ---"
Dir.chdir("test/fixtures/disabled")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

puts "--- every scenario claimed, so the two sides agree ---"
Dir.chdir("test/fixtures/aligned")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

puts "--- a scenario nothing claims answers at the specification ---"
Dir.chdir("test/fixtures/uncovered")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

puts "--- a claim resolving to no scenario is not a difference but a failure to compare ---"
Dir.chdir("test/fixtures/behavior")
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

puts "--- a root the configuration points at but nothing wrote ---"
File.write(".sumi.json", "{ \"root\": \"nope\" }\n")
puts "exit=#{cli.run(["verify"])}"
File.delete(".sumi.json")

puts "--- what init lays down verifies clean ---"
puts "exit=#{cli.run(["init"])}"
puts "exit=#{cli.run(["verify"])}"

Dir.chdir(back)
root.rmtree
