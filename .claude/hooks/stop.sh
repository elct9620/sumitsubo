#!/usr/bin/env bash
# Nothing leaves a turn with a red suite. Exit 2 is how a Stop hook says so:
# it prevents the stop and hands the failure back to be fixed.
set -euo pipefail

root=${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}
spin=${SPIN:-$(command -v spin || true)}
if [ -z "$spin" ]; then
  echo "spin is not on PATH, so the suite was not run." >&2
  exit 0
fi

cd "$root"
output=$("$spin" test 2>&1) && exit 0

printf 'spin test failed, so this turn is not finished:\n%s\n' "$(printf '%s' "$output" | tail -c 3000)" >&2
exit 2
