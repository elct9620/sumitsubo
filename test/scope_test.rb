require "pathname"
require "sumitsubo/source/patterns"
require "sumitsubo/source/scope"

# What the walk reaches, and where it starts from. The tree is built here so
# the answers are against a shape this file wrote rather than whatever the
# repository holds. Nothing reaches the grammar, so `--regen` can write the
# snapshot beside it.

root = Pathname.new("/tmp/sumi_scope_test_#{Process.pid}")
root.rmtree if root.exist?
back = Dir.pwd
root.mkpath
Dir.chdir(root)
base = Pathname.pwd

[
  "top.rb",
  "app/order.rb",
  "app/billing/charge.rb",
  ".hidden/kept.rb",
  "app/.cache/gen.rb",
  "docs/guide.md"
].each do |path|
  file = base / path
  file.parent.mkpath
  file.write("")
end
# A directory that links back up the tree: descending it would never end.
File.symlink("#{base / "app"}", "#{base / "app" / "loop"}")

# A pattern names its walk by everything before its first wildcard, so a
# literal one names no walk at all.
# @behavior W-001
puts "--- where a walk starts ---"
[
  ["app/**/*.rb"],
  ["app/*.rb", "app/billing/*.rb"],
  ["**/*.rb"],
  ["top.rb"],
  ["docs/*.md", "app/**/*.rb", "top.rb"]
].each do |patterns|
  puts "  #{patterns.join(" ")} -> #{Sumitsubo::Source::Scope.roots_in(patterns).inspect}"
end

# `app/billing` sits under `app`, so it is walked by that one and not again.
# @behavior W-002
puts "--- a root under another root is dropped ---"
puts "  #{Sumitsubo::Source::Scope.roots_in(["app/**/*.rb", "app/billing/*.rb", "docs/*.md"]).inspect}"

# Hidden entries are passed over, hidden directories are not descended, and a
# symlinked directory is not followed.
# @behavior W-003
puts "--- what a walk from the base reaches ---"
puts "  #{Sumitsubo::Source::Scope.walk(base, ["**/*"], []).paths.sort.join(" ")}"

# A root the specification names and nothing wrote is an include reaching
# nothing, which is a finding rather than a crash.
# @behavior W-004
puts "--- a root nothing wrote ---"
puts "  #{Sumitsubo::Source::Scope.walk(base, ["nowhere/**/*.rb"], []).paths.inspect}"

# An excluded directory is refused rather than walked and then thrown away,
# which is what keeps a build tree from costing anything at all. What it
# refused is carried, because that is what tells an include the project
# emptied apart from one nobody could have meant.
# @behavior W-006
puts "--- a directory the walk refuses ---"
walked = Sumitsubo::Source::Scope.walk(base, ["**/*.rb"], Sumitsubo::Source::Patterns.read(["billing/"]))
puts "  reached: #{walked.paths.sort.join(" ")}"
puts "  refused: #{walked.pruned.inspect}"
puts "  billing/*.rb emptied by the project: #{Sumitsubo::Source::Scope.refused?(walked.pruned, "app/billing")}"
puts "  nowhere/*.rb nobody could have meant: #{Sumitsubo::Source::Scope.refused?(walked.pruned, "nowhere")}"

# The whole of it: patterns in, files out, with what the project excludes
# taken off.
# @behavior W-005
puts "--- what an include covers ---"
puts "  #{Sumitsubo::Source::Scope.of(base, ["**/*.rb"], []).sort.join(" ")}"
puts "  #{Sumitsubo::Source::Scope.of(base, ["**/*.rb"], Sumitsubo::Source::Patterns.read(["billing/"])).sort.join(" ")}"
# The glob this walk replaces cannot match a directory in the middle of a
# path, which is how a workspace writes an include.
# @behavior W-007
puts "  #{Sumitsubo::Source::Scope.of(base, ["app/*/*.rb"], []).sort.join(" ")}"

Dir.chdir(back)
root.rmtree
