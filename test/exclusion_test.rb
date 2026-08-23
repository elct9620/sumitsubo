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
