require "pathname"
require "sumitsubo/behavior"
require "sumitsubo/source/marker"
require "sumitsubo/source"

# What a piece of source claims to implement, read out of the comments a
# language offers.
#
# The comments are written out rather than parsed for. Where they sit in a file
# and what each stands next to are the language's to answer, and a real grammar
# here would only be answering a question this reading never asks.

BEHAVIOR = [Sumitsubo::Behavior::MARKER]

# A language's answer, said outright.
class Offered
  def initialize(regions)
    @regions = regions
  end

  def comments_in(path, where)
    @regions
  end
end

# A region stands in front of code unless the case says otherwise, since what
# each one stands next to is the reading's answer and not this one's subject.
def region(line, text, followed_by = Sumitsubo::Source::Region::SOURCE_CODE)
  Sumitsubo::Source::Region.new(line, text, followed_by)
end

# The text is bracketed because a keyword with nothing after it carries an
# empty one, and a snapshot cannot hold the trailing space that would leave.
# Whether the claim reaches the code it names is said outright, because that is
# what a mechanism reads it for.
def claims(path, keywords, regions)
  Sumitsubo::Source::Marker.claims_in(path, keywords, Offered.new(regions))
    .map do |claim|
      "#{claim.path}:#{claim.line} #{claim.keyword} [#{claim.text}]" \
        "#{claim.reaches_code ? "" : " reaching no code"}"
    end
end

# @behavior M-001 M-005
puts "--- a claim answers at the line its comment sits on ---"
claims("src/verify.rb", BEHAVIOR, [
  region(7, "# @behavior G-001"),
  region(10, "# @behavior G-002 I-001")
]).each { |line| puts line }

# A comment spanning lines arrives whole, so the line is counted from where it
# began rather than taken from it.
# @behavior M-003
puts "--- a claim in a block comment ---"
claims("src/init.rb", BEHAVIOR, [
  region(9, "=begin\nWhat the next thing is for.\n@behavior I-003\n=end")
]).each { |line| puts line }

# A caller reaching a mechanism other than Behavior has no reason to have
# rendered the path first, so the reading answers for itself.
# @behavior M-008
puts "--- a path that arrives absolute still answers where the run started ---"
claims(Pathname.new("src/commands.rb").expand_path.to_s, BEHAVIOR, [
  region(2, "# @behavior I-001")
]).each { |line| puts line }

# Parsing is the cost, so a whole set of keywords is read in one pass. The
# route carries the space a list reading would have split on, which is why
# what follows a keyword is handed back unread.
# @behavior M-009 M-010
puts "--- two keywords in one pass, and one with nothing after it ---"
claims("src/commands.rb", ["@command", "@route"], [
  region(4, "# @command verify"),
  region(5, "# @route GET /users/:id"),
  region(8, "# @command")
]).each { |line| puts line }

# A language writes its comment against the marker with nothing between, and so
# does the `*` down the side of a block comment. A letter in front of it makes
# another word, which is what keeps an address from claiming.
#
# Single-quoted because Ruby reads `#@name` in a double-quoted string as the
# instance variable rather than as the two characters written here.
# @behavior M-011
puts "--- a keyword the comment is written against ---"
claims("src/order.rb", BEHAVIOR, [
  region(3, '#@behavior G-003'),
  region(5, '/*@behavior G-004'),
  region(7, ' *@behavior G-005'),
  region(9, ' * 說明：@behavior G-006'),
  region(11, '# mail@behavior.example claims nothing')
]).each { |line| puts line }

# A claim reaches the code it names through the comments after it, because
# what a person wrote between a claim and what implements it is still what they
# wrote. A run of them ending the file reaches none, and every claim in that run
# says so — the claim is still made, and whoever asked decides what to do about
# one that witnesses nothing.
# @behavior M-012
puts "--- a claim reaches code through the comments after it, or reaches none ---"
claims("src/order.rb", BEHAVIOR, [
  region(2, "# @behavior G-007", Sumitsubo::Source::Region::COMMENT),
  region(3, "# @behavior G-008", Sumitsubo::Source::Region::SOURCE_CODE),
  region(6, "# @behavior G-009", Sumitsubo::Source::Region::COMMENT),
  region(7, "# @behavior G-010", Sumitsubo::Source::Region::NOTHING)
]).each { |line| puts line }

# The answer is per comment while the keywords are read per line, so a file
# carrying both is where one could be handed to the wrong claim.
# @behavior M-012
puts "--- and says so for every keyword on the line ---"
claims("src/routes.rb", ["@command", "@route"], [
  region(2, "# @command verify", Sumitsubo::Source::Region::SOURCE_CODE),
  region(4, "# @command init @route GET /users", Sumitsubo::Source::Region::NOTHING)
]).each { |line| puts line }
