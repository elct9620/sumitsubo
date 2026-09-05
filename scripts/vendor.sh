#!/bin/sh
# Fetch the tree-sitter runtime and the grammars into vendor/, which is not
# committed. Every version is pinned here: a grammar's node names are what the
# queries are written against, and a parse table generated for another runtime
# is refused at load time rather than misread.
#
# Grammar repositories ship a pre-generated src/parser.c, so this needs a C
# compiler and nothing else — no tree-sitter CLI, no node.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
vendor="$root/vendor"
RUNTIME=v0.26.12
RUBY=v0.23.1
RUST=v0.24.2
GO=v0.25.0
PYTHON=v0.25.0
JAVASCRIPT=v0.25.0
TYPESCRIPT=v0.23.2
MARKDOWN=v0.5.3

mkdir -p "$vendor"

fetch() {
  name=$1
  repo=$2
  tag=$3
  stamp="$vendor/$name.pin"
  [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$tag" ] && return 0

  rm -rf "$vendor/$name"
  echo "$name $tag"
  curl -sSL "https://github.com/$repo/archive/refs/tags/$tag.tar.gz" | tar xz -C "$vendor"
  mv "$vendor/$(basename "$repo")-${tag#v}" "$vendor/$name"
  echo "$tag" > "$stamp"
}

fetch tree-sitter tree-sitter/tree-sitter "$RUNTIME"
fetch tree-sitter-ruby tree-sitter/tree-sitter-ruby "$RUBY"
fetch tree-sitter-rust tree-sitter/tree-sitter-rust "$RUST"
fetch tree-sitter-go tree-sitter/tree-sitter-go "$GO"
fetch tree-sitter-python tree-sitter/tree-sitter-python "$PYTHON"
fetch tree-sitter-javascript tree-sitter/tree-sitter-javascript "$JAVASCRIPT"
# TypeScript ships two grammars in one repository — the language, and the one
# that reads JSX alongside it — so one fetch answers for two translation units.
fetch tree-sitter-typescript tree-sitter/tree-sitter-typescript "$TYPESCRIPT"
# Markdown ships two grammars in one repository and this build carries both:
# the block one for the structure a specification is written in, and the inline
# one for reading the text a block-level node holds unparsed.
fetch tree-sitter-markdown tree-sitter-grammars/tree-sitter-markdown "$MARKDOWN"

# The binding is compiled against the header it carries, so the pin has one
# home: re-pointing RUNTIME above refreshes the committed copy, and the diff is
# where a version change becomes visible.
cp "$vendor/tree-sitter/lib/include/tree_sitter/api.h" \
   "$root/.packages/tree-sitter/tree_sitter/api.h"

# tree-sitter's sources reach their headers as "tree_sitter/api.h" and
# "unicode/ptypes.h", which normally resolve through -I lib/src and
# -I lib/include. spin compiles carried C with only the package root on the
# include path, so the two roots are mirrored into the source tree instead;
# the self-referential unicode link resolves the nesting at any depth.
src="$vendor/tree-sitter/lib/src"
[ -e "$src/tree_sitter" ] || ln -s ../include/tree_sitter "$src/tree_sitter"
[ -e "$src/unicode/unicode" ] || ln -s . "$src/unicode/unicode"

# Both TypeScript grammars reach their scanner through a header they share,
# and that header asks for "tree_sitter/parser.h" — which resolves beside
# itself, where there is none. Upstream builds pass -I for each grammar's own
# src; spin gives the application root alone, so the directory is mirrored
# where the shared header will look for it.
common="$vendor/tree-sitter-typescript/common"
[ ! -d "$common" ] || [ -e "$common/tree_sitter" ] ||
  ln -s ../typescript/src/tree_sitter "$common/tree_sitter"

# spin decides what to recompile from the mtimes of the files it scans, and
# vendor/ is not one of them. Re-pinning would otherwise link yesterday's
# runtime against today's header.
touch "$root"/grammars/*.c 2>/dev/null || true

echo "vendored into $vendor"
