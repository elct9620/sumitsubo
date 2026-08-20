require "pathname"
require "sumitsubo/behavior"
require "sumitsubo/marker"

# What a piece of source claims to implement, read through the grammar.
#
# This test crosses into the binding, so it can never be regenerated: `spin
# test --regen` produces its snapshot by running the file under CRuby, which
# has no ffi_func. The snapshot beside it is written by hand and stays that way.

BEHAVIOR = [Sumitsubo::Behavior::MARKER]

# The text is bracketed because a keyword with nothing after it carries an
# empty one, and a snapshot cannot hold the trailing space that would leave.
def claims(path, keywords)
  Sumitsubo::Marker.claims_in(path, keywords)
    .map { |claim| "#{claim.path}:#{claim.line} #{claim.keyword} [#{claim.text}]" }
end

# The claim attaches to whatever statement follows it, so a linear script needs
# no method to hold one. G-999 sits at the end of the file with nothing after
# it, and a comment nothing follows claims nothing.
# @behavior M-001 M-004 M-005
puts "--- a linear snapshot script ---"
claims("test/fixtures/behavior/test/verify_test.rb", BEHAVIOR).each { |line| puts line }

# Depth is not a barrier: a class body, a method body and a block comment all
# hold claims, and a block comment answers at the line its keyword is on.
# @behavior M-002 M-003
puts "--- methods, nesting, and a block comment ---"
claims("test/fixtures/behavior/test/init_test.rb", BEHAVIOR).each { |line| puts line }

# @behavior M-006
puts "--- prose is not code, so it claims nothing ---"
p claims("test/fixtures/behavior/test/overview.md", BEHAVIOR)

# @behavior M-007
puts "--- source the grammar cannot read is not a claim of anything ---"
begin
  claims("test/fixtures/behavior/test/broken.rb", BEHAVIOR)
rescue Sumitsubo::Marker::Error => e
  puts e.message
end

# A caller reaching a mechanism other than Behavior has no reason to have
# rendered the path first, so the reading answers for itself.
# @behavior M-008
puts "--- a path that arrives absolute still answers where the run started ---"
claims(Pathname.new("test/fixtures/behavior/test/init_test.rb").expand_path.to_s, BEHAVIOR)
  .each { |line| puts line }

# Parsing is the cost, so a whole set of keywords is read in one pass. The
# route carries the space a list reading would have split on, which is why
# what follows a keyword is handed back unread.
# @behavior M-009 M-010
puts "--- two keywords in one pass, and one with nothing after it ---"
claims("test/fixtures/marker/two_keywords.rb", ["@command", "@route"]).each { |line| puts line }
