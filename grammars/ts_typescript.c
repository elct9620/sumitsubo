// The TypeScript grammar, linked in rather than loaded: what this executable
// can parse is decided when it is built.
//
// Its two sources share one translation unit because they are one grammar —
// the parse table, and the external scanner. That scanner is shared with the
// JSX grammar beside it through a header two directories up, which is why
// `scripts/vendor.sh` mirrors a directory for the header that one asks for.
//
// The runtime cannot join them, and neither can the two TypeScript grammars
// join each other: each carries its own tree_sitter/parser.h under the same
// include guard, so one would silently be compiled against the other's layout.
#include "vendor/tree-sitter-typescript/typescript/src/parser.c"
#include "vendor/tree-sitter-typescript/typescript/src/scanner.c"
