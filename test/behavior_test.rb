require "pathname"
require "sumitsubo/behavior"

# The loader answers where a scenario sits as well as what it says. A scenario
# nothing declares is a finding about the specification, so the reader has to
# be able to go to the line that declares it — which is why the raw text is
# read alongside the parsed document.
#
# Nothing here reaches the grammar, so this snapshot can be regenerated. See
# the Build section of CLAUDE.md for what that buys.

# @behavior B-001
puts "--- what the directory declares, and where ---"
Sumitsubo::Behavior.load("test/fixtures/behavior/.spec/behavior").each do |feature|
  puts "#{feature.name} #{feature.includes.inspect}"
  feature.scenarios.each do |scenario|
    puts "  #{scenario.path}:#{scenario.line} #{scenario.id} #{scenario.title}"
    scenario.given.each { |state| puts "    given #{state}" }
    puts "    when  #{scenario.action}"
    puts "    then  #{scenario.outcome}"
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
  feature.scenarios.each { |scenario| puts "  #{scenario.line} #{scenario.id}" }
end
