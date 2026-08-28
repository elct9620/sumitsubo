require "sumitsubo/patterns"

# Which paths a run leaves alone. The rules take the form a `.gitignore` line
# takes, and nothing here reaches the filesystem — a path is text — so `--regen`
# can write the snapshot beside it.

PATHS = [
  "src/main.rs",
  "target/debug/build.rs",
  "crates/one/src/lib.rs",
  "crates/one/target/debug/gen.rs",
  "crates/one/target",
  "docs/target.md",
  "a/b/c.rs",
  "a/b/x/y/c.rs",
  "run.log",
  "crates/one/run.log"
]

def against(*patterns)
  rules = Sumitsubo::Patterns.read(patterns)
  kept = PATHS.reject { |path| Sumitsubo::Patterns.excludes?(rules, path) }
  puts "  #{patterns.join(" ")} -> #{kept.join(" ")}"
end

# A build directory is what this was wanted for: a name with no separator
# reaches one wherever it sits, and everything under it goes with it. The file
# named after it does not, and neither does the directory read as a file.
puts "--- a directory named at any depth ---"
against("target/")

# The separator is what says where to look from. `/target/` is the one at the
# base; `crates/*/target/` is one per crate, which is the shape Dir.glob cannot
# spell in an include.
puts "--- anchored by a separator at the start or the middle ---"
against("/target/")
against("crates/*/target/")

# `**` stands for however many directories, none included.
puts "--- however many directories ---"
against("a/**/c.rs")
against("**/target/")

puts "--- a name at any depth ---"
against("*.log")
against("?.rs")

# The last rule to match decides, so the order the project wrote them in is
# what a reader follows.
puts "--- put back by a later rule ---"
against("*.log", "!crates/one/run.log")
against("!crates/one/run.log", "*.log")

puts "--- a rule matching nothing takes nothing out ---"
against("nowhere/")

def selected(pattern)
  rule = Sumitsubo::Patterns.read([pattern])[0]
  puts "  #{pattern} -> #{PATHS.select { |path| Sumitsubo::Patterns.selects?(rule, path) }.join(" ")}"
end

# An include is anchored to the base and names files, so the whole path has to
# match. `crates/*/src` is the shape a workspace is written in, and the one
# Dir.glob answers nothing for.
puts "--- what an include reaches ---"
selected("src/main.rs")
selected("crates/*/src/*.rs")
selected("a/**/c.rs")
selected("*.log")

# The same text read on the two sides. A rule with no separator reaches a name
# at any depth when it excludes, and the base and no deeper when it includes.
puts "--- the same rule read as an exclusion and as an include ---"
against("run.log")
selected("run.log")

# A .gitignore writes for a reader as well as for git, and neither the remark
# nor the blank line between sections is a pattern.
puts "--- what a .gitignore holds, less what it wrote for a reader ---"
puts Sumitsubo::Patterns.patterns_in(<<~TEXT).inspect
  # what the build leaves behind
  /target/

    vendor/
  !vendor/keep.rs
TEXT

# --- parity with Dir.glob -----------------------------------------------
#
# Taking `include` over means answering what Dir.glob answered. The rule this
# holds the matcher to: what Dir.glob matched, the matcher matches; where
# Dir.glob answered nothing for a well-formed pattern, the matcher answers.
#
# The tree is built here rather than pointed at, so the ground truth is the
# list this file wrote and not whatever the repository happens to hold.

require "pathname"

root = Pathname.new("/tmp/sumi_parity_test_#{Process.pid}")
root.rmtree if root.exist?
back = Dir.pwd
root.mkpath
Dir.chdir(root)
base = Pathname.pwd

TREE = [
  "CLAUDE.md",
  "README.md",
  ".spec/glossary.md",
  ".spec/contract/cli.json",
  ".spec/behavior/verify.md",
  "sumitsubo/config.rb",
  "sumitsubo/command/help.rb",
  "sumitsubo/language/ruby.rb",
  "test/verify_test.rb",
  "test/fixtures/app/order.rb",
  "docs/spec/glossary.md",
  "lib/kobako.rb",
  "crates/one/src/lib.rs",
  "crates/one/build.rs"
]
TREE.each do |path|
  file = base / path
  file.parent.mkpath
  file.write("")
end

def globbed(base, pattern)
  base.glob(pattern).map { |path| "#{path.relative_path_from(base)}" }.sort
end

def matched(pattern)
  rule = Sumitsubo::Patterns.read([pattern])[0]
  TREE.select { |path| Sumitsubo::Patterns.selects?(rule, path) }.sort
end

# Every shape the two projects' 23 include patterns take. Same answer both
# ways is what licenses the change.
puts "--- the shapes in use answer the same either way ---"
[
  "CLAUDE.md",
  "README.md",
  ".spec/glossary.md",
  ".spec/contract/*.json",
  ".spec/behavior/*.md",
  "sumitsubo/**/*.rb",
  "sumitsubo/command/*.rb",
  "test/*.rb",
  "test/verify_test.rb",
  "docs/**/*.md",
  "crates/**/*.rs",
  "lib/**/*.rb"
].each do |pattern|
  glob = globbed(base, pattern)
  mine = matched(pattern)
  puts "  #{glob == mine ? "same" : "DIFFERS"}  #{pattern} -> #{mine.join(" ")}"
end

# The other side of the rule: well-formed patterns the glob this replaces
# never answered, so nobody could write them. What that glob does with them is
# not asserted here — it is upstream's behavior, and it differs between the
# compiler and the CRuby run that takes this snapshot. What is asserted is the
# answer this matcher gives, which is what a later change would break.
puts "--- shapes that had no answer before ---"
[
  "crates/*/src/**/*.rs",
  "sumitsubo/**/**/*.rb",
  "sumitsubo/**"
].each { |pattern| puts "  #{pattern} -> #{matched(pattern).join(" ")}" }

# The matcher has no opinion about hidden directories, and answers inside one.
# Skipping them is the walk's, which is where the glob this replaces keeps it
# too, so this line is what the walk has to go on to disagree with.
puts "--- inside a hidden directory, which the walk and not the matcher rules on ---"
puts "  **/*.json -> #{matched("**/*.json").join(" ")}"

Dir.chdir(back)
root.rmtree
