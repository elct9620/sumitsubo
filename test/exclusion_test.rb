require "sumitsubo/exclusion"

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
  rules = Sumitsubo::Exclusion.read(patterns)
  kept = PATHS.reject { |path| Sumitsubo::Exclusion.excludes?(rules, path) }
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
  rule = Sumitsubo::Exclusion.read([pattern])[0]
  puts "  #{pattern} -> #{PATHS.select { |path| Sumitsubo::Exclusion.selects?(rule, path) }.join(" ")}"
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
puts Sumitsubo::Exclusion.patterns_in(<<~TEXT).inspect
  # what the build leaves behind
  /target/

    vendor/
  !vendor/keep.rs
TEXT
