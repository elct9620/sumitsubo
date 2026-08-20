require "pathname"
require "sumitsubo/behavior"

# The loader answers where a scenario sits as well as what it says. A scenario
# nothing declares is a finding about the specification, so the reader has to
# be able to go to the line that declares it — which is why the raw text is
# read alongside the parsed document.
#
# Nothing here reaches the grammar, so this snapshot can be regenerated. See
# the Build section of CLAUDE.md for what that buys.

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

puts "--- a directory nobody wrote declares no scenarios ---"
p Sumitsubo::Behavior.load("test/fixtures/behavior/.spec/absent")

puts "--- one id under two scenarios leaves a marker nothing to resolve to ---"
begin
  Sumitsubo::Behavior.load("test/fixtures/behavior/duplicate")
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

puts "--- the root arrives absolute, but a message answers where the run started ---"
begin
  Sumitsubo::Behavior.load(Pathname.pwd / "test/fixtures/behavior/duplicate")
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

puts "--- a scenario with no id cannot be referenced at all ---"
begin
  Sumitsubo::Behavior.load("test/fixtures/behavior/anonymous")
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end

puts "--- and neither is a specification that will not parse ---"
begin
  Sumitsubo::Behavior.load("test/fixtures/behavior/broken")
rescue Sumitsubo::Behavior::Error => e
  puts e.message
end
