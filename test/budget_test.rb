require "sumitsubo/budget"

# Blocks are built by hand, the way a parser answers them, so what is measured
# here reaches no grammar and its snapshot is one `--regen` writes.
def block(kind, line, text, cells = [])
  Sumitsubo::Specification::Block.new(kind, 0, line, text, nil, [], cells)
end

PARAGRAPH = Sumitsubo::Specification::Block::PARAGRAPH
ITEM = Sumitsubo::Specification::Block::ITEM
ROW = Sumitsubo::Specification::Block::ROW
CELL = Sumitsubo::Specification::Block::CELL

def show(found)
  found.each { |one| puts "  #{one.place.spoken}: #{one.check}: #{one.message}" }
  puts "  (nothing)" if found.empty?
end

THIRTY = (1..30).map { |n| "word#{n}" }.join(" ") + "."
SEVEN = "One. Two. Three. Four. Five. Six. Seven."
both = Sumitsubo::Budget.new(25, 6)

# @behavior BU-002
puts "--- a list item over its limit ---"
show(both.over("spec.md", [block(ITEM, 3, SEVEN)]))

# Twenty-three words, a span of code holding spaces and a stop of its own, and
# one more: 25 in all, so a count reading the span as words or as a stop would
# answer otherwise.
# @behavior BU-003
puts "--- inline code is one word ---"
spanned = "#{(1..23).map { |n| "w#{n}" }.join(" ")} `a. b c` end."
puts "  sentences=#{Sumitsubo::Budget.sentences(spanned).length}"
show(both.over("spec.md", [block(PARAGRAPH, 5, spanned)]))
puts "  the dot in a path ends nothing: #{Sumitsubo::Budget.sentences("Read docs/a.md and v1.2 here.").length}"

# @behavior BU-004
puts "--- a cell is measured for its sentences alone ---"
row = block(ROW, 9, "", [block(CELL, 9, SEVEN), block(CELL, 9, THIRTY)])
show(both.over("spec.md", [row]))

# @behavior BU-005
puts "--- only what the budget writes is measured ---"
show(Sumitsubo::Budget.new(25, nil).over("spec.md", [block(PARAGRAPH, 2, SEVEN)]))
puts "  measures: #{Sumitsubo::Budget.new(25, nil).measures?} #{Sumitsubo::Budget.new(nil, nil).measures?}"
