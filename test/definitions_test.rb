require "sumitsubo/definitions"

# The syntax tree reading: what a Ruby file declares, spelled the way a contract
# would have to name it.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.

FIXTURE = "test/fixtures/definitions"

def show(path)
  Sumitsubo::Definitions.names_in(path).each do |name|
    puts "  #{name.path}:#{name.line} #{name.name}"
  end
end

# One file answers five: `Outer::Inner` is qualified by its nesting, `.load`
# and `#check` are told apart the way Ruby spells them, `Flat::Scoped` is
# written as a path rather than nested, `loose` sits outside every scope, and
# `Reopened.built` belongs to its class though it is written as an instance method.
# @behavior D-001 D-002 D-003 D-004 D-007
puts "--- what a file declares ---"
show("#{FIXTURE}/sample.rb")

# @behavior D-005
puts "--- a file that is not Ruby declares nothing ---"
show("test/fixtures/behavior/test/overview.md")

# @behavior D-006
puts "--- source the grammar cannot read ---"
begin
  show("test/fixtures/behavior/test/broken.rb")
rescue Sumitsubo::Definitions::Error => e
  puts "  #{e.message}"
end
