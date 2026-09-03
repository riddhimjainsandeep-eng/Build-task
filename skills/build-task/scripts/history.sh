#!/usr/bin/env bash
# history.sh — read the shared build history.
#
# Read-only by construction: the table has no update or delete policy, so
# nothing here could edit a past entry even if it tried.
#
#   history.sh                     the 20 most recent runs, all projects
#   history.sh --limit 50
#   history.sh --repo owner/name   only that project
#   history.sh --search sync       runs whose lessons or landmines mention it
#   history.sh --summary           counts per project, verdicts, total cost
#
# Credentials: $BUILD_TASK_SUPABASE_URL / $BUILD_TASK_SUPABASE_KEY, or
# ~/.claude/build-task/env

set -uo pipefail

LIMIT=20 REPO="" SEARCH="" SUMMARY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --limit)   LIMIT="$2"; shift 2 ;;
    --repo)    REPO="$2"; shift 2 ;;
    --search)  SEARCH="$2"; shift 2 ;;
    --summary) SUMMARY=true; shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown argument $1" >&2; shift ;;
  esac
done

for tool in jq curl; do
  command -v "$tool" >/dev/null 2>&1 || { echo "$tool is required." >&2; exit 1; }
done

ENV_FILE="${HOME}/.claude/build-task/env"
URL="${BUILD_TASK_SUPABASE_URL:-${CLAUDE_PLUGIN_OPTION_SUPABASE_URL:-}}"
KEY="${BUILD_TASK_SUPABASE_KEY:-${CLAUDE_PLUGIN_OPTION_SUPABASE_KEY:-}}"

if { [ -z "$URL" ] || [ -z "$KEY" ]; } && [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  set -a; . "$ENV_FILE"; set +a
  URL="${URL:-${BUILD_TASK_SUPABASE_URL:-}}"
  KEY="${KEY:-${BUILD_TASK_SUPABASE_KEY:-}}"
fi

if [ -z "$URL" ] || [ -z "$KEY" ]; then
  echo "Shared history is not set up yet — see the plugin's SETUP.md." >&2
  exit 1
fi
URL="${URL%/}"

urlenc() { jq -rn --arg v "$1" '$v|@uri'; }

if $SUMMARY; then
  QUERY="select=*&order=logged_at.desc&limit=1000"
else
  QUERY="select=repo,task,run_date,verdict,small_mode,cost_usd,contradictions,lessons,landmines"
  QUERY="$QUERY&order=logged_at.desc&limit=$LIMIT"
  [ -n "$REPO" ]   && QUERY="$QUERY&repo=eq.$(urlenc "$REPO")"
  [ -n "$SEARCH" ] && QUERY="$QUERY&or=(lessons.cs.{\"$(urlenc "$SEARCH")\"},landmines.cs.{\"$(urlenc "$SEARCH")\"})"
fi

RESP=$(curl -sS --max-time 30 "$URL/rest/v1/build_runs?$QUERY" \
  -H "apikey: $KEY" -H "Authorization: Bearer $KEY") || {
  echo "Could not reach the history." >&2; exit 1; }

if ! echo "$RESP" | jq -e 'type == "array"' >/dev/null 2>&1; then
  echo "The history returned an error:" >&2
  echo "$RESP" | head -c 400 >&2; echo >&2
  exit 1
fi

if [ "$(echo "$RESP" | jq 'length')" -eq 0 ]; then
  echo "Nothing recorded yet."
  exit 0
fi

if $SUMMARY; then
  echo "== Shared build history =="
  echo
  echo "Total runs: $(echo "$RESP" | jq 'length')"
  echo
  echo "-- Runs per project --"
  echo "$RESP" | jq -r 'group_by(.repo)[] | "\(length)\t\(.[0].repo)"' | sort -rn
  echo
  echo "-- Verdicts --"
  echo "$RESP" | jq -r 'group_by(.verdict)[] | "\(length)\t\(.[0].verdict // "unrecorded")"' | sort -rn
  echo
  echo "-- Cost --"
  echo "$RESP" | jq '[.[] | select(.cost_usd != null) | .cost_usd | tonumber]
    | {runs_with_a_figure: length, total: (add // 0)}'
else
  echo "$RESP" | jq -r '.[] |
    "── \(.run_date // "?")  \(.repo)  —  \(.task)\n" +
    "   verdict: \(.verdict // "?")\(if .small_mode then "  (small)" else "" end)" +
    "\(if .cost_usd then "  ~$\(.cost_usd)" else "" end)" +
    (if (.contradictions // "") != "" then "\n   contradicted: \(.contradictions)" else "" end) +
    (if ((.lessons // []) | length) > 0 then "\n   lessons:\n" + ((.lessons | map("     · " + .)) | join("\n")) else "" end) +
    (if ((.landmines // []) | length) > 0 then "\n   landmines:\n" + ((.landmines | map("     · " + .)) | join("\n")) else "" end)'
fi
