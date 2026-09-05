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

# A green above is a statement about one compiler. CI builds against the
# revision the action pins, and a local toolchain ahead of that is a normal
# state rather than a fault, so this says which one answered rather than
# asking the two to agree.
#
# It goes out as `systemMessage` because a hook that lets the turn end has no
# other way to reach a reader: stderr from an exit 0 reaches the debug log
# alone. Carrying no decision field, it leaves the turn ending as it would.
spinel=${SPINEL:-$(command -v spinel || true)}
pin=$(sed -n 's/^[[:space:]]*default: \([0-9a-f]\{40\}\)$/\1/p' \
  "$root/.github/actions/setup-spinel/action.yml" || true)
if [ -n "$spinel" ] && [ -n "$pin" ]; then
  ran=$("$spinel" --version 2>/dev/null | awk '{ print $2 }' || true)
  if [ -n "$ran" ] && [ "$ran" != "${pin:0:12}" ]; then
    printf '{"systemMessage":"The suite ran under spinel %s; CI builds against %s."}\n' \
      "$ran" "${pin:0:12}"
  fi
fi
