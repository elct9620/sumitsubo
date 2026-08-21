#!/bin/sh
# Write the revision a build answers for. Generated rather than committed, so
# no commit carries its own hash, and written at the root, which no
# specification's include globs reach.
#
# Kept out of vendor.sh: that script's contents are the CI cache key for the
# vendored sources, and a revision moving with every commit has no business
# invalidating a year-old pin.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)

rev=$(git -C "$root" rev-parse --short=7 HEAD 2>/dev/null || echo unknown)
rev_file="$root/build_rev.rb"
new=$(printf 'module Sumitsubo\n  STAMPED_REV = "%s"\nend' "$rev")

# spin decides what to recompile from mtimes, so an unchanged revision is left
# alone rather than rewritten with the same bytes.
if [ ! -f "$rev_file" ] || [ "$(cat "$rev_file")" != "$new" ]; then
  printf '%s\n' "$new" > "$rev_file"
fi
echo "build revision $rev"
