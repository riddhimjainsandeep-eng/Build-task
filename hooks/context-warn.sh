#!/usr/bin/env bash
# context-warn.sh — warn when the session's context gets expensive.
#
# WARNING ONLY. Always exits 0. Never blocks a tool call, never alters
# behaviour, never writes into the repo.
#
# Why it reads the transcript instead of stdin: no hook payload carries context
# size or token counts (the statusline payload does; hook payloads do not).
# Every hook payload does carry `transcript_path`, and the transcript's last
# `message.usage` block holds the same four token counts the statusline sums.
# Subagent turns live in their own transcript file, so a main-session hook sees
# the main session's real number rather than a mixture.
#
# Runs on `Stop` — once per assistant turn, at the moment the user is about to
# type — rather than on every tool call, which would fire ten times a turn for
# the same information.
#
# Self-check (expect: a warning then 0, then silence then 0):
#   T=$(ls -t ~/.claude/projects/*/*.jsonl | head -1)
#   echo "{\"session_id\":\"demo\",\"transcript_path\":\"$T\"}" | bash hooks/context-warn.sh; echo $?
#   echo '{"session_id":"demo","transcript_path":"/nope"}' | bash hooks/context-warn.sh; echo $?

set -uo pipefail

THRESHOLD=150000   # tokens; roughly 75% of a 200k window
BAND=50000         # re-warn once per this many tokens above the threshold

command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat)
transcript=$(jq -r '.transcript_path // empty' <<<"$payload" 2>/dev/null)
session=$(jq -r '.session_id // "unknown"' <<<"$payload" 2>/dev/null)
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

# Last usage block in the transcript. Reading the tail keeps this cheap on a
# multi-megabyte file; fromjson? drops the partial first line tail may produce.
total=$(tail -n 40 "$transcript" 2>/dev/null | jq -Rn '
  [ inputs | fromjson? | .message.usage? // empty ] | last // {}
  | (.input_tokens // 0) + (.cache_creation_input_tokens // 0)
  + (.cache_read_input_tokens // 0) + (.output_tokens // 0)' 2>/dev/null)

case "$total" in ''|*[!0-9]*) exit 0 ;; esac
[ "$total" -ge "$THRESHOLD" ] || exit 0

# One warning per band per session, so a long session is not spammed.
marker="${TMPDIR:-/tmp}/build-task-ctxwarn-${session}-$(( total / BAND ))"
[ -e "$marker" ] && exit 0
: > "$marker" 2>/dev/null

printf '{"systemMessage":"Context is at ~%s tokens, past the %s mark. Turns cost more from here on: /compact now, or finish this phase and /clear before the next task."}\n' \
  "$total" "$THRESHOLD"
exit 0
