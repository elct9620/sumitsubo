require "sumitsubo/definitions"

# The syntax tree reading: what a Ruby file declares, spelled the way a contract
# would have to name it.
#
# This reaches the grammar, so the snapshot beside it is written by hand —
# `--regen` runs under CRuby, which has no `ffi_func`.

FIXTURE = "test/fixtures/definitions"

def show(path)
  Sumitsubo::Definitions.names_in(path).each do |name|
    puts "  #{name.path}:#{name.line} #{name.name}#{signature(name)}"
  end
end

# The parameters as a caller would have to satisfy them: the name, the kind,
# and a `?` where the caller may leave it out. A dash stands where Ruby let the
# parameter go unnamed.
def signature(name)
  return "" if name.params.nil?

  spelled = []
  name.params.each do |param|
    spelled.push("#{param.name.nil? ? "-" : param.name}:#{param.kind}#{param.optional ? "?" : ""}")
  end
  " (#{spelled.join(", ")})"
end

# One file answers five: `Outer::Inner` is qualified by its nesting, `.load`
# and `#check` are told apart the way Ruby spells them, `Flat::Scoped` is
# written as a path rather than nested, `loose` sits outside every scope, and
# `Reopened.built` belongs to its class though it is written as an instance method.
#
# `Signed` then answers what each method takes: the kind Ruby's spelling gives
# each parameter, which of them a caller may leave out, the ones Ruby let go
# unnamed, and the difference between a method taking none and a scope taking
# no parameters at all. `**nil` names no parameter, so `#strict` answers one.
#
# What the reading does not carry is declared here too: `Called` answers itself
# and neither of the methods its calls bring into being, and `Widget` answers
# itself without the method it mixes in.
# @behavior D-001 D-002 D-003 D-004 D-007 D-008 D-009 D-010 D-011 D-012 D-013
# @behavior D-014 D-015
puts "--- what a file declares ---"
show("#{FIXTURE}/sample.rb")

# @behavior D-006
puts "--- source the grammar cannot read ---"
begin
  show("test/fixtures/behavior/test/broken.rb")
rescue Sumitsubo::Definitions::Error => e
  puts "  #{e.message}"
end
