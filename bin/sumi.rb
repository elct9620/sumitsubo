require "sumitsubo"
# What this build carries, and what it answers for: neither is the library's to
# know, and neither is compiled into a test. Naming the languages and the
# parsers here is what keeps a grammar, and a format, out of every run that
# only prints or lays down files.
require "sumitsubo/language"
require "sumitsubo/parser/json"
require "build_rev"

exit Sumitsubo::CLI.new(
  Sumitsubo::STAMPED_REV, Sumitsubo::Language, [Sumitsubo::Parser::Json.new]
).run(ARGV)
