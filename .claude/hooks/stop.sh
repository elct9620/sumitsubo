#!/usr/bin/env bash
# Nothing leaves a turn with a red suite. Exit 2 is how a Stop hook says so:
# it prevents the stop and hands the failure back to be fixed.
#
# The binding holds its own record format on its own terms and is a package of
# its own, so its suite is a second one to run — the same two CI runs, in the
# same order.
set -euo pipefail

root=${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}
spin=${SPIN:-$(command -v spin || true)}
if [ -z "$spin" ]; then
  echo "spin is not on PATH, so the suite was not run." >&2
  exit 0
fi

refuse() {
  printf '%s failed, so this turn is not finished:\n%s\n' "$1" "$(printf '%s' "$2" | tail -c 3000)" >&2
  exit 2
}

cd "$root"
output=$("$spin" test 2>&1) || refuse "spin test" "$output"

cd "$root/.packages/tree-sitter"
output=$("$spin" test 2>&1) || refuse "spin test in .packages/tree-sitter" "$output"
