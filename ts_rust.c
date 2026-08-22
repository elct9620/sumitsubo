// The Rust grammar, linked in rather than loaded: what this executable can
// parse is decided when it is built.
//
// A grammar gets a translation unit of its own for the same reason the Ruby one
// does — every generated parser defines the same macros and carries its own
// tree_sitter/parser.h under one include guard, so two in a unit compile
// against each other's layout.
#include "vendor/tree-sitter-rust/src/parser.c"
#include "vendor/tree-sitter-rust/src/scanner.c"
