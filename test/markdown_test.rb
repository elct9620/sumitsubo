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

# The same specification written both ways reads into the same shape. This is
# what says the format changed and nothing else did: path and line are what a
# document carries rather than what it says, so they are the only two fields
# the two sides are allowed to differ in.
require "sumitsubo/reading/json"

def agree(said, one, other)
  puts "  #{one == other ? "same" : "DIFFER"} #{said}#{one == other ? "" : " #{one.inspect} / #{other.inspect}"}"
end

def agree_on_steps(taken, given)
  agree("#{taken.key} steps", taken.attributes, given.attributes)
end

puts "--- the same specification, written both ways ---"
written = Sumitsubo::Reading::Markdown.new.behavior("test/fixtures/reading/init.md")
structured = Sumitsubo::Reading::Json.new.behavior("test/fixtures/reading/init.json")

agree("key", written.key, structured.key)
agree("text", written.text, structured.text)
agree("includes", written.includes, structured.includes)
agree("scenario count", written.statements.length, structured.statements.length)
agree("ids", written.statements.map { |one| one.key }, structured.statements.map { |one| one.key })
agree("titles", written.statements.map { |one| one.text }, structured.statements.map { |one| one.text })

index = 0
while index < written.statements.length
  agree_on_steps(written.statements[index], structured.statements[index])
  index += 1
end

# What they are allowed to differ in, said out loud so the exception is not a
# silent one: a line is where a reader goes, and the two formats write the same
# declaration in different places.
puts "  path #{written.statements[0].path} / #{structured.statements[0].path}"
puts "  line #{written.statements[0].line} / #{structured.statements[0].line}"
