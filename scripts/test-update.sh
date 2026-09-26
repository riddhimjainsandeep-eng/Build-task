#!/usr/bin/env bash
# test-update.sh — self-check for update.sh against throwaway clones and a local
# bare remote. Never touches the real plugin or GitHub.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fails=0
check() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fails=$((fails+1)); fi; }
ver() { sed -nE 's/.*"version": *"([^"]+)".*/\1/p' "$1/.claude-plugin/$2" | head -1; }

git init -q --bare "$T/remote.git"
git clone -q "$T/remote.git" "$T/a" 2>/dev/null
cd "$T/a" && git config user.email t@t && git config user.name t
mkdir -p .claude-plugin scripts
printf '{\n  "name": "build-task",\n  "version": "1.1.1"\n}\n' > .claude-plugin/plugin.json
printf '{\n  "plugins": [\n    {\n      "name": "build-task",\n      "version": "1.1.1"\n    }\n  ]\n}\n' > .claude-plugin/marketplace.json
cp "$HERE/update.sh" scripts/ && echo rule > SKILL.md
git add -A && git commit -qm init && git push -q origin HEAD 2>/dev/null
git clone -q "$T/remote.git" "$T/b" 2>/dev/null
git -C "$T/b" config user.email t@t; git -C "$T/b" config user.name t

out=$(bash scripts/update.sh --check)
check "clean: up to date"          "grep -q 'already up to date' <<<\"\$out\""

echo "rule 2" >> SKILL.md
out=$(bash scripts/update.sh --check)
check "check: says it would bump"  "grep -q 'would: bump 1.1.1 → 1.1.2' <<<\"\$out\""
check "check: changed nothing"     "[ \"\$(ver . plugin.json)\" = 1.1.1 ] && [ -n \"\$(git status --porcelain)\" ]"

out=$(bash scripts/update.sh --message "add rule 2")
check "publish: both versions bumped" "[ \"\$(ver . plugin.json)\" = 1.1.2 ] && [ \"\$(ver . marketplace.json)\" = 1.1.2 ]"
check "publish: committed and pushed" "[ -z \"\$(git status --porcelain)\" ] && [ \$(git rev-parse HEAD) = \$(git -C $T/remote.git rev-parse HEAD) ]"

cd "$T/b"
out=$(bash scripts/update.sh --message pull)
check "other machine: pulled"      "grep -q 'pulled' <<<\"\$out\" && grep -q 'rule 2' SKILL.md && [ \"\$(ver . plugin.json)\" = 1.1.2 ]"

# Diverged: new commit on GitHub (from a) plus a local edit here → refuse.
cd "$T/a" && echo "rule 3" >> SKILL.md && bash scripts/update.sh --message "rule 3" >/dev/null
cd "$T/b" && echo "local" >> SKILL.md
out=$(bash scripts/update.sh --message "local")
check "diverged: refuses, changes nothing" "grep -q FAILED <<<\"\$out\" && grep -q local SKILL.md && [ \"\$(ver . plugin.json)\" = 1.1.2 ]"

# Marketplace install: a plain copy, sitting inside someone's dotfiles repo.
# Must call `claude plugin …` and never commit to the outer repo.
git init -q "$T/dotfiles" && M="$T/dotfiles/plugin" && mkdir -p "$M/.claude-plugin" "$M/scripts" "$T/bin"
printf '{\n  "name": "build-task",\n  "version": "1.1.1"\n}\n' > "$M/.claude-plugin/plugin.json"
printf '{\n  "name": "riddhim-tools",\n  "plugins": [{ "name": "build-task" }]\n}\n' > "$M/.claude-plugin/marketplace.json"
cp "$HERE/update.sh" "$M/scripts/"
printf '#!/bin/sh\necho "$*" >> "%s"\n' "$T/claude.log" > "$T/bin/claude" && chmod +x "$T/bin/claude"
out=$(PATH="$T/bin:$PATH" bash "$M/scripts/update.sh" --check)
check "marketplace check: calls nothing" "grep -q 'would: fetch' <<<\"\$out\" && [ ! -e $T/claude.log ]"
out=$(PATH="$T/bin:$PATH" bash "$M/scripts/update.sh" --message pull)
check "marketplace: fetches via claude" "grep -q 'restart Claude Code' <<<\"\$out\" && grep -qx 'plugin marketplace update riddhim-tools' $T/claude.log && grep -qx 'plugin update build-task@riddhim-tools' $T/claude.log"
check "marketplace: outer repo untouched" "! git -C $T/dotfiles rev-parse -q --verify HEAD >/dev/null"

[ "$fails" = 0 ] && echo "ALL PASS" || { echo "$fails FAILED"; exit 1; }
