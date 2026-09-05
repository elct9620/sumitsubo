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

module GoGrammar
  ffi_func :tree_sitter_go, [], :ptr
end

module PythonGrammar
  ffi_func :tree_sitter_python, [], :ptr
end

module JavascriptGrammar
  ffi_func :tree_sitter_javascript, [], :ptr
end

module TypescriptGrammar
  ffi_func :tree_sitter_typescript, [], :ptr
end

module TsxGrammar
  ffi_func :tree_sitter_tsx, [], :ptr
end

module MarkdownGrammar
  ffi_func :tree_sitter_markdown, [], :ptr
end

module MarkdownInlineGrammar
  ffi_func :tree_sitter_markdown_inline, [], :ptr
end

module Sumitsubo
  # What a grammar is called here, which is also what a specification names when
  # it says which language spells the names it registers. The queries put to one
  # live with the reading that writes them, since they are written against that
  # grammar's node names and no two grammars spell a node alike.
  module Grammar
    RUBY = "ruby"
    RUST = "rust"
    GO = "go"
    PYTHON = "python"
    JAVASCRIPT = "javascript"
    TYPESCRIPT = "typescript"
    # TypeScript ships two grammars and this build carries both: the language,
    # and the one that reads JSX alongside it. A file is one or the other, so a
    # specification naming the wrong one is a parse this cannot make.
    TSX = "tsx"
    # Markdown ships two grammars and this build carries both. The block one
    # gives the structure a specification is written in — sections, tables,
    # fences — and hands back the text a block-level `inline` node holds
    # unparsed; the inline one reads inside that text, which is where a run
    # taken letter for letter is marked.
    MARKDOWN = "markdown"
    MARKDOWN_INLINE = "markdown_inline"

    # What a query put to one of them captured in a file. Every query in this
    # program is put through here, so what a caller handed this module can do
    # is the whole of what a grammar answers — which is what lets a reading of
    # source, or of a specification, be handed one instead of reaching for it.
    #
    # Reaching the file is part of that: a parser handed this module opens
    # nothing itself, so what it can be asked stays the whole of what it does.
    def self.captures_in(grammar, path, query, where)
      captures_of(grammar, path.read, query, where)
    end

    # The same query put to a piece of text nobody wrote to a file. A signature
    # a specification registers is read by the query the source is read by, and
    # there is no file to hand over.
    def self.captures_of(grammar, source, query, where)
      TreeSitter.capture(grammar, source, query, where)
    end
  end
end

TreeSitter.register(Sumitsubo::Grammar::RUBY, RubyGrammar.tree_sitter_ruby)
TreeSitter.register(Sumitsubo::Grammar::RUST, RustGrammar.tree_sitter_rust)
TreeSitter.register(Sumitsubo::Grammar::GO, GoGrammar.tree_sitter_go)
TreeSitter.register(Sumitsubo::Grammar::PYTHON, PythonGrammar.tree_sitter_python)
TreeSitter.register(Sumitsubo::Grammar::JAVASCRIPT, JavascriptGrammar.tree_sitter_javascript)
TreeSitter.register(Sumitsubo::Grammar::TYPESCRIPT, TypescriptGrammar.tree_sitter_typescript)
TreeSitter.register(Sumitsubo::Grammar::TSX, TsxGrammar.tree_sitter_tsx)
TreeSitter.register(Sumitsubo::Grammar::MARKDOWN, MarkdownGrammar.tree_sitter_markdown)
TreeSitter.register(Sumitsubo::Grammar::MARKDOWN_INLINE, MarkdownInlineGrammar.tree_sitter_markdown_inline)
