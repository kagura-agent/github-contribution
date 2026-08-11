#!/usr/bin/env bash
# Regression: a TERM sent directly to the wrapper must preserve partial output
# as a redacted interruption artifact and return the conventional TERM status.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
runner="$repo_root/scripts/run-workloop-step.sh"
label="followup"
evidence_dir="$repo_root/offline/evidence/$(date +%F)"
tmp=$(mktemp -d)
wrapper_pid=""
artifact=""

cleanup() {
  if [ -n "$wrapper_pid" ] && kill -0 "$wrapper_pid" 2>/dev/null; then
    kill -TERM "$wrapper_pid" 2>/dev/null || true
    wait "$wrapper_pid" 2>/dev/null || true
  fi
  [ -z "$artifact" ] || rm -f "$artifact"
  rmdir "$evidence_dir" 2>/dev/null || true
  rm -rf "$tmp"
}
trap cleanup EXIT

before=$(find "$evidence_dir" -maxdepth 1 -type f -name "*-${label}.md" -print 2>/dev/null | sort || true)
bash "$runner" --label "$label" -- bash -c '
  echo stdout-before-term
  echo authorization=output-secret >&2
  while :; do sleep 1; done
' >"$tmp/stdout" 2>"$tmp/stderr" &
wrapper_pid=$!
sleep 0.2
kill -TERM "$wrapper_pid"
set +e
wait "$wrapper_pid"
status=$?
set -e
wrapper_pid=""

[ "$status" -eq 143 ] || { echo "expected status 143, got $status" >&2; exit 1; }
after=$(find "$evidence_dir" -maxdepth 1 -type f -name "*-${label}.md" -print 2>/dev/null | sort || true)
artifact=$(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | tail -n 1)
[ -n "$artifact" ] || { echo "no interruption artifact created" >&2; exit 1; }

grep -Fq -- '- Signal: TERM' "$artifact"
grep -Fq -- '- Exit status: 143' "$artifact"
grep -Fq 'stdout-before-term' "$artifact"
grep -Fq 'authorization=[REDACTED]' "$artifact"
! grep -Fq 'output-secret' "$artifact"

echo "PASS: SIGTERM writes a redacted interruption artifact and exits 143"
