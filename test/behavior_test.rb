require "pathname"
require "sumitsubo/behavior"

# The loader answers where a scenario sits as well as what it says. A scenario
# nothing declares is a finding about the specification, so the reader has to
# be able to go to the line that declares it — which is why the raw text is
# read alongside the parsed document.
#
# Nothing here reaches the grammar, so --regen can still write this snapshot.

# @behavior B-001
puts "--- what the directory declares, and where ---"
Sumitsubo::Behavior.load("test/fixtures/behavior/.spec/behavior").each do |feature|
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
p Sumitsubo::Behavior.load("test/fixtures/behavior/.spec/absent")

# @behavior B-004
puts "--- one id under two scenarios leaves a marker nothing to resolve to ---"
begin
  Sumitsubo::Behavior.load("test/fixtures/behavior/duplicate")
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

# @behavior B-003
puts "--- the root arrives absolute, but a message answers where the run started ---"
begin
  Sumitsubo::Behavior.load(Pathname.pwd / "test/fixtures/behavior/duplicate")
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

# @behavior B-005
puts "--- a scenario with no id cannot be referenced at all ---"
begin
  Sumitsubo::Behavior.load("test/fixtures/behavior/anonymous")
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

# @behavior B-006
puts "--- and neither is a specification that will not parse ---"
begin
  Sumitsubo::Behavior.load("test/fixtures/behavior/broken")
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
Sumitsubo::Behavior.load("test/fixtures/behavior/oneline").each do |feature|
  feature.statements.each { |scenario| puts "  #{scenario.line} #{scenario.key}" }
end

# An `include` is the boundary of what a feature answers for rather than a
# list of files to read: two features over one directory reach different files,
# and the union of them is only what gets read once.
# @behavior B-011
puts "--- what each feature's include reaches ---"
base = Pathname.new("test/fixtures/behavior")
features = Sumitsubo::Behavior.load(base / ".spec/behavior")
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

# @behavior B-013
puts "--- and the claim that could not witness it ---"
Sumitsubo::Behavior.misplaced(features, claims, reach).each do |claim|
  puts "  #{claim.path}:#{claim.line} #{Sumitsubo::Behavior.describe_misplaced(claim)}"
end
