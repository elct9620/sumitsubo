// The Markdown inline grammar, linked in beside the block one.
//
// It is a translation unit of its own for the reason every grammar is: it
// carries its own tree_sitter/parser.h under the same include guard as the
// others, and two generated parsers collide on the macros each of them
// defines.
//
// A block-level `inline` node holds its text unparsed, and this is what reads
// inside one — which run of it a document marked as taken letter for letter.
// The text arrives as a string of its own, so the parser needs no view into
// the document it came from.
#include "vendor/tree-sitter-markdown/tree-sitter-markdown-inline/src/parser.c"
#include "vendor/tree-sitter-markdown/tree-sitter-markdown-inline/src/scanner.c"
