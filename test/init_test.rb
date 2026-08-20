require "pathname"
require "sumitsubo"

# init writes into the working directory, so the run has to happen
# somewhere other than the repository it is testing.
root = Pathname.new("/tmp/sumi_init_test_#{Process.pid}")
root.rmtree if root.exist?
root.mkpath

back = Dir.pwd
Dir.chdir(root.to_s)

cli = Sumitsubo::CLI.new
# @behavior I-001 I-004 I-005
puts "--- first run ---"
puts "exit=#{cli.run(["init"])}"
print File.read(".spec/glossary.json")
# @behavior I-002
puts "--- second run leaves it alone ---"
puts "exit=#{cli.run(["init"])}"

# @behavior I-003
puts "--- a configured root is created however deep it is ---"
File.write(".sumi.json", "{ \"root\": \"spec/nested\" }\n")
puts "exit=#{cli.run(["init"])}"

Dir.chdir(back)
root.rmtree
