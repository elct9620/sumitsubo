require "sumitsubo/declaration"

# The syntax tree reading: what a Ruby file declares, spelled the way a contract
# would have to name it.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.

FIXTURE = "test/fixtures/declaration"

def show(path)
  Sumitsubo::Declaration.names_in(path).each do |name|
    puts "  #{name.path}:#{name.line} #{name.name}"
  end
end

puts "--- what a file declares ---"
show("#{FIXTURE}/sample.rb")

puts "--- a file that is not Ruby declares nothing ---"
show("test/fixtures/behavior/test/overview.md")

puts "--- source the grammar cannot read ---"
begin
  show("test/fixtures/behavior/test/broken.rb")
rescue Sumitsubo::Declaration::Error => e
  puts "  #{e.message}"
end
