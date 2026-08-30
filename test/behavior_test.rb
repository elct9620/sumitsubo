require "pathname"
require "sumitsubo/behavior"
require "sumitsubo/check/claim"
require "sumitsubo/check/reach"
require "sumitsubo/mechanism"
require "sumitsubo/specification/repository"
require "sumitsubo/source/scope"
require "sumitsubo/specification"
require "sumitsubo/grammar"
require "sumitsubo/specification/parser/markdown"

# Nothing under sumitsubo/ names a format, so a test says which it reads. This
# one reads the format features are really written in, which is why its
# snapshot is written by hand.
PARSERS = [Sumitsubo::Specification::Parser::Markdown.new(Sumitsubo::Grammar)]

# A format this build does not really carry, so that what decides which files
# are specifications is visibly the parsers rather than an extension written
# into the mechanism. There is one real format left, so a second one has to be
# stood in for.
# Features come from the repository the way a run's do, and one id twice is
# refused before anything is compared, which is what the mechanism does.
def reads(directory)
  taken(directory, PARSERS)
end

def taken(directory, parsers)
  features = Sumitsubo::Specification::Repository.new(parsers, nil)
               .all(directory, Sumitsubo::Mechanism::Behavior.new)
  Sumitsubo::Behavior.refuse_ambiguity(features)
  features
end

class Other
  SUFFIX = ".spec"

  # What a document written this way is made of. A format answers with blocks
  # and the form makes a feature of them, so this stands in for the reading
  # rather than for the meaning.
  TITLE = "Other"
  SCENARIO = "`O-001` What another format declares"

  def reads?(path) = "#{path}".end_with?(SUFFIX)

  def blocks(paths, kinds)
    found = {}
    paths.each { |path| found[path] = spoken }
    found
  end

  def spoken
    heading = Sumitsubo::Specification::Block::HEADING
    [
      Sumitsubo::Specification::Block.new(heading, 1, 1, TITLE, nil, [], []),
      Sumitsubo::Specification::Block.new(
        heading, 2, 1, SCENARIO, nil, [Sumitsubo::Specification::Span.new("O-001", 0, 7)], []
      )
    ]
  end
end

# The loader answers where a scenario sits as well as what it says. A scenario
# nothing declares is a finding about the specification, so the reader has to
# be able to go to the line that declares it.

# @behavior B-001
puts "--- what the directory declares, and where ---"
reads("test/fixtures/behavior/.spec/behavior").each do |feature|
  puts "#{feature.key} #{feature.includes.map { |one| one.key }.inspect}"
  feature.statements.each do |scenario|
    puts "  #{scenario.path}:#{scenario.line} #{scenario.key} #{scenario.text}"
    steps = scenario.attributes
    steps["given"].each { |state| puts "    given #{state}" }
    puts "    when  #{steps["when"][0]}"
    puts "    then  #{steps["then"][0]}"
  end
end

# @behavior B-002
puts "--- a directory nobody wrote declares no scenarios ---"
p reads("test/fixtures/behavior/.spec/absent")

# @behavior B-004
puts "--- one id under two scenarios leaves a marker nothing to resolve to ---"
begin
  reads("test/fixtures/behavior/duplicate")
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

# @behavior B-003
puts "--- the root arrives absolute, but a message answers where the run started ---"
begin
  reads(Pathname.pwd / "test/fixtures/behavior/duplicate")
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

# @behavior B-005
puts "--- a scenario with no id cannot be referenced at all ---"
begin
  reads("test/fixtures/behavior/anonymous")
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

# Marker hands back the whole of the line after the keyword; what counts as an
# id is this mechanism's to say.
# @behavior B-007
puts "--- several ids on one marker line ---"
p Sumitsubo::Behavior.ids_in("V-008 V-009")

# An `include` is the boundary of what a feature answers for rather than a
# list of files to read: two features over one directory reach different files,
# and the union of them is only what gets read once.
# @behavior B-011
puts "--- what each feature's include reaches ---"
base = Pathname.new("test/fixtures/behavior")
features = reads(base / ".spec/behavior")
reach = Sumitsubo::Behavior.reach(features, base, [])
features.each { |feature| puts "  #{feature.key} #{reach[feature.path].keys.sort.inspect}" }
puts "  read once: #{Sumitsubo::Behavior.scope(reach).inspect}"

# I-001 is declared by Init, whose include reaches only its own test. A claim
# of it from the file next door names the scenario without being able to
# witness it, so the scenario stands unclaimed.
claims = [Sumitsubo::Behavior::Claim.new(path: "test/fixtures/behavior/test/verify_test.rb", line: 9, id: "I-001")]

# @behavior B-012
puts "--- a scenario claimed only from outside its own feature ---"
declaring = Sumitsubo::Behavior.declaring_in(features)
witnessing = Sumitsubo::Check::Claim.witnessing(claims, declaring, reach)
Sumitsubo::Check::Claim::Unclaimed.new(Sumitsubo::Mechanism::Behavior::UNCLAIMED)
  .run(Sumitsubo::Behavior.stated_in(features), witnessing).each do |finding|
  puts "  #{finding.place.spoken} #{finding.message}"
end

# Which files in the directory are specifications is the parsers' answer: the
# build reads two formats here, so it loads the feature written in each, and
# `notes.txt` is passed over rather than refused.
# @behavior B-014
puts "--- which files a directory holds that this build can read ---"
taken("test/fixtures/behavior/formats", PARSERS + [Other.new]).each do |feature|
  puts "  #{feature.path} #{feature.key} #{feature.statements.map { |one| one.key }.inspect}"
end

# The walk answers which pattern covered nothing, and the include carries the
# line it was written on, so the reader arrives at the word to edit rather than
# at the file holding it.
# @behavior B-015
puts "--- an include covering no file answers at the line that wrote it ---"
unreached = reads("test/fixtures/behavior/nowhere")
Sumitsubo::Check::Reach::Barren.new(Sumitsubo::Mechanism::Behavior::BARREN)
  .run(Sumitsubo::Behavior.covers(unreached), Pathname.new("test/fixtures/behavior"), []).each do |finding|
  puts "  #{finding.place.spoken} #{finding.message}"
end

# @behavior B-013
puts "--- and the claim that could not witness it ---"
Sumitsubo::Check::Claim::Misplaced.new(Sumitsubo::Mechanism::Behavior::MISPLACED)
  .run(claims, declaring, reach).each do |finding|
  puts "  #{finding.place.spoken} #{finding.message}"
end
