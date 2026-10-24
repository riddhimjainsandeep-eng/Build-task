#!/usr/bin/env bash
# run-cost.sh — measure what a run actually cost, from the session transcript.
#
#   run-cost.sh --since 2026-09-18T10:00:00Z [--transcript FILE]
#
# Counts, from the main session and its subagents, every assistant turn at or
# after --since: tool calls, new input tokens (input + cache writes), tokens
# re-read from cache, output tokens, and wall time. Without --transcript it uses
# the newest transcript of the current project. Measured, not estimated.

set -uo pipefail
SINCE="" TRANSCRIPT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE="$2"; shift 2 ;;
    --transcript) TRANSCRIPT="$2"; shift 2 ;;
    *) echo "run-cost.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done
[ -n "$SINCE" ] || { echo "run-cost.sh: --since is required" >&2; exit 2; }
SINCE=$(date -u -d "$SINCE" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || { echo "run-cost.sh: bad --since" >&2; exit 2; }

if [ -z "$TRANSCRIPT" ]; then
  top=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  win=$(cd "$top" && (pwd -W 2>/dev/null || pwd))
  enc=$(printf '%s' "$win" | sed 's/[^A-Za-z0-9]/-/g')
  TRANSCRIPT=$(ls -t "$HOME/.claude/projects/$enc"/*.jsonl 2>/dev/null | head -1)
  [ -n "$TRANSCRIPT" ] || { echo "run-cost.sh: no transcript found for $win"; exit 0; }
fi

measure() {  # measure <files...> -> "turns tools new reread out first last"
  cat "$@" 2>/dev/null | jq -Rr --arg since "$SINCE" '
    fromjson? | select(.type == "assistant" and (.timestamp // "") >= $since)
    | [(.message.id // ""), (.timestamp // ""),
       ((.message.content // []) | map(select(type == "object" and .type == "tool_use")) | length),
       ((.message.usage.input_tokens // 0) + (.message.usage.cache_creation_input_tokens // 0)),
       (.message.usage.cache_read_input_tokens // 0), (.message.usage.output_tokens // 0)]
    | @tsv' | tr -d '\r' | awk -F'\t' '
    # One API message is split across several transcript lines that repeat its
    # usage; count usage once per message id, tool calls on every line.
    { tools += $3
      if (!($1 in seen)) { seen[$1] = 1; turns++; nw += $4; rr += $5; out += $6 }
      if (first == "" || $2 < first) first = $2
      if ($2 > last) last = $2 }
    END { printf "%d %d %d %d %d %s %s\n", turns, tools, nw, rr, out, (first ? first : "-"), (last ? last : "-") }'
}

mins() {  # mins <first> <last>
  [ "$1" = "-" ] && { echo 0; return; }
  echo $(( ( $(date -u -d "$2" +%s) - $(date -u -d "$1" +%s) ) / 60 ))
}

read -r mt mtl mn mr mo mf ml <<<"$(measure "$TRANSCRIPT")"
SUB="${TRANSCRIPT%.jsonl}/subagents"
subs=$(ls "$SUB"/*.jsonl 2>/dev/null)
if [ -n "$subs" ]; then
  # shellcheck disable=SC2086
  read -r st stl sn sr so sf sl <<<"$(measure $subs)"
else
  st=0 stl=0 sn=0 sr=0 so=0 sf=- sl=-
fi

k() { echo "$(( ($1 + 500) / 1000 ))k"; }
echo "Since $SINCE — $(mins "$mf" "$ml") min wall time"
echo "  main session: $mt turns · $mtl tool calls · $(k "$mn") new input · $(k "$mr") re-read · $(k "$mo") output"
echo "  subagents:    $st turns · $stl tool calls · $(k "$sn") new input · $(k "$sr") re-read · $(k "$so") output"
