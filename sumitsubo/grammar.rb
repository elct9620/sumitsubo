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
  # What a grammar is called here. The queries put to one live with the reading
  # that writes them, since they are written against that grammar's node names
  # and no two grammars spell a node alike.
  module Grammar
    RUBY = "ruby"
  end
end

TreeSitter.register(Sumitsubo::Grammar::RUBY, RubyGrammar.tree_sitter_ruby)
