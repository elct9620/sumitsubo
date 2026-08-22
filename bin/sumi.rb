require "sumitsubo"
# What this build carries, and what it answers for: neither is the library's to
# know, and neither is compiled into a test. Requiring the languages here is
# what keeps a grammar out of every run that only prints or lays down files.
require "sumitsubo/language"
require "build_rev"

exit Sumitsubo::CLI.new(Sumitsubo::STAMPED_REV, Sumitsubo::Language).run(ARGV)
