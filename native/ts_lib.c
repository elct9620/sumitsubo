// The tree-sitter runtime as one translation unit.
//
// lib.c is an amalgamation that includes the runtime's other sources, so they
// must not also be compiled on their own. Keeping the vendored tree under
// vendor/ — which spin does not scan — is what stops that, and this file is the
// one translation unit that pulls it in.
#include "../vendor/tree-sitter/lib/src/lib.c"
