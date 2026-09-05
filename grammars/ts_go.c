// The Go grammar, linked in rather than loaded: what this executable can parse
// is decided when it is built.
//
// One source rather than the two its neighbours carry: Go needs no external
// scanner, since nothing in it has to be recognised that a parse table cannot.
// It still gets a translation unit of its own — every generated parser defines
// the same macros and carries its own tree_sitter/parser.h under one include
// guard, so two in a unit compile against each other's layout.
#include "vendor/tree-sitter-go/src/parser.c"
