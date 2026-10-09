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
Dir.chdir("test/fixtures/project/glossary")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-002
puts "--- the same run from a subdirectory: same findings, paths from where it started ---"
Dir.chdir("test/fixtures/project/glossary/app")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-019
puts "--- a finding set aside by hand, and an ignore that no longer names one ---"
Dir.chdir("test/fixtures/project/ignored")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# Both files drifted the same way, and `**/*.rb` covers both. What decides is
# the project having said the build directory is not its source.
# @behavior V-020
puts "--- a build directory the project excludes ---"
Dir.chdir("test/fixtures/project/excluded")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# The same tree, saying it through the file it already keeps. The generated
# file is committed with `git add -f`, since this repository's git reads that
# .gitignore too — and a tracked file is one git keeps and this tool still
# leaves out, which is the whole of the difference between the two readings.
# @behavior V-021
puts "--- a build directory the project's .gitignore already leaves out ---"
Dir.chdir("test/fixtures/project/gitignored")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# Two includes reach nothing and only one of them is wrong: what the project
# excludes is what the project asked for, while a pattern nothing ever matched
# is a vocabulary checked against nothing at all.
# @behavior V-022
puts "--- an include covering no file, beside one whose files are excluded ---"
Dir.chdir("test/fixtures/project/nowhere")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-003
puts "--- a specification switched off is not read, however far the code drifted ---"
Dir.chdir("test/fixtures/project/disabled")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-004
puts "--- every scenario claimed, so the two sides agree ---"
Dir.chdir("test/fixtures/project/aligned")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-005
puts "--- a scenario nothing claims answers at the specification ---"
Dir.chdir("test/fixtures/project/uncovered")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# Two claims this run cannot compare against anything: one names a scenario
# that is not there at all, and the other names one whose feature does not
# include the file it sits in — so it resolves, and still witnesses nothing.
# The file also ends on a run of comments, one of them a claim. It stands in
# front of nothing, so it witnesses nothing and says so where it was written
# rather than leaving the scenario reported as claimed nowhere.
# One of them carries no id at all, which names no scenario rather than naming
# one that resolves to none.
# @behavior V-006 V-023 V-030 V-031
puts "--- claims that resolve to nothing a run can compare against ---"
Dir.chdir("test/fixtures/project/behavior")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-007 V-011
puts "--- a mechanism that cannot be read leaves the others still answering ---"
Dir.chdir("test/fixtures/project/unparseable")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# One run answers all four: `verify` is registered and claimed nowhere, `init`
# is claimed twice, `render` is claimed but registered nowhere, and the one
# claim of `verify` sits in a file only the routes definition includes — read,
# and unable to implement a contract the CLI definition registers.
# @behavior V-012 V-013 V-014 V-024
puts "--- an interface nothing claims, one claimed twice, one registered nowhere, and one claimed out of reach ---"
Dir.chdir("test/fixtures/project/contracted")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# `Store#write` is registered and the class does not declare it; the other two
# are there, so only the one answers. The worker declares a `Store#write` of
# its own, in a file the API definition does not include — a class sharing a
# registered name defines nothing for it, and nothing answers for the class.
# @behavior V-015 V-025
puts "--- an interface the syntax tree does not declare ---"
Dir.chdir("test/fixtures/project/declared")
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
Dir.chdir("test/fixtures/project/shaped")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# The marker that made these claims went missing, and nothing was put in its
# place, so what the run says is that the specification cannot be read rather
# than reporting every name in it as undefined.
# @behavior V-016
puts "--- a definition that lost the word its contracts were claimed with ---"
Dir.chdir("test/fixtures/project/unresolvable")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# A barren include answers at the line that wrote it, which in this format is
# a list item in backticks rather than a quoted value.
# @behavior V-027
puts "--- a feature whose include covers no file ---"
Dir.chdir("test/fixtures/project/markdown")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# One root holding both: the specifications are read as such, and the document
# beside them — in no form at all — as the source an include reaches. That is
# what lets a project keep its prose where its reference line already is.
# @behavior V-029
puts "--- a root the project also keeps its prose in ---"
Dir.chdir("test/fixtures/project/coexisting")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# One run over two languages, which the four findings are one of each of. The
# glossary reaches both and a language is chosen for each file by what it is,
# while the two definitions each reach one and read it as the language their
# own signatures are spelled in. A shape that disagrees is what says the source
# was really read: a name found nowhere would answer the same whether the file
# was read or never opened.
# @behavior V-032
puts "--- a project written in two languages, read in one run ---"
Dir.chdir("test/fixtures/project/polyglot")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# The difference is the point: it comes from the document beside the one that
# could not be read, so it stands as proof the run went on rather than stopping
# at the refusal. A run that stopped would answer the refusal alone.
# @behavior V-033
puts "--- a specification nobody could read, beside one that answers ---"
Dir.chdir("test/fixtures/project/beside")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# A name is what a claim names, so one standing for two things leaves every
# claim of it resolving to neither. No document answers for that by itself,
# which is why it is refused across the directory rather than in one of them.
# Both mechanisms keeping a directory answer it, and each answers for its own.
# @behavior V-034
puts "--- one name declared twice, in each specification that keeps a directory ---"
Dir.chdir("test/fixtures/project/twice")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# A scenario, a claimed interface and a defined one each say nothing can hold
# them yet, and the source has each of them. A scenario and an interface saying
# the same that the source does not have are not compared at all.
# @behavior V-035
puts "--- what the source holds of what was set aside ---"
Dir.chdir("test/fixtures/project/unverifiable")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# A vocabulary is one document, so its refusals reach the run all at once
# rather than one per file. Two of them is what tells each being answered
# from only the first.
# @behavior V-036 V-041 V-042
puts "--- a vocabulary refused in two places, beside a feature that answers ---"
Dir.chdir("test/fixtures/project/misshapen")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# Each scenario names one statement by key: one declared and one not, of its
# own mechanism and of the contracts. Only the two naming nothing answer.
# @behavior V-044
puts "--- a relation naming a statement nobody declares ---"
Dir.chdir("test/fixtures/project/related")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# The same scenarios with the contracts switched off. What a relation names is
# looked up all the same, and the one contract relating to a scenario nobody
# declares is not compared, since its own mechanism is off.
# @behavior V-045 V-046
puts "--- relations beside a switched-off mechanism ---"
Dir.chdir("test/fixtures/project/related-off")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# The switched-off contracts are written out of shape. Reading them for what
# a relation names is the first time they are read, so the refusal is answered
# there, and a relation into them names what nobody could look up.
# @behavior V-047
puts "--- a switched-off mechanism named by a relation and refused ---"
Dir.chdir("test/fixtures/project/related-unread")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# A contract writes relations too, and a scenario names a term, which the
# vocabulary keeps a level deeper than a feature keeps its scenarios.
# @behavior V-048 V-049
puts "--- relations a contract writes, and relations naming a term ---"
Dir.chdir("test/fixtures/project/related-terms")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# The feature names a word from each subdomain and reaches only the screens,
# so the one answering is what shows its includes chose the section.
# @behavior V-037
puts "--- a feature speaks the words of the subdomain its includes reach ---"
Dir.chdir("test/fixtures/project/reached")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# The same project with Behavior switched off: the feature is never read, so
# the word it uses answers nowhere.
# @behavior V-038
puts "--- a feature switched off is not held to the vocabulary ---"
Dir.chdir("test/fixtures/project/reached-off")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# Two features declaring one id are refused as a set, and the refusal is
# Behavior's to answer: it answers once, and neither is held to a word.
# @behavior V-039
puts "--- features refused together are not held to the vocabulary ---"
Dir.chdir("test/fixtures/project/reached-twice")
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

# No fixture has two checks answering about one line, so the findings are built
# here: what is shown is how a report words and orders them, whichever check
# made them.
# @behavior V-040 V-043
puts "--- a finding names the check that found it ---"
found = Sumitsubo::Finding::Repository.new
at = Sumitsubo::Place.of("app/order.rb", 2)
found.add(Sumitsubo::Finding.new(check: "glossary/rejected", difference: true, place: at, message: "a word turned down"))
found.add(Sumitsubo::Finding.new(check: "contract/mismatched", difference: true, place: at, message: "the shape drifted"))
Sumitsubo::Finding::Report.new(found).lines.each { |line| puts line }

# @behavior V-050
puts "--- a vocabulary covering its own file, from the root and from a subdirectory ---"
Dir.chdir("test/fixtures/project/self-covering")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir("app")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-051
puts "--- a contract claim with no code under it ---"
Dir.chdir("test/fixtures/project/contract-dangling")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)

# @behavior V-052 V-053
puts "--- relations naming a contract and a term more than one statement answers to ---"
Dir.chdir("test/fixtures/project/related-ambiguous")
puts "exit=#{cli.run(["verify"])}"
Dir.chdir(back)
