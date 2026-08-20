require "treesitter"

# The grammar this build carries, announced to the binding so the rest of the
# code can ask for it by name.
#
# Ruby is the only language Sumitsubo targets, and its parse tables are linked
# in rather than loaded, so the announcement happens once as this file is
# required. A build that carried several would announce only the ones a run
# asks for — waking a grammar means paging its tables in.
module RubyGrammar
  ffi_func :tree_sitter_ruby, [], :ptr
end

module Sumitsubo
  module Grammar
    RUBY = "ruby"

    # Comments are the part of a source file a person wrote for another person,
    # which is where a concept is called by name rather than spelled as an
    # identifier.
    COMMENTS = "(comment) @text"

    # A comment with something after it. A behavior is claimed in front of the
    # code that implements it, so a comment nothing follows claims nothing.
    # The anchor only excludes that orphan: a comment followed by another
    # comment is still a match, which is as far as this needs to reach.
    ATTACHED = "((comment) @text . (_))"
  end
end

TreeSitter.register(Sumitsubo::Grammar::RUBY, RubyGrammar.tree_sitter_ruby)
