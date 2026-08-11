#!/usr/bin/env bash
# Run a workloop data-gathering step, preserve its console output, and persist
# bounded evidence when the command fails, reports an unavailable dependency,
# or the wrapper is interrupted.
set -uo pipefail

usage() {
  echo "Usage: $0 --label <followup|find-work> -- <command> [args...]" >&2
  exit 64
}

label=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --label)
      [ "$#" -ge 2 ] || usage
      label="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *) usage ;;
  esac
done

[ -n "$label" ] && [ "$#" -gt 0 ] || usage

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
evidence_dir="$repo_root/offline/evidence/$(date +%F)"
mkdir -p "$evidence_dir"
stdout_file=$(mktemp "${TMPDIR:-/tmp}/workloop-${label}.stdout.XXXXXX")
stderr_file=$(mktemp "${TMPDIR:-/tmp}/workloop-${label}.stderr.XXXXXX")
child_pid=""
cleanup() { rm -f "$stdout_file" "$stderr_file"; }
trap cleanup EXIT

redact() {
  sed -E \
    -e 's/(token|authorization|password|secret)[=:][^[:space:]]+/\1=[REDACTED]/Ig' \
    -e 's/ghp_[[:alnum:]_]+/[REDACTED_GITHUB_TOKEN]/g' \
    -e 's/github_pat_[[:alnum:]_]+/[REDACTED_GITHUB_TOKEN]/g'
}

write_artifact() {
  local kind="$1"
  local status="$2"
  local signal="${3:-}"
  local timestamp artifact command_line

  timestamp=$(date +%Y%m%dT%H%M%S%z)
  artifact="$evidence_dir/${timestamp}-${label}.md"
  command_line=$(printf '%q ' "${command[@]}")
  {
    echo "# Workloop ${label} ${kind} evidence"
    echo
    echo "- Timestamp: $(date -Is)"
    printf '%s' "- Command: \`${command_line% }\`" | redact
    echo
    echo "- Exit status: $status"
    if [ -n "$signal" ]; then
      echo "- Signal: $signal"
    fi
    if [ "$kind" = "unavailable" ]; then
      if grep -Eqi "$marker" "$stdout_file" "$stderr_file"; then
        echo "- Explicit unavailable marker: yes"
      else
        echo "- Explicit unavailable marker: no"
      fi
    fi
    echo
    echo "## stdout tail (40 lines)"
    echo '```text'
    tail -n 40 "$stdout_file" | redact
    echo '```'
    echo
    echo "## stderr tail (40 lines)"
    echo '```text'
    tail -n 40 "$stderr_file" | redact
    echo '```'
  } >"$artifact"
  echo "WORKLOOP_EVIDENCE_ARTIFACT=$artifact" >&2
}

# Keep the command in the background so a TERM delivered to this wrapper can
# capture its partial output, stop the child, and still return TERM's 128+15
# status to the caller.
command=("$@")
marker='FINDER_RESULT=UNAVAILABLE|scan_unavailable|gh search (issues|prs) failed|JSON feed unavailable'
interrupted() {
  local signal="$1"
  trap - TERM INT
  if [ -n "$child_pid" ]; then
    kill -TERM "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  fi
  write_artifact "interruption" 143 "$signal"
  exit 143
}
trap 'interrupted TERM' TERM

"${command[@]}" >"$stdout_file" 2>"$stderr_file" &
child_pid=$!
wait "$child_pid"
status=$?
child_pid=""
cat "$stdout_file"
cat "$stderr_file" >&2

# Some legacy scripts keep running after a failed internal query. Treat their
# explicit markers as unavailable evidence, without changing their exit code.
if [ "$status" -ne 0 ] || grep -Eqi "$marker" "$stdout_file" "$stderr_file"; then
  write_artifact "unavailable" "$status"
fi

exit "$status"
