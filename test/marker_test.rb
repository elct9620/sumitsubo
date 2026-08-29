require "pathname"
require "sumitsubo/behavior"
require "sumitsubo/marker"
require "sumitsubo/source"

# What a piece of source claims to implement, read out of the comments a
# language offers.
#
# The comments are written out rather than parsed for. Where they sit in a file
# and which of them a claim could sit in are the language's to answer, and a
# real grammar here would only be answering a question this reading never asks.

BEHAVIOR = [Sumitsubo::Behavior::MARKER]

# A language's answer, said outright.
class Offered
  def initialize(regions)
    @regions = regions
  end

  def attached_comments_in(path, where)
    @regions
  end
end

# The text is bracketed because a keyword with nothing after it carries an
# empty one, and a snapshot cannot hold the trailing space that would leave.
def claims(path, keywords, regions)
  Sumitsubo::Marker.claims_in(path, keywords, Offered.new(regions))
    .map { |claim| "#{claim.path}:#{claim.line} #{claim.keyword} [#{claim.text}]" }
end

# @behavior M-001 M-005
puts "--- a claim answers at the line its comment sits on ---"
claims("src/verify.rb", BEHAVIOR, [
  Sumitsubo::Source::Region.new(7, "# @behavior G-001"),
  Sumitsubo::Source::Region.new(10, "# @behavior G-002 I-001")
]).each { |line| puts line }

# A comment spanning lines arrives whole, so the line is counted from where it
# began rather than taken from it.
# @behavior M-003
puts "--- a claim in a block comment ---"
claims("src/init.rb", BEHAVIOR, [
  Sumitsubo::Source::Region.new(9, "=begin\nWhat the next thing is for.\n@behavior I-003\n=end")
]).each { |line| puts line }

# A caller reaching a mechanism other than Behavior has no reason to have
# rendered the path first, so the reading answers for itself.
# @behavior M-008
puts "--- a path that arrives absolute still answers where the run started ---"
claims(Pathname.new("src/commands.rb").expand_path.to_s, BEHAVIOR, [
  Sumitsubo::Source::Region.new(2, "# @behavior I-001")
]).each { |line| puts line }

# Parsing is the cost, so a whole set of keywords is read in one pass. The
# route carries the space a list reading would have split on, which is why
# what follows a keyword is handed back unread.
# @behavior M-009 M-010
puts "--- two keywords in one pass, and one with nothing after it ---"
claims("src/commands.rb", ["@command", "@route"], [
  Sumitsubo::Source::Region.new(4, "# @command verify"),
  Sumitsubo::Source::Region.new(5, "# @route GET /users/:id"),
  Sumitsubo::Source::Region.new(8, "# @command")
]).each { |line| puts line }
