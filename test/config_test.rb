require "pathname"
require "sumitsubo/config"
require "sumitsubo/exclusion"

# Where a run is configured from is decided by what is on disk above it, so the
# cases are real directories walked into rather than a layout described to a
# double. Nothing above the temporary root is expected to carry a .sumi.json or
# a .git; a machine that has one there would answer differently.
root = Pathname.new("/tmp/sumi_config_test_#{Process.pid}")
root.rmtree if root.exist?
back = Dir.pwd
root.mkpath
Dir.chdir(root)
here = Pathname.pwd

(here / "project" / "app" / "billing").mkpath
(here / "project" / ".git").mkpath
(here / "project" / ".sumi.json").write(<<~JSON)
  {
    "root": ".spec/",
    "docs": "docs/spec",
    "exclude": ["target/", "!vendor/kept.rb"],
    "specifications": {
      "glossary": { "verify": false, "render": false },
      "behavior": { "render": false }
    }
  }
JSON
(here / "project" / ".gitignore").write(<<~TEXT)
  # what the build leaves behind
  vendor/
TEXT
(here / "switched").mkpath
(here / "switched" / ".gitignore").write("vendor/\n")
(here / "switched" / ".sumi.json").write("{ \"gitignore\": false }\n")
(here / "repo" / "lib").mkpath
(here / "repo" / ".git").write("gitdir: elsewhere\n")
(here / "loose").mkpath
(here / "broken").mkpath
(here / "broken" / ".sumi.json").write("{ not json\n")

# @behavior C-005 C-006 C-009 C-010
def show(where)
  config = Sumitsubo::Config.load
  from = Pathname.pwd
  puts "#{where}: base=#{config.base.relative_path_from(from)} " \
       "root=#{config.root.relative_path_from(from)} " \
       "docs=#{config.docs.relative_path_from(from)}"
  puts "  verify: glossary=#{config.verify?("glossary")} " \
       "behavior=#{config.verify?("behavior")} contract=#{config.verify?("contract")}"
  puts "  render: glossary=#{config.render?("glossary")} " \
       "behavior=#{config.render?("behavior")} contract=#{config.render?("contract")}"
end

# @behavior C-001 C-007
puts "--- the nearest .sumi.json decides the base, however deep the run starts ---"
Dir.chdir(here / "project" / "app" / "billing")
show("app/billing")
Dir.chdir(here / "project")
show("project")

# @behavior C-002
puts "--- with no .sumi.json, the repository it sits in ---"
# A .git written as a gitfile, which is what a worktree and a submodule leave.
Dir.chdir(here / "repo" / "lib")
show("repo/lib")

# @behavior C-003 C-008
puts "--- with neither, where the run started ---"
Dir.chdir(here / "loose")
show("loose")

# @behavior C-004
puts "--- a .sumi.json that will not parse is not a difference ---"
Dir.chdir(here / "broken")
begin
  Sumitsubo::Config.load
rescue Sumitsubo::Error => e
  puts e.message
end

# What a run leaves alone is the project's rather than any one
# specification's, so it is read once here and every mechanism is handed the
# same answer.
# @behavior C-011
puts "--- what the project excludes ---"
Dir.chdir(here / "project")
rules = Sumitsubo::Config.load.exclusion
["app/order.rb", "target/debug/generated.rb"].each do |path|
  puts "  #{path}: #{Sumitsubo::Exclusion.excludes?(rules, path)}"
end
Dir.chdir(here / "loose")
puts "  a project that said nothing excludes nothing: #{Sumitsubo::Config.load.exclusion.inspect}"

# A project keeping a .gitignore has already said which paths are not its
# source. Saying so is not the same as being made to say it twice, so the
# switch is what a project reaches for when git's answer is the wrong one.
# @behavior C-012
puts "--- and what its .gitignore already said ---"
Dir.chdir(here / "project")
rules = Sumitsubo::Config.load.exclusion
puts "  vendor/gem.rb: #{Sumitsubo::Exclusion.excludes?(rules, "vendor/gem.rb")}"
# .sumi.json is read after the .gitignore, so a `!` there is the last rule to
# match and the path comes back.
puts "  vendor/kept.rb, put back by .sumi.json: #{Sumitsubo::Exclusion.excludes?(rules, "vendor/kept.rb")}"
Dir.chdir(here / "switched")
puts "  switched off: #{Sumitsubo::Exclusion.excludes?(Sumitsubo::Config.load.exclusion, "vendor/gem.rb")}"

Dir.chdir(back)
root.rmtree
