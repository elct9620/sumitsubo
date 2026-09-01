require "sumitsubo/source/patterns"

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
  rules = Sumitsubo::Source::Patterns.read(patterns)
  kept = PATHS.reject { |path| Sumitsubo::Source::Patterns.excludes?(rules, path) }
  puts "  #{patterns.join(" ")} -> #{kept.join(" ")}"
end

# A build directory is what this was wanted for: a name with no separator
# reaches one wherever it sits, and everything under it goes with it. The file
# named after it does not, and neither does the directory read as a file.
# @behavior P-001
puts "--- a directory named at any depth ---"
against("target/")

# The separator is what says where to look from. `/target/` is the one at the
# base, and `crates/*/target/` is one per crate.
# @behavior P-002
puts "--- anchored by a separator at the start or the middle ---"
against("/target/")
against("crates/*/target/")

# `**` stands for however many directories, none included.
# @behavior P-003
puts "--- however many directories ---"
against("a/**/c.rs")
against("**/target/")

# @behavior P-004
puts "--- a name at any depth ---"
against("*.log")
against("?.rs")

# The last rule to match decides, so the order the project wrote them in is
# what a reader follows.
# @behavior P-005
puts "--- put back by a later rule ---"
against("*.log", "!crates/one/run.log")
against("!crates/one/run.log", "*.log")

# @behavior P-006
puts "--- a rule matching nothing takes nothing out ---"
against("nowhere/")

def selected(pattern)
  rule = Sumitsubo::Source::Patterns.read([pattern])[0]
  puts "  #{pattern} -> #{PATHS.select { |path| Sumitsubo::Source::Patterns.selects?(rule, path) }.join(" ")}"
end

# An include is anchored to the base and names files, so the whole path has to
# match. `crates/*/src` is the shape a workspace is written in.
# @behavior P-007
puts "--- the whole path has to match ---"
selected("src/main.rs")
selected("crates/*/src/*.rs")
selected("a/**/c.rs")
selected("*.log")

# The same text read on the two sides. A rule with no separator reaches a name
# at any depth when it excludes, and the base and no deeper when it includes.
# @behavior P-008
puts "--- the same rule read as an exclusion and as an include ---"
against("run.log")
selected("run.log")

# A .gitignore writes for a reader as well as for git, and neither the remark
# nor the blank line between sections is a pattern.
# @behavior P-009
puts "--- what a .gitignore holds, less what it wrote for a reader ---"
puts Sumitsubo::Source::Patterns.patterns_in(<<~TEXT).inspect
  # what the build leaves behind
  /target/

    vendor/
  !vendor/keep.rs
TEXT

# --- what an include reaches --------------------------------------------
#
# The tree is written here rather than pointed at, so the ground truth is the
# list this file holds and not whatever the repository happens to carry.

TREE = [
  "CLAUDE.md",
  "README.md",
  ".spec/glossary.md",
  ".spec/contract/cli.json",
  ".spec/behavior/verify.md",
  "sumitsubo/config.rb",
  "sumitsubo/command/help.rb",
  "sumitsubo/source/language/ruby.rb",
  "test/verify_test.rb",
  "test/fixtures/app/order.rb",
  "docs/spec/glossary.md",
  "lib/kobako.rb",
  "crates/one/src/lib.rs",
  "crates/one/build.rs"
]

def matched(pattern)
  rule = Sumitsubo::Source::Patterns.read([pattern])[0]
  TREE.select { |path| Sumitsubo::Source::Patterns.selects?(rule, path) }.sort
end

# Every shape the two projects' includes take, and three nobody has written
# yet. A trailing `**` is the one place the two forms an include could be read
# against part company: a `.gitignore` reads it as everything inside, at any
# depth, and a glob reads it as one level. An include takes the form a
# `.gitignore` line takes, so `sumitsubo/**` reaches every depth.
# @behavior P-010
puts "--- what each shape an include is written in reaches ---"
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
  "lib/**/*.rb",
  "crates/*/src/**/*.rs",
  "sumitsubo/**/**/*.rb",
  "sumitsubo/**"
].each { |pattern| puts "  #{pattern} -> #{matched(pattern).join(" ")}" }

# The matcher has no opinion about hidden directories, and answers inside one.
# Skipping them is the walk's, which is where `Dir.glob` keeps it too, so this
# line is what the walk has to go on to disagree with.
# @behavior P-012
puts "--- inside a hidden directory, which the walk and not the matcher rules on ---"
puts "  **/*.json -> #{matched("**/*.json").join(" ")}"

# A pattern and a path are read by the characters they were written in. The
# star after a name outside ASCII is what tells that apart from the bytes: the
# two counts differ there, and every other shape here happens to agree.
# @behavior P-013
puts "--- a pattern written outside ASCII ---"
WIDE = ["說明.rb", "說.rb", "前記.rb", "abc.rb"]
["說*.rb", "*記.rb", "?記.rb", "說明*"].each do |pattern|
  rule = Sumitsubo::Source::Patterns.read([pattern])[0]
  found = WIDE.select { |path| Sumitsubo::Source::Patterns.selects?(rule, path) }
  puts "  #{pattern} -> #{found.join(" ")}"
end
