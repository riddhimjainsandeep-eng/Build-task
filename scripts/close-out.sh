#!/usr/bin/env bash
# close-out.sh — Phase 5 steps (c) to (g) of build-task-v2 in one call.
#
# Every step is safe to repeat: a rerun skips what is already done. Prints one
# "ok / skip / held / FAILED" line per step; a FAILED step is left for the agent
# to do by hand, then rerun. Reads the user's settings (settings.sh) itself.
#
# Usage, from the repo root:
#   close-out.sh --task-dir agent-runs/active/2026-09-18_foo --task foo \
#     --base <sha> --outcome "done. prose" --check pass|fail --review pass|fail \
#     --risk "B R K T G D" [--rounds N] [--readme FILE] [--backups DIR] \
#     [--push-approved] -- <log-run.sh arguments except --task>
#
# Pushing happens only when --check and --review are both "pass", and then per
# the `push` setting: auto pushes, ask needs --push-approved, never holds.
#
# Self-check: test-close-out.sh beside this file.

set -uo pipefail

TASK_DIR="" TASK="" BASE="" README="" OUTCOME="" BACKUPS=""
CHECK="" REVIEW="" RISK="" ROUNDS=0 APPROVED=0
while [ $# -gt 0 ]; do
  case "$1" in
    --task-dir) TASK_DIR="${2%/}"; shift 2 ;;
    --task)     TASK="$2"; shift 2 ;;
    --base)     BASE="$2"; shift 2 ;;
    --readme)   README="$2"; shift 2 ;;
    --outcome)  OUTCOME="$2"; shift 2 ;;
    --backups)  BACKUPS="$2"; shift 2 ;;
    --check)    CHECK="$2"; shift 2 ;;
    --review)   REVIEW="$2"; shift 2 ;;
    --risk)     RISK="$2"; shift 2 ;;
    --rounds)   ROUNDS="$2"; shift 2 ;;
    --push-approved) APPROVED=1; shift ;;
    --) shift; break ;;
    *) echo "close-out.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done
LOG_ARGS=("$@")

need() { echo "close-out.sh: $*" >&2; exit 2; }
[ -n "$TASK_DIR" ] && [ -n "$TASK" ] && [ -n "$BASE" ] && [ -n "$OUTCOME" ] \
  || need "--task-dir --task --base --outcome are required"
case "$CHECK"  in pass|fail) ;; *) need "--check must be pass or fail" ;; esac
case "$REVIEW" in pass|fail) ;; *) need "--review must be pass or fail" ;; esac
git rev-parse --verify -q "$BASE^{commit}" >/dev/null || need "$BASE is not a commit"

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC2086
RISK_JSON=$(bash "$HERE/risk-score.sh" --json $RISK 2>/dev/null) || need "--risk needs six scores 1-3, e.g. \"3 1 2 2 1 3\""
setting() { bash "$HERE/settings.sh" get "$1"; }
ZIP=$(setting zip); HISTORY=$(setting history); PUSH_MODE=$(setting push)

cfg() {  # tr: the Windows jq build ends lines with CRLF, which would poison paths.
  local v=""
  [ -f build-task.config.json ] && v=$(jq -r --arg k "$1" '.[$k] | select(. != null)' build-task.config.json 2>/dev/null | tr -d '\r')
  printf '%s' "${v:-$2}"
}
DONE_ROOT=$(cfg doneFolder agent-runs/done)
DOCS_ROOT=$(cfg docsRoot docs/maps)
DONE_DIR="$DONE_ROOT/$(basename "$TASK_DIR")"
TODAY=$(date +%Y-%m-%d)
ZIP_OUT=""

REPO=$(git remote get-url origin 2>/dev/null | sed -E 's#^git@[^:]+:#/#; s#^https?://[^/]+/#/#; s#\.git$##; s#^/##')
[ -n "$REPO" ] || REPO=$(basename "$(git rev-parse --show-toplevel)")
RISK_LOG="${BUILD_TASK_RISK_LOG:-$HOME/.claude/build-task/risk-log.jsonl}"
log_risk() {  # the local calibration log: every run's score with its outcome
  mkdir -p "$(dirname "$RISK_LOG")"
  if grep -F "\"task\":\"$TASK\"" "$RISK_LOG" 2>/dev/null | grep -F "\"repo\":\"$REPO\"" | grep -qF "\"date\":\"$TODAY\""; then
    echo "e) skip: risk log already has this run"
  else
    jq -nc --arg date "$TODAY" --arg repo "$REPO" --arg task "$TASK" --argjson risk "$RISK_JSON" \
      --arg check "$CHECK" --arg review "$REVIEW" --argjson rounds "${ROUNDS:-0}" \
      '{date:$date, repo:$repo, task:$task} + $risk + {check:$check, review:$review, failedRounds:$rounds}' \
      | tr -d '\r' >> "$RISK_LOG" && echo "e) ok: risk score and outcome logged for calibration"
  fi
}

# A run that did not pass is not closed: moving it to done/ would leave its
# commits unpushed on the branch, where the next run's push would ship them.
if [ "$CHECK" != pass ] || [ "$REVIEW" != pass ]; then
  log_risk
  echo "held: check=$CHECK review=$REVIEW — the run stays in $TASK_DIR, nothing moved or pushed."
  echo "held: its commits ($BASE..HEAD) are local only; the user decides: fix, revert, or accept."
  exit 0
fi
[ "$ZIP" = true ] && [ -z "$README" ] && need "--readme is required while the zip setting is on"

