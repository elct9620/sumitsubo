require "pathname"
require "sumitsubo"

cli = Sumitsubo::CLI.new
back = Dir.pwd

# @behavior V-001
puts "--- code that drifted from its glossary ---"
Dir.chdir("test/fixtures/glossary")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-002
puts "--- the same run from a subdirectory: same findings, paths from where it started ---"
Dir.chdir("test/fixtures/glossary/app")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-003
puts "--- a specification switched off is not read, however far the code drifted ---"
Dir.chdir("test/fixtures/disabled")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-004
puts "--- every scenario claimed, so the two sides agree ---"
Dir.chdir("test/fixtures/aligned")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-005
puts "--- a scenario nothing claims answers at the specification ---"
Dir.chdir("test/fixtures/uncovered")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-006
puts "--- a claim resolving to no scenario is not a difference but a failure to compare ---"
Dir.chdir("test/fixtures/behavior")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-007 V-011
puts "--- a mechanism that cannot be read leaves the others still answering ---"
Dir.chdir("test/fixtures/unparseable")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# One run answers all three: `verify` is registered and claimed nowhere, `init`
# is claimed twice, and `render` is claimed but registered nowhere.
# @behavior V-012 V-013 V-014
puts "--- an interface nothing claims, one claimed twice, and a claim registered nowhere ---"
Dir.chdir("test/fixtures/contracted")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

root = Pathname.new("/tmp/sumi_verify_test_#{Process.pid}")
root.rmtree if root.exist?
root.mkpath
Dir.chdir(root.to_s)

# @behavior V-008
puts "--- no specification at all ---"
puts "exit=#{cli.run(["verify"])}"

# @behavior V-009
puts "--- a root the configuration points at but nothing wrote ---"
File.write(".sumi.json", "{ \"root\": \"nope\" }\n")
puts "exit=#{cli.run(["verify"])}"
File.delete(".sumi.json")

puts "--- what init lays down verifies clean ---"
puts "exit=#{cli.run(["init"])}"
puts "exit=#{cli.run(["verify"])}"

# Git carries no empty directory, so a clone of a project that committed what
# init laid down arrives without one. Declaring no scenarios is an answer.
# @behavior V-010
puts "--- and so does a clone that arrived without the empty directory ---"
Pathname.new(".spec/behavior").rmtree
puts "exit=#{cli.run(["verify"])}"

Dir.chdir(back)
root.rmtree
