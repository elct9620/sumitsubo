require "pathname"
require "sumitsubo"
require "sumitsubo/source/language"
require "sumitsubo/source/language/prose"
require "sumitsubo/source/language/ruby"
require "sumitsubo/source/language/rust"

# What this test carries, built the way `bin/sumi.rb` builds it: a reading is
# handed the grammar it puts its queries to.
LANGUAGES = Sumitsubo::Source::Language.new([
  Sumitsubo::Source::Language::Ruby.new(Sumitsubo::Grammar),
  Sumitsubo::Source::Language::Rust.new(Sumitsubo::Grammar),
  Sumitsubo::Source::Language::Prose.new
])
require "sumitsubo/grammar"
require "sumitsubo/specification/parser/markdown"

# A run is handed what this build carries, the way `bin/sumi.rb` hands it. This
# file already crosses into the binding through the languages, so the grammar
# the parser reads through costs it nothing it had not already paid.
cli = Sumitsubo::CLI.new(
  Sumitsubo::BUILD_REV, LANGUAGES,
  [Sumitsubo::Specification::Parser::Markdown.new(Sumitsubo::Grammar)]
)
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

# Two claims this run cannot compare against anything: one names a scenario
# that is not there at all, and the other names one whose feature does not
# include the file it sits in — so it resolves, and still witnesses nothing.
# @behavior V-006 V-023
puts "--- claims that resolve to nothing a run can compare against ---"
Dir.chdir("test/fixtures/behavior")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-007 V-011
puts "--- a mechanism that cannot be read leaves the others still answering ---"
Dir.chdir("test/fixtures/unparseable")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# One run answers all four: `verify` is registered and claimed nowhere, `init`
# is claimed twice, `render` is claimed but registered nowhere, and the one
# claim of `verify` sits in a file only the routes definition includes — read,
# and unable to implement a contract the CLI definition registers.
# @behavior V-012 V-013 V-014 V-024
puts "--- an interface nothing claims, one claimed twice, one registered nowhere, and one claimed out of reach ---"
Dir.chdir("test/fixtures/contracted")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# `Store#write` is registered and the class does not declare it; the other two
# are there, so only the one answers. The worker declares a `Store#write` of
# its own, in a file the API definition does not include — a class sharing a
# registered name defines nothing for it, and nothing answers for the class.
# @behavior V-015 V-025
puts "--- an interface the syntax tree does not declare ---"
Dir.chdir("test/fixtures/declared")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# `Store.open` takes a parameter the contract never registered, and `Store#read`
# is defined twice with two shapes — the second of which the specification does
# not describe. `Store#write` is defined as registered, and `Store` is a class
# reopened without changing what it is: both say nothing.
#
# `Store::Held` is registered through the class body a call writes, which the
# signature spells as the source does. It is compared like any other: the
# constant is the scope holding the contract, and the method inside it drifted.
# @behavior V-017 V-018 V-028
puts "--- source whose shape drifted from the contract ---"
Dir.chdir("test/fixtures/shaped")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# The marker that made these claims went missing, and nothing was put in its
# place, so what the run says is that the specification cannot be read rather
# than reporting every name in it as undefined.
# @behavior V-016
puts "--- a definition that lost the word its contracts were claimed with ---"
Dir.chdir("test/fixtures/unresolvable")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# A barren include answers at the line that wrote it, which in this format is
# a list item in backticks rather than a quoted value.
# @behavior V-027
puts "--- a feature whose include covers no file ---"
Dir.chdir("test/fixtures/markdown")
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
