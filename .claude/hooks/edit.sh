#!/usr/bin/env bash
# The documents are derived from the specification, so a change under `.spec/`
# leaves them stale until something renders again. This is that something —
# see the Render section of CLAUDE.md for what a run writes.
#
# It renders whatever the tool was and whatever it touched, rather than
# reading a path out of the payload: a specification edited through a shell
# heredoc is as stale-making as one edited through Edit, and where the
# documents go is `.sumi.json`'s to say, not this script's to guess. Rendering
# is cheap and replaces each file with what the specification now says, so the
# run is its own test of whether anything moved.
#
# The executable this repository builds is the one that renders this
# repository's own specification. A `sumi` on PATH is a fallback, and the
# message says which one ran, since the two can disagree.
set -euo pipefail

root=${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}
cd "$root"

sumi="$root/build/bin/sumi"
[ -x "$sumi" ] || sumi=$(command -v sumi || true)
if [ -z "$sumi" ]; then
  echo "The documents may now be stale: no sumi to render with. Run spin build." >&2
  exit 2
fi

before=$(git status --porcelain)
if ! output=$("$sumi" render 2>&1); then
  printf 'sumi render could not finish:\n%s\n' "$output" >&2
  exit 2
fi

# Silence means the specification says what it said before. Only a document
# that actually moved is worth a line in the transcript.
[ "$before" != "$(git status --porcelain)" ] || exit 0
jq -n --arg sumi "${sumi#"$root"/}" '{systemMessage: ("the documents were re-rendered by " + $sumi)}'
