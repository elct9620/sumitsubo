// The Python grammar, linked in rather than loaded: what this executable can
// parse is decided when it is built.
//
// Its two sources share one translation unit because they are one grammar —
// the parse table, and the external scanner that recognises what a table
// cannot, such as where a block's indentation opens and closes. The runtime
// cannot join them: it carries its own tree_sitter/parser.h under the same
// include guard as the grammar's, so one would silently be compiled against
// the other's layout.
#include "vendor/tree-sitter-python/src/parser.c"
#include "vendor/tree-sitter-python/src/scanner.c"
