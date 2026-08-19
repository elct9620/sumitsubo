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
puts "--- first run ---"
puts "exit=#{cli.run(["init"])}"
print File.read(".spec/glossary.json")
puts "--- second run leaves it alone ---"
puts "exit=#{cli.run(["init"])}"

Dir.chdir(back)
root.rmtree
