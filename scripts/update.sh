#!/usr/bin/env bash
# update.sh — publish or fetch changes to the global build-task plugin.
#
# Claude Code loads the plugin straight from this git checkout, so every project
# that uses it picks up whatever is here at its next session start. This script
# only keeps this checkout and GitHub in step:
#
#   local edits here          → bump the patch version, commit, push
#   GitHub has newer commits  → fast-forward pull (e.g. on another machine)
#   both                      → stop; a human merges
#
# Installed from the marketplace instead (a copy, no .git)? It asks Claude Code
# to fetch the latest version from GitHub; nothing is committed or pushed.
#
# It never touches a project's own local copy of the skill.
#
# Usage:
#   update.sh --check              show what would happen, change nothing
#   update.sh --message "summary"  do it
#
# Self-check: test-update.sh beside this file.

set -uo pipefail

MODE="" MSG=""
case "${1:-}" in
  --check)   MODE=check ;;
  --message) MODE=publish; MSG="${2:-}"; [ -n "$MSG" ] || { echo "update.sh: --message needs a summary" >&2; exit 2; } ;;
  *) sed -n '2,20p' "$0"; exit 2 ;;
esac

# The plugin folder itself must be the checkout — a repo further up (a dotfiles
# ~/.claude, say) must never be committed or pushed by this script.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
PLUGIN_JSON=.claude-plugin/plugin.json
MARKET_JSON=.claude-plugin/marketplace.json
version() { sed -nE 's/.*"version": *"([^"]+)".*/\1/p' "$PLUGIN_JSON" | head -1; }
first_name() { sed -nE 's/.*"name": *"([^"]+)".*/\1/p' "$1" | head -1; }

if [ ! -e .git ]; then
  ID="$(first_name "$PLUGIN_JSON")@$(first_name "$MARKET_JSON")"
  echo "plugin: $ID, marketplace install (version $(version))"
  [ "$MODE" = check ] && { echo "would: fetch the latest version from GitHub"; exit 0; }
  claude plugin marketplace update "${ID#*@}" && claude plugin update "$ID" \
    || { echo "FAILED: plugin update — nothing else was changed"; exit 1; }
  echo "ok: updated — restart Claude Code to use the new version"
  exit 0
fi

echo "plugin: $ROOT (version $(version))"

git fetch -q 2>/dev/null || { echo "FAILED: could not reach GitHub — nothing changed"; exit 1; }
UPSTREAM=$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null) || { echo "FAILED: branch has no upstream — nothing changed"; exit 1; }
BEHIND=$(git rev-list --count "HEAD..$UPSTREAM")
AHEAD=$(git rev-list --count "$UPSTREAM..HEAD")
DIRTY=$(git status --porcelain)

if [ "$BEHIND" -gt 0 ] && { [ -n "$DIRTY" ] || [ "$AHEAD" -gt 0 ]; }; then
  echo "FAILED: GitHub has $BEHIND newer commit(s) AND this machine has its own changes."
  echo "Nothing was changed. Merge by hand: commit here, then 'git pull --rebase' in $ROOT."
  exit 1
fi

if [ "$BEHIND" -gt 0 ]; then
  echo "GitHub is $BEHIND commit(s) ahead:"; git log --oneline "HEAD..$UPSTREAM" | sed 's/^/  /'
  [ "$MODE" = check ] && { echo "would: pull them"; exit 0; }
  git pull -q --ff-only || { echo "FAILED: pull"; exit 1; }
  echo "ok: pulled — now version $(version)"
  exit 0
fi

if [ -z "$DIRTY" ] && [ "$AHEAD" = 0 ]; then
  echo "ok: already up to date — nothing to publish"
  exit 0
fi

if [ -n "$DIRTY" ]; then
  echo "local changes:"; git status --short | sed 's/^/  /'
  OLD=$(version)
  NEW=$(awk -F. -v OFS=. '{ $NF = $NF + 1; print }' <<<"$OLD")
  if [ "$MODE" = check ]; then
    echo "would: bump $OLD → $NEW, commit, push"; exit 0
  fi
  sed -i -E "s/(\"version\": *\")$OLD\"/\1$NEW\"/" "$PLUGIN_JSON" "$MARKET_JSON"
  [ "$(version)" = "$NEW" ] || { echo "FAILED: version bump"; exit 1; }
  git add -A
  git commit -q -m "$MSG" -m "build-task $NEW" || { echo "FAILED: commit"; exit 1; }
  echo "ok: committed version $NEW"
else
  echo "$AHEAD unpushed commit(s):"; git log --oneline "$UPSTREAM..HEAD" | sed 's/^/  /'
  [ "$MODE" = check ] && { echo "would: push them"; exit 0; }
fi

git push -q || { echo "FAILED: push — committed locally, rerun to retry"; exit 1; }
echo "ok: pushed version $(version) to GitHub"
echo "Every project picks this up at its next session start. Other machines: run /build --update there."