# ---- c) move and log --------------------------------------------------------
if [ -d "$TASK_DIR" ]; then
  [ -e "$DONE_DIR" ] && { echo "c) FAILED: both $TASK_DIR and $DONE_DIR exist"; exit 1; }
  mkdir -p "$DONE_ROOT"
  if git ls-files --error-unmatch "$TASK_DIR" >/dev/null 2>&1; then
    git mv "$TASK_DIR" "$DONE_DIR" || { echo "c) FAILED: git mv"; exit 1; }
    # git mv carries only tracked files; bring the untracked rest along.
    if [ -d "$TASK_DIR" ]; then cp -r "$TASK_DIR"/. "$DONE_DIR"/ && rm -rf "$TASK_DIR"; fi
  else
    mv "$TASK_DIR" "$DONE_DIR" || { echo "c) FAILED: mv"; exit 1; }
  fi
  echo "c) ok: moved to $DONE_DIR"
elif [ -d "$DONE_DIR" ]; then
  echo "c) skip: already in $DONE_DIR"
else
  echo "c) FAILED: neither $TASK_DIR nor $DONE_DIR exists"; exit 1
fi

if grep -qF -- "— $TASK — " "$DONE_ROOT/README.md" 2>/dev/null; then
  echo "c) skip: run log already has $TASK"
else
  printf -- '- %s — %s — %s\n' "$TODAY" "$TASK" "$OUTCOME" >> "$DONE_ROOT/README.md" && echo "c) ok: run log line appended"
fi

# The archive stays untracked. A bare ":(exclude)*.zip" silently staged nothing
# on git 2.53, so the exclude carries the full path.
git add -A -- "$DONE_ROOT" ":(exclude)$DONE_ROOT/**/*.zip"
if git diff --cached --quiet; then
  echo "c) skip: nothing to commit"
else
  git commit -q -m "build-task: close out $TASK" && echo "c) ok: committed"
fi

# ---- d) archive -------------------------------------------------------------
if [ "$ZIP" != true ]; then
  echo "d) skip: zip is off in settings"
else
  ZIP_OUT="$(cd "$DONE_DIR" && pwd)/$TASK-$TODAY.zip"
  if [ -s "$ZIP_OUT" ] && [ ! -e "$DONE_DIR/RESUME.md" ]; then
    # Rebuilding now would drop RESUME.md, which (g) already deleted.
    echo "d) skip: archive exists and RESUME.md is gone"
  else
    STAGE=$(mktemp -d); trap 'rm -rf "$STAGE"' EXIT
    A="$STAGE/$TASK-$TODAY"
    mkdir -p "$A/run" "$A/docs" "$A/backups"
    cp "$README" "$A/README.md"
    git diff "$BASE"..HEAD > "$A/code-changes.diff"
    find "$DONE_DIR" -maxdepth 1 -type f ! -name '*.zip' -exec cp {} "$A/run/" \;
    git diff --name-only --diff-filter=d "$BASE"..HEAD -- "$DOCS_ROOT" | while IFS= read -r f; do
      mkdir -p "$A/docs/$(dirname "$f")" && cp "$f" "$A/docs/$f"
    done
    [ -n "$BACKUPS" ] && [ -d "$BACKUPS" ] && cp -r "$BACKUPS"/. "$A/backups/"
    rmdir "$A/docs" "$A/backups" 2>/dev/null   # no empty folders; the README says why
    rm -f "$ZIP_OUT"
    if command -v zip >/dev/null 2>&1; then
      (cd "$STAGE" && zip -qr "$ZIP_OUT" "$TASK-$TODAY")
    elif PY=$(command -v python3 || command -v python) && [ -n "$PY" ]; then
      (cd "$STAGE" && "$PY" -m zipfile -c "$ZIP_OUT" "$TASK-$TODAY")
    elif command -v powershell.exe >/dev/null 2>&1; then
      powershell.exe -NoProfile -Command "Compress-Archive -Path '$(cygpath -w "$A")' -DestinationPath '$(cygpath -w "$ZIP_OUT")' -Force"
    fi
    [ -s "$ZIP_OUT" ] && echo "d) ok: $ZIP_OUT ($(wc -c < "$ZIP_OUT" | tr -d ' ') bytes)" \
      || echo "d) FAILED: no zip tool (zip, python, powershell) produced $ZIP_OUT"
  fi
fi

# ---- e) shared history (never blocks) + local risk calibration log ------------
if [ "$HISTORY" = true ]; then
  bash "$HERE/log-run.sh" --task "$TASK" ${LOG_ARGS+"${LOG_ARGS[@]}"} 2>&1 | sed 's/^/e) /'
else
  echo "e) skip: shared history is off in settings"
fi

log_risk

# ---- f) push — per the push setting (only reached when both passed) ----------
push() {
  case "$PUSH_MODE" in
    never) echo "$1) held: push is 'never' in settings"; return ;;
    ask) [ "$APPROVED" = 1 ] || { echo "$1) held: push is 'ask' — ask the user, then rerun with --push-approved"; return; } ;;
  esac
  git push -q 2>&1 && echo "$1) ok: pushed" || echo "$1) FAILED: push"
}
push f

# ---- g) delete RESUME.md, last ----------------------------------------------
if [ -e "$DONE_DIR/RESUME.md" ]; then
  if git ls-files --error-unmatch "$DONE_DIR/RESUME.md" >/dev/null 2>&1; then
    git rm -q "$DONE_DIR/RESUME.md" && git commit -q -m "build-task: $TASK finished, remove RESUME.md"
  else
    rm "$DONE_DIR/RESUME.md"
  fi
  echo "g) ok: RESUME.md deleted"
  push g
else
  echo "g) skip: no RESUME.md"
fi
exit 0
