require "pathname"
require "sumitsubo/config"

# Where a run is configured from is decided by what is on disk above it, so the
# cases are real directories walked into rather than a layout described to a
# double. Nothing above the temporary root is expected to carry a .sumi.json or
# a .git; a machine that has one there would answer differently.
root = Pathname.new("/tmp/sumi_config_test_#{Process.pid}")
root.rmtree if root.exist?
back = Dir.pwd
root.mkpath
Dir.chdir(root.to_s)
here = Pathname.pwd

(here / "project" / "app" / "billing").mkpath
(here / "project" / ".git").mkpath
(here / "project" / ".sumi.json").write(<<~JSON)
  {
    "root": ".spec/",
    "specifications": {
      "glossary": { "verify": false }
    }
  }
JSON
(here / "repo" / "lib").mkpath
(here / "repo" / ".git").write("gitdir: elsewhere\n")
(here / "loose").mkpath
(here / "broken").mkpath
(here / "broken" / ".sumi.json").write("{ not json\n")

def show(where)
  config = Sumitsubo::Config.load
  from = Pathname.pwd
  puts "#{where}: base=#{config.base.relative_path_from(from)} " \
       "root=#{config.root.relative_path_from(from)} " \
       "glossary=#{config.verify?("glossary")} contract=#{config.verify?("contract")}"
end

puts "--- the nearest .sumi.json decides the base, however deep the run starts ---"
Dir.chdir((here / "project" / "app" / "billing").to_s)
show("app/billing")
Dir.chdir((here / "project").to_s)
show("project")

puts "--- with no .sumi.json, the repository it sits in ---"
# A .git written as a gitfile, which is what a worktree and a submodule leave.
Dir.chdir((here / "repo" / "lib").to_s)
show("repo/lib")

puts "--- with neither, where the run started ---"
Dir.chdir((here / "loose").to_s)
show("loose")

puts "--- a .sumi.json that will not parse is not a difference ---"
Dir.chdir((here / "broken").to_s)
begin
  Sumitsubo::Config.load
rescue Sumitsubo::Error => e
  puts e.message
end

Dir.chdir(back)
root.rmtree
