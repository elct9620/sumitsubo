require "pathname"
require "sumitsubo"
require "sumitsubo/language"

cli = Sumitsubo::CLI.new(Sumitsubo::BUILD_REV, Sumitsubo::Language)
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

# @behavior V-019
puts "--- a finding set aside by hand, and an ignore that no longer names one ---"
Dir.chdir("test/fixtures/ignored")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# Both files drifted the same way, and `**/*.rb` covers both. What decides is
# the project having said the build directory is not its source.
# @behavior V-020
puts "--- a build directory the project excludes ---"
Dir.chdir("test/fixtures/excluded")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# The same tree, saying it through the file it already keeps. The generated
# file is committed with `git add -f`, since this repository's git reads that
# .gitignore too — and a tracked file is one git keeps and this tool still
# leaves out, which is the whole of the difference between the two readings.
# @behavior V-021
puts "--- a build directory the project's .gitignore already leaves out ---"
Dir.chdir("test/fixtures/gitignored")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# Two includes reach nothing and only one of them is wrong: what the project
# excludes is what the project asked for, while a pattern nothing ever matched
# is a vocabulary checked against nothing at all.
# @behavior V-022
puts "--- an include covering no file, beside one whose files are excluded ---"
Dir.chdir("test/fixtures/nowhere")
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

# `Store#write` is registered and the class does not declare it; the other two
# are there, so only the one answers.
# @behavior V-015
puts "--- an interface the syntax tree does not declare ---"
Dir.chdir("test/fixtures/declared")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# `Store.open` takes a parameter the contract never registered, and `Store#read`
# is defined twice with two shapes — the second of which the specification does
# not describe. `Store#write` is defined as registered, and `Store` is a class
# reopened without changing what it is: both say nothing.
# @behavior V-017 V-018
puts "--- source whose shape drifted from the contract ---"
Dir.chdir("test/fixtures/shaped")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# Read as Ruby every name in the file would answer as undefined, so what the
# run says is that the specification cannot be read.
# @behavior V-016
puts "--- a contract the language it named cannot spell ---"
Dir.chdir("test/fixtures/unresolvable")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

root = Pathname.new("/tmp/sumi_verify_test_#{Process.pid}")
root.rmtree if root.exist?
root.mkpath
Dir.chdir(root)

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
