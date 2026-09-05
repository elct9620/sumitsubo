require "sumitsubo"
# What this build carries, and what it answers for: neither is the library's to
# know, and neither is compiled into a test. Naming the languages, the grammars
# and the parsers here is what keeps a grammar, and a format, out of every run
# that only prints or lays down files.
require "sumitsubo/source/language"
require "sumitsubo/source/language/go"
require "sumitsubo/source/language/prose"
require "sumitsubo/source/language/ruby"
require "sumitsubo/source/language/rust"
require "sumitsubo/grammar"
require "sumitsubo/specification/parser/markdown"
require "build_rev"

exit Sumitsubo::CLI.new(
  Sumitsubo::STAMPED_REV,
  Sumitsubo::Source::Language.new([
    Sumitsubo::Source::Language::Ruby.new(Sumitsubo::Grammar),
    Sumitsubo::Source::Language::Rust.new(Sumitsubo::Grammar),
    Sumitsubo::Source::Language::Go.new(Sumitsubo::Grammar),
    Sumitsubo::Source::Language::Prose.new
  ]),
  [Sumitsubo::Specification::Parser::Markdown.new(Sumitsubo::Grammar)]
).run(ARGV)
