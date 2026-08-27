require "pathname"
require "sumitsubo/behavior"
require "sumitsubo/scope"
require "sumitsubo/specification"
require "sumitsubo/parser/json"

# Nothing under sumitsubo/ names a format, so a test says which it reads.
PARSERS = [Sumitsubo::Parser::Json.new]

# A format this build does not really carry, so that what decides which files
# are specifications is visibly the parsers rather than an extension written
# into the mechanism. A real second format reaches a grammar; this one answers
# what it was asked for, which is what keeps this file's snapshot writable.
class Other
  SUFFIX = ".spec"

  def reads?(path) = "#{path}".end_with?(SUFFIX)

  def behavior(path)
    where = "#{path}"
    Sumitsubo::Specification.new("Other", nil, [], where, {}, [
      Sumitsubo::Statement.new("O-001", "What another format declares", where, 1, { "given" => [] }, [])
    ])
  end
end

# The loader answers where a scenario sits as well as what it says. A scenario
# nothing declares is a finding about the specification, so the reader has to
# be able to go to the line that declares it — which is why the raw text is
# read alongside the parsed document.
#
# Nothing here reaches the grammar, so --regen can still write this snapshot.

# @behavior B-001
puts "--- what the directory declares, and where ---"
Sumitsubo::Behavior.load("test/fixtures/behavior/.spec/behavior", PARSERS).each do |feature|
  puts "#{feature.key} #{feature.includes.inspect}"
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
p Sumitsubo::Behavior.load("test/fixtures/behavior/.spec/absent", PARSERS)

# @behavior B-004
puts "--- one id under two scenarios leaves a marker nothing to resolve to ---"
begin
  Sumitsubo::Behavior.load("test/fixtures/behavior/duplicate", PARSERS)
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

# @behavior B-003
puts "--- the root arrives absolute, but a message answers where the run started ---"
begin
  Sumitsubo::Behavior.load(Pathname.pwd / "test/fixtures/behavior/duplicate", PARSERS)
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

# @behavior B-005
puts "--- a scenario with no id cannot be referenced at all ---"
begin
  Sumitsubo::Behavior.load("test/fixtures/behavior/anonymous", PARSERS)
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

# @behavior B-006
puts "--- and neither is a specification that will not parse ---"
begin
  Sumitsubo::Behavior.load("test/fixtures/behavior/broken", PARSERS)
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

# Marker hands back the whole of the line after the keyword; what counts as an
# id is this mechanism's to say.
# @behavior B-007
puts "--- several ids on one marker line ---"
p Sumitsubo::Behavior.ids_in("V-008 V-009")

# A scenario written on the same line as the one before it still has a line to
# answer at, which is what a finding about it needs.
# @behavior B-008
puts "--- two scenarios on one line ---"
Sumitsubo::Behavior.load("test/fixtures/behavior/oneline", PARSERS).each do |feature|
  feature.statements.each { |scenario| puts "  #{scenario.line} #{scenario.key}" }
end

# An `include` is the boundary of what a feature answers for rather than a
# list of files to read: two features over one directory reach different files,
# and the union of them is only what gets read once.
# @behavior B-011
puts "--- what each feature's include reaches ---"
base = Pathname.new("test/fixtures/behavior")
features = Sumitsubo::Behavior.load(base / ".spec/behavior", PARSERS)
reach = Sumitsubo::Behavior.reach(features, base, [])
features.each { |feature| puts "  #{feature.key} #{reach[feature.path].keys.sort.inspect}" }
puts "  read once: #{Sumitsubo::Behavior.scope(reach).inspect}"

# I-001 is declared by Init, whose include reaches only its own test. A claim
# of it from the file next door names the scenario without being able to
# witness it, so the scenario stands unclaimed.
claims = [Sumitsubo::Behavior::Claim.new("test/fixtures/behavior/test/verify_test.rb", 9, "I-001")]

# @behavior B-012
puts "--- a scenario claimed only from outside its own feature ---"
witnessing = Sumitsubo::Behavior.witnessing(features, claims, reach)
Sumitsubo::Behavior.uncovered(features, witnessing).each do |finding|
  puts "  #{finding.path}:#{finding.line} #{Sumitsubo::Behavior.describe_uncovered(finding)}"
end

# Which files in the directory are specifications is the parsers' answer: the
# build reads two formats here, so it loads the feature written in each, and
# `notes.txt` is passed over rather than refused.
# @behavior B-014
puts "--- which files a directory holds that this build can read ---"
Sumitsubo::Behavior.load("test/fixtures/behavior/formats", PARSERS + [Other.new]).each do |feature|
  puts "  #{feature.path} #{feature.key} #{feature.statements.map { |one| one.key }.inspect}"
end

# The walk answers which pattern covered nothing; where that pattern was
# written is asked of the parser that read the specification, so the reader
# arrives at the word to edit rather than at the file holding it.
# @behavior B-015
puts "--- an include covering no file answers at the line that wrote it ---"
unreached = Sumitsubo::Behavior.load("test/fixtures/behavior/nowhere", PARSERS)
Sumitsubo::Behavior.barren(unreached, Pathname.new("test/fixtures/behavior"), [], PARSERS).each do |barren|
  puts "  #{barren.path}:#{barren.line} #{Sumitsubo::Scope.describe(barren)}"
end

# @behavior B-013
puts "--- and the claim that could not witness it ---"
Sumitsubo::Behavior.misplaced(features, claims, reach).each do |claim|
  puts "  #{claim.path}:#{claim.line} #{Sumitsubo::Behavior.describe_misplaced(claim)}"
end
