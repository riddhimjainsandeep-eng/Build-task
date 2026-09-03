#!/usr/bin/env bash
# save-config.sh — bridge the plugin's install-time settings to the scripts.
#
# WHY THIS EXISTS
# The values collected by the plugin's setup dialog are handed to *hook*
# processes as CLAUDE_PLUGIN_OPTION_<KEY> environment variables. The history
# scripts are not hooks — the agent runs them through the shell — so they never
# see those variables. This hook runs at session start, where the variables do
# exist, and writes them once to the file the scripts already read.
#
# Silent and harmless in every failure case. Always exits 0, never blocks a
# session, never prints the key.

set -uo pipefail

URL="${CLAUDE_PLUGIN_OPTION_SUPABASE_URL:-}"
KEY="${CLAUDE_PLUGIN_OPTION_SUPABASE_KEY:-}"

# Nothing configured, or this build does not export them: leave any existing
# hand-written file exactly as it is.
[ -n "$URL" ] && [ -n "$KEY" ] || exit 0

DIR="${HOME}/.claude/build-task"
FILE="${DIR}/env"

mkdir -p "$DIR" 2>/dev/null || exit 0
chmod 700 "$DIR" 2>/dev/null

NEW="BUILD_TASK_SUPABASE_URL=${URL%/}
BUILD_TASK_SUPABASE_KEY=${KEY}"

# Only write when something actually changed, so this is a no-op on almost
# every session start.
if [ -f "$FILE" ] && [ "$(cat "$FILE" 2>/dev/null)" = "$NEW" ]; then
  exit 0
fi

umask 177   # the file is created 0600 — readable only by this user
printf '%s\n' "$NEW" > "$FILE" 2>/dev/null || exit 0
chmod 600 "$FILE" 2>/dev/null

exit 0
