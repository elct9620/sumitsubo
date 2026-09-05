// The tree-sitter runtime as one translation unit.
//
// lib.c is an amalgamation that includes the runtime's other sources, so they
// must not also be compiled on their own. What stops that is the name the
// vendored tree sits under: spin scans this application's directories for the
// .c they carry, at any depth, and skips `vendor` alone. This file is the one
// translation unit that pulls it in.
#include "vendor/tree-sitter/lib/src/lib.c"
