require "treesitter"

# The grammars this build carries, announced to the binding so the rest of the
# code can ask for one by name.
#
# Parse tables are linked in rather than loaded, so what an executable can read
# is decided when it is built and the announcement happens once as this file is
# required. Announcing only the grammars a run asks for would save paging their
# tables in, which is worth doing when a build carries enough of them to notice.
module RubyGrammar
  ffi_func :tree_sitter_ruby, [], :ptr
end

module RustGrammar
  ffi_func :tree_sitter_rust, [], :ptr
end

module Sumitsubo
  # What a grammar is called here, which is also what a specification names when
  # it says which language spells the names it registers. The queries put to one
  # live with the reading that writes them, since they are written against that
  # grammar's node names and no two grammars spell a node alike.
  module Grammar
    RUBY = "ruby"
    RUST = "rust"
  end
end

TreeSitter.register(Sumitsubo::Grammar::RUBY, RubyGrammar.tree_sitter_ruby)
TreeSitter.register(Sumitsubo::Grammar::RUST, RustGrammar.tree_sitter_rust)
