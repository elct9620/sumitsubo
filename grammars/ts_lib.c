// The tree-sitter runtime as one translation unit.
//
// lib.c is an amalgamation that includes the runtime's other sources, so they
// must not also be compiled on their own. What stops that is the manifest,
// which names `grammars/*.c` and nothing under `vendor`: this file is the one
// translation unit that pulls the runtime in.
#include "vendor/tree-sitter/lib/src/lib.c"
