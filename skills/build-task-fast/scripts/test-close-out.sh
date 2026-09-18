#!/usr/bin/env bash
# test-close-out.sh — self-check for close-out.sh and log-run.sh.
#
# Runs in a throwaway repo with a local bare remote and a fake shared-history
# server on localhost, so it never touches a real project, GitHub or Supabase.
# Prints PASS/FAIL per check; exits 1 on any failure.
# Needs git, jq, curl, python.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
PY=$(command -v python3 || command -v python)
T=$(mktemp -d)
fails=0
check() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fails=$((fails+1)); fi; }
zlist() { "$PY" -m zipfile -l "$1"; }

# --- fake Supabase: GET filters by repo/task/run_date, POST appends ----------
cat > "$T/fake.py" <<'EOF'
import http.server, json, sys, urllib.parse
rows = []
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        want = {k: v[0][3:] for k, v in q.items() if k in ("repo", "task", "run_date")}
        hit = [r for r in rows if all(r.get(k) == v for k, v in want.items())]
        body = json.dumps(hit).encode()
        self.send_response(200); self.end_headers(); self.wfile.write(body)
    def do_POST(self):
        rows.append(json.loads(self.rfile.read(int(self.headers["Content-Length"]))))
        open(sys.argv[2], "w").write(json.dumps(rows))
        self.send_response(201); self.end_headers()
s = http.server.HTTPServer(("127.0.0.1", 0), H)
open(sys.argv[1], "w").write(str(s.server_address[1]))
s.serve_forever()
EOF
"$PY" "$T/fake.py" "$T/port" "$T/rows.json" & SRV=$!
trap 'kill $SRV 2>/dev/null; rm -rf "$T"' EXIT
for _ in $(seq 50); do [ -s "$T/port" ] && break; sleep 0.1; done
export HOME="$T/home" BUILD_TASK_SUPABASE_URL="http://127.0.0.1:$(cat "$T/port")" BUILD_TASK_SUPABASE_KEY=test
unset CLAUDE_PLUGIN_OPTION_SUPABASE_URL CLAUDE_PLUGIN_OPTION_SUPABASE_KEY
rows() { [ -f "$T/rows.json" ] && jq length "$T/rows.json" || echo 0; }

# --- throwaway project -------------------------------------------------------
git init -q --bare "$T/remote.git"
git clone -q "$T/remote.git" "$T/repo" 2>/dev/null
cd "$T/repo" && git config user.email t@t && git config user.name t && git config core.autocrlf false
R=agent-runs/active/2026-09-17_foo; D=agent-runs/done/2026-09-17_foo
mkdir -p docs/maps other "$R"
echo map > docs/maps/sys.md; echo x > other/untouched.md; echo code > app.txt
for f in 00-PROMPT 01-FINDINGS 02-CHECK 03-REVIEW 04-REPORT RESUME; do echo "$f" > "$R/$f.md"; done
git add -A && git commit -qm init && git push -q origin HEAD 2>/dev/null
BASE=$(git rev-parse HEAD)
echo code2 >> app.txt; echo map2 >> docs/maps/sys.md; git commit -qam feature
echo untracked-log > "$R/02-CHECK-output.log"
echo "# readme" > "$T/readme.md"

run() { bash "$HERE/close-out.sh" --task-dir "$R" --task foo --base "$BASE" \
  --readme "$T/readme.md" --outcome "done. test" "$@" \
  -- --verdict feasible --phases 0,1,2,3,4,5 --browser no --effort-signal none --lesson "a lesson"; }

out=$(run 2>&1); echo "$out"
check "folder moved"               "[ -d $D ] && [ ! -e $R ]"
check "untracked log moved too"    "[ -f $D/02-CHECK-output.log ]"
check "run log line committed"     "grep -q '— foo — done. test' agent-runs/done/README.md && git ls-files --error-unmatch agent-runs/done/README.md >/dev/null 2>&1"
check "zip untracked"              "[ -z \"\$(git ls-files '*.zip')\" ] && ls $D/foo-*.zip >/dev/null"
check "zip: RESUME, diff, map"     "zlist $D/foo-*.zip | grep -q run/RESUME.md && zlist $D/foo-*.zip | grep -q code-changes.diff && zlist $D/foo-*.zip | grep -q docs/maps/sys.md"
check "zip: untouched map left out" "! zlist $D/foo-*.zip | grep -q untouched"
check "history: one row, lesson"   "[ \$(rows) = 1 ] && jq -e '.[0].lessons[0]==\"a lesson\"' $T/rows.json >/dev/null"
check "RESUME.md deleted"          "[ ! -e $D/RESUME.md ]"
check "clean tree, remote in sync" "[ -z \"\$(git status --porcelain --untracked-files=no)\" ] && [ \$(git rev-parse HEAD) = \$(git -C $T/remote.git rev-parse HEAD) ]"

out=$(run 2>&1); echo "$out"
check "rerun: no FAILED"           "! grep -q FAILED <<<\"\$out\""
check "rerun: zip kept RESUME.md"  "zlist $D/foo-*.zip | grep -q run/RESUME.md"
check "rerun: one run log line"    "[ \$(grep -c '— foo —' agent-runs/done/README.md) = 1 ]"
check "rerun: no duplicate row"    "[ \$(rows) = 1 ] && grep -q 'not logging twice' <<<\"\$out\""

# Resume: close-out commit landed, then the session died (no zip, RESUME.md still there).
git reset -q --hard "$(git rev-list -n1 --grep='close out foo' HEAD)"
rm -f $D/foo-*.zip
out=$(run --no-push 2>&1); echo "$out"
check "resume: zip rebuilt with RESUME" "zlist $D/foo-*.zip | grep -q run/RESUME.md"
check "resume: still one row"      "[ \$(rows) = 1 ]"
check "resume: RESUME.md deleted"  "[ ! -e $D/RESUME.md ]"

# push: false in config is honoured.
# Outputs are captured before grepping: `run | grep -q` trips pipefail.
printf '{"push": false}' > build-task.config.json
out=$(run 2>&1)
check "config push:false honoured" "grep -q 'f) skip: push disabled' <<<\"\$out\""

# History not configured: warns, never blocks.
out=$(BUILD_TASK_SUPABASE_URL= BUILD_TASK_SUPABASE_KEY= run 2>&1)
check "no history config: warns, continues" "grep -q 'e) .*not configured' <<<\"\$out\" && grep -q '^g) ' <<<\"\$out\""

# A custom doneFolder from config is used as-is (no stray CR from Windows jq).
mkdir -p agent-runs/active/2026-09-17_bar && echo x > agent-runs/active/2026-09-17_bar/04-REPORT.md
printf '{"push": false, "doneFolder": "archive/finished"}' > build-task.config.json
bash "$HERE/close-out.sh" --task-dir agent-runs/active/2026-09-17_bar --task bar --base "$BASE" \
  --readme "$T/readme.md" --outcome "ok" -- --verdict feasible >/dev/null 2>&1
check "config doneFolder honoured" "[ -d archive/finished/2026-09-17_bar ] && grep -q '— bar —' archive/finished/README.md"

[ "$fails" = 0 ] && echo "ALL PASS" || { echo "$fails FAILED"; exit 1; }
