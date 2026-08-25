require "sumitsubo/reading/markdown"

# Reading a real Markdown specification through the grammar linked into this
# build. What the query has to get right is which blocks a document is made of
# and where they sit; what those blocks mean is Blocks', and tested beside it
# on the side `--regen` can still write.
#
# This test crosses into the binding, so it can never be regenerated: `spin
# test --regen` produces its snapshot by running the file under CRuby, which
# has no `ffi_func`. The snapshot below is written by hand and stays that way.

# Spelled as a method rather than a block inside a block: an inner iteration
# capturing an outer block's variable is a shape the compiler refuses.
def steps_of(scenario)
  steps = scenario.attributes
  steps.keys.each { |name| said(name, steps[name]) }
end

def said(name, holding)
  holding.each { |one| puts "    #{name} #{one}" }
end

feature = Sumitsubo::Reading::Markdown.new.behavior("test/fixtures/reading/init.md")

puts "#{feature.key} #{feature.includes.inspect}"
puts "  #{feature.text}"
feature.statements.each do |scenario|
  puts "  #{scenario.path}:#{scenario.line} #{scenario.key} #{scenario.text}"
  steps_of(scenario)
end

# The extension is the whole of what says a file is written this way, so a
# reading is asked rather than told.
reading = Sumitsubo::Reading::Markdown.new
p [reading.reads?("init.md"), reading.reads?("init.json"), reading.reads?(".spec/behavior/init.md")]
