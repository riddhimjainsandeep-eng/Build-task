#!/usr/bin/env bash
# settings.sh — the user's build-task-v2 settings.
#
# Settings change what the user gets and where it goes, never how carefully the
# work is done. Global file ~/.claude/build-task/settings.json, overridden per
# project by the `settings` key of build-task.config.json in the current repo.
#
#   settings.sh                       print the merged settings as JSON
#   settings.sh get <key>             print one value
#   settings.sh set global|project key=value [key=value ...]
#
# Keys and allowed values (first is the default, matching build-task v1):
#   zip          true|false      the run archive
#   costSection  true|false      Phase 5's measured cost in the report
#   printReport  true|false      print the user report in chat
#   handoff      true|false      the technical handoff section
#   history      true|false      one row to the shared history
#   push         auto|ask|never  pushing, and only ever after check + review pass
#   maps         apply|propose   update maps, or propose the changes in the report
#   rulesFile    apply|propose   same, for CLAUDE.md

set -uo pipefail

DEFAULTS='{"zip":true,"costSection":true,"printReport":true,"handoff":true,"history":true,"push":"auto","maps":"apply","rulesFile":"apply"}'
GLOBAL="${BUILD_TASK_SETTINGS:-$HOME/.claude/build-task/settings.json}"
PROJECT="build-task.config.json"

allowed() {  # allowed <key> -> space-separated values, empty if unknown key
  case "$1" in
    zip|costSection|printReport|handoff|history) echo "true false" ;;
    push) echo "auto ask never" ;;
    maps|rulesFile) echo "apply propose" ;;
  esac
}

# The Windows jq build ends lines with CRLF; strip it everywhere.
jqr() { jq "$@" | tr -d '\r'; }

merged() {
  local g='{}' p='{}'
  [ -f "$GLOBAL" ] && g=$(jqr -c '.' "$GLOBAL" 2>/dev/null || echo '{}')
  if [ -f "$PROJECT" ]; then
    # v1's `push: false` means never, unless an explicit v2 setting says otherwise.
    p=$(jqr -c '(if .push == false then {push:"never"} else {} end)
      + (.settings // {})' "$PROJECT" 2>/dev/null || echo '{}')
  fi
  jqr -c -n --argjson d "$DEFAULTS" --argjson g "$g" --argjson p "$p" '$d * $g * $p'
}

case "${1:-}" in
  "") merged ;;
  get)
    [ -n "$(allowed "${2:-}")" ] || { echo "settings.sh: unknown key ${2:-}" >&2; exit 2; }
    merged | jqr -r --arg k "$2" '.[$k]' ;;
  set)
    scope="${2:-}"; shift 2 2>/dev/null || true
    case "$scope" in
      global)  file="$GLOBAL" ;;
      project) file="$PROJECT" ;;
      *) echo "settings.sh: set global|project key=value ..." >&2; exit 2 ;;
    esac
    [ $# -gt 0 ] || { echo "settings.sh: nothing to set" >&2; exit 2; }
    patch='{}'
    for kv in "$@"; do
      k="${kv%%=*}"; v="${kv#*=}"
      ok=$(allowed "$k")
      [ -n "$ok" ] || { echo "settings.sh: unknown key $k" >&2; exit 2; }
      case " $ok " in *" $v "*) ;; *) echo "settings.sh: $k must be one of: $ok" >&2; exit 2 ;; esac
      case "$v" in true|false) val="$v" ;; *) val="\"$v\"" ;; esac
      patch=$(jqr -c -n --argjson p "$patch" --arg k "$k" --argjson v "$val" '$p + {($k): $v}')
    done
    mkdir -p "$(dirname "$file")"
    cur='{}'; [ -f "$file" ] && cur=$(jqr -c '.' "$file")
    if [ "$scope" = project ]; then
      new=$(jqr -n --argjson c "$cur" --argjson p "$patch" '$c + {settings: (($c.settings // {}) + $p)}')
    else
      new=$(jqr -n --argjson c "$cur" --argjson p "$patch" '$c + $p')
    fi
    printf '%s\n' "$new" > "$file" && echo "saved to $file" && merged ;;
  *) sed -n '2,22p' "$0"; exit 2 ;;
esac
