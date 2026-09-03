#!/usr/bin/env bash
# log-run.sh — append one finished run to the shared build history.
#
# Called from Phase 5(e). NEVER blocks the run: every failure path warns on
# stderr and exits 0, because a missing history row is not worth failing a
# completed piece of work over.
#
# Credentials, in order of precedence:
#   1. $BUILD_TASK_SUPABASE_URL / $BUILD_TASK_SUPABASE_KEY
#   2. ~/.claude/build-task/env   (shell format: KEY=value per line)
#
# Usage:
#   log-run.sh --task add-break-comparisons --verdict feasible \
#     --phases 0,1,2,3,4,5 --browser no --effort-signal none \
#     [--small-mode] [--cost-usd 4.12] [--files-changed 3] \
#     [--contradictions "the prompt assumed X; the code does Y"] \
#     [--lesson "one line"] [--lesson "another"] \
#     [--landmine "fragile thing left alone"]
#
# `repo` and `run_date` are derived automatically.
#
# NEVER pass a secret value in any field. This table is readable by anyone
# holding the key.

set -uo pipefail

warn() { echo "log-run.sh: $*" >&2; }

TASK="" VERDICT="" PHASES="" BROWSER="no" EFFORT="none"
SMALL="false" COST="null" FILES="null" CONTRADICTIONS=""
LESSONS=() LANDMINES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --task)           TASK="$2"; shift 2 ;;
    --verdict)        VERDICT="$2"; shift 2 ;;
    --phases)         PHASES="$2"; shift 2 ;;
    --browser)        BROWSER="$2"; shift 2 ;;
    --effort-signal)  EFFORT="$2"; shift 2 ;;
    --small-mode)     SMALL="true"; shift ;;
    --cost-usd)       COST="$2"; shift 2 ;;
    --files-changed)  FILES="$2"; shift 2 ;;
    --contradictions) CONTRADICTIONS="$2"; shift 2 ;;
    --lesson)         LESSONS+=("$2"); shift 2 ;;
    --landmine)       LANDMINES+=("$2"); shift 2 ;;
    *) warn "unknown argument $1"; shift ;;
  esac
done

[ -n "$TASK" ] || { warn "no --task given, skipping"; exit 0; }

command -v jq   >/dev/null 2>&1 || { warn "jq not found, skipping history write";   exit 0; }
command -v curl >/dev/null 2>&1 || { warn "curl not found, skipping history write"; exit 0; }

# --- credentials ------------------------------------------------------------
ENV_FILE="${HOME}/.claude/build-task/env"
if [ -z "${BUILD_TASK_SUPABASE_URL:-}" ] && [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  set -a; . "$ENV_FILE"; set +a
fi

URL="${BUILD_TASK_SUPABASE_URL:-}"
KEY="${BUILD_TASK_SUPABASE_KEY:-}"
if [ -z "$URL" ] || [ -z "$KEY" ]; then
  warn "shared history not configured (no BUILD_TASK_SUPABASE_URL/KEY, no $ENV_FILE) — skipping"
  exit 0
fi
URL="${URL%/}"

# --- derived fields ---------------------------------------------------------
REPO=$(git remote get-url origin 2>/dev/null \
       | sed -E 's#^git@[^:]+:#/#; s#^https?://[^/]+/#/#; s#\.git$##; s#^/##')
[ -n "$REPO" ] || REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
RUN_DATE=$(date -u +%Y-%m-%d)

case "$BROWSER" in yes|true|1) BROWSER_BOOL=true ;; *) BROWSER_BOOL=false ;; esac
case "$COST"  in ''|null) COST=null  ;; esac
case "$FILES" in ''|null) FILES=null ;; esac

phases_json()  { printf '%s' "$PHASES" | jq -R 'split(",") | map(select(length>0))'; }
strings_json() { [ "$#" -eq 0 ] && echo '[]' || printf '%s\n' "$@" | jq -R . | jq -s .; }

PAYLOAD=$(jq -nc \
  --arg repo "$REPO" --arg task "$TASK" --arg run_date "$RUN_DATE" \
  --arg verdict "$VERDICT" --arg effort "$EFFORT" --arg contra "$CONTRADICTIONS" \
  --argjson phases "$(phases_json)" \
  --argjson small "$SMALL" --argjson browser "$BROWSER_BOOL" \
  --argjson cost "$COST" --argjson files "$FILES" \
  --argjson lessons "$(strings_json ${LESSONS+"${LESSONS[@]}"})" \
  --argjson landmines "$(strings_json ${LANDMINES+"${LANDMINES[@]}"})" \
  '{repo:$repo, task:$task, run_date:$run_date, verdict:$verdict,
    phases_completed:$phases, small_mode:$small, browser:$browser,
    effort_signal:$effort, cost_usd:$cost, files_changed:$files,
    contradictions:(if $contra == "" then null else $contra end),
    lessons:$lessons, landmines:$landmines}') || {
  warn "could not build the payload, skipping"; exit 0; }

CODE=$(curl -sS -o /tmp/build-task-log.out -w '%{http_code}' \
  -X POST "$URL/rest/v1/build_runs" \
  -H "apikey: $KEY" -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" -H "Prefer: return=minimal" \
  --max-time 20 -d "$PAYLOAD" 2>/dev/null) || {
  warn "request failed (network), skipping"; exit 0; }

case "$CODE" in
  2*) echo "logged this run to the shared history ($REPO / $TASK)" ;;
  *)  warn "history write returned HTTP $CODE — $(head -c 300 /tmp/build-task-log.out 2>/dev/null)"
      warn "continuing; the run itself is unaffected" ;;
esac

exit 0
