#!/usr/bin/env bash
# Nothing leaves a turn with a red suite. Exit 2 is how a Stop hook says so:
# it prevents the stop and hands the failure back to be fixed.
#
# A suite that cannot be made green would otherwise trap the session, since
# the hook runs again on every attempt to stop. After a few consecutive
# blocks it says so and lets the turn end, leaving the decision to a person.
set -euo pipefail

payload=$(cat)
session=$(printf '%s' "$payload" | jq -r '.session_id // "unknown"')
root=${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}
attempts="${TMPDIR:-/tmp}/sumi-stop-$session"

spin=${SPIN:-$(command -v spin || true)}
if [ -z "$spin" ]; then
  echo "spin is not on PATH, so the suite was not run." >&2
  exit 0
fi

cd "$root"
if output=$("$spin" test 2>&1); then
  rm -f "$attempts"
  exit 0
fi

blocked=$(($(cat "$attempts" 2>/dev/null || echo 0) + 1))
printf '%s' "$blocked" > "$attempts"

if [ "$blocked" -gt 3 ]; then
  rm -f "$attempts"
  printf 'spin test is still failing after %s attempts; letting the turn end.\n' "$blocked" >&2
  exit 0
fi

printf 'spin test failed, so this turn is not finished:\n%s\n' "$(printf '%s' "$output" | tail -c 3000)" >&2
exit 2
