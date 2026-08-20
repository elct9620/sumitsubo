require "sumitsubo/behavior"
require "sumitsubo/marker"

# What a piece of source claims to implement, read through the grammar.
#
# This test crosses into the binding, so it can never be regenerated: `spin
# test --regen` produces its snapshot by running the file under CRuby, which
# has no ffi_func. The snapshot beside it is written by hand and stays that way.

def claims(path)
  Sumitsubo::Marker.claims_in(path, Sumitsubo::Behavior::MARKER)
    .map { |claim| "#{claim.path}:#{claim.line} #{claim.id}" }
end

# The claim attaches to whatever statement follows it, so a linear script needs
# no method to hold one. G-999 sits at the end of the file with nothing after
# it, and a comment nothing follows claims nothing.
# @behavior M-001 M-004 M-005
puts "--- a linear snapshot script ---"
claims("test/fixtures/behavior/test/verify_test.rb").each { |line| puts line }

# Depth is not a barrier: a class body, a method body and a block comment all
# hold claims, and a block comment answers at the line its keyword is on.
# @behavior M-002 M-003
puts "--- methods, nesting, and a block comment ---"
claims("test/fixtures/behavior/test/init_test.rb").each { |line| puts line }

# @behavior M-006
puts "--- prose is not code, so it claims nothing ---"
p claims("test/fixtures/behavior/test/overview.md")

# @behavior M-007
puts "--- source the grammar cannot read is not a claim of anything ---"
begin
  claims("test/fixtures/behavior/test/broken.rb")
rescue Sumitsubo::Marker::Error => e
  puts e.message
end
