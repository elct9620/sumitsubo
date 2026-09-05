// The TSX grammar, linked in rather than loaded: what this executable can
// parse is decided when it is built.
//
// It is the second grammar of the TypeScript repository — the language with
// JSX read alongside it — so `scripts/vendor.sh` already fetched it and
// already mirrored the directory its shared scanner header looks in.
//
// It cannot join the TypeScript unit beside it: each carries its own
// tree_sitter/parser.h under the same include guard, so one would silently be
// compiled against the other's layout.
#include "vendor/tree-sitter-typescript/tsx/src/parser.c"
#include "vendor/tree-sitter-typescript/tsx/src/scanner.c"
