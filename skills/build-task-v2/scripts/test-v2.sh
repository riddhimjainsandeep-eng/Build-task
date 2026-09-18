#!/usr/bin/env bash
# test-v2.sh — self-check for build-task-v2's scripts: risk-score, settings,
# run-cost and close-out.
#
# Everything runs in throwaway folders with a local bare remote and a fake
# shared-history server on localhost — never a real project, GitHub or Supabase.
# Prints PASS/FAIL per check; exits 1 on any failure. Needs git, jq, curl, python.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
PY=$(command -v python3 || command -v python)
T=$(mktemp -d)
fails=0
check() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fails=$((fails+1)); fi; }
zlist() { "$PY" -m zipfile -l "$1"; }
export BUILD_TASK_SETTINGS="$T/settings.json" BUILD_TASK_RISK_LOG="$T/risk-log.jsonl"

# ============================== risk-score ====================================
rs() { bash "$HERE/risk-score.sh" "$@" 2>&1; }
check "risk: all 1s → 1 LOW"                 "rs 1 1 1 1 1 1 | grep -q 'Score: 1 — LOW'"
check "risk: one high alone → 3 LOW"         "rs 3 1 1 1 1 1 | grep -q 'Score: 3 — LOW'"
check "risk: formatDate example → 15 MID"    "rs 3 1 2 2 1 3 | grep -q 'Score: 15 — MID'"
check "risk: compounding → 21 HIGH, opus"    "rs 3 1 3 3 1 3 | grep -q 'Score: 21 — HIGH' && rs 3 1 3 3 1 3 | grep -q 'model: opus'"
check "risk: edge 6 is LOW"                  "rs 2 1 3 3 3 1 | grep -q 'Score: 6 — LOW'"
check "risk: edge 20 is MID"                 "rs 2 1 3 2 1 5 2>/dev/null; rs 1 2 3 3 3 3 | grep -q 'Score: 18 — MID' && rs 2 2 3 3 3 1 | grep -q 'Score: 12 — MID'"
check "risk: json output"                    "rs --json 3 3 3 2 2 2 | jq -e '.score==42 and .level==\"HIGH\"' >/dev/null"
check "risk: rejects out-of-range"           "! bash $HERE/risk-score.sh 4 1 1 1 1 1 2>/dev/null"

# ============================== settings ======================================
mkdir -p "$T/proj" && cd "$T/proj"
st() { bash "$HERE/settings.sh" "$@" 2>&1; }
check "settings: defaults match v1"          "st | jq -e '.zip==true and .push==\"auto\" and .maps==\"apply\" and .handoff==true' >/dev/null"
st set global zip=false push=ask >/dev/null
check "settings: global set"                 "[ \$(st get zip) = false ] && [ \$(st get push) = ask ]"
printf '{"doneFolder":"x","push":false}' > build-task.config.json
check "settings: v1 push:false → never"      "[ \$(st get push) = never ]"
st set project push=auto handoff=false >/dev/null
check "settings: project overrides global"   "[ \$(st get push) = auto ] && [ \$(st get handoff) = false ] && [ \$(st get zip) = false ]"
check "settings: project file keeps config"  "jq -e '.doneFolder==\"x\"' build-task.config.json >/dev/null"
check "settings: rejects bad value"          "! bash $HERE/settings.sh set global push=sometimes 2>/dev/null"
check "settings: rejects unknown key"        "! bash $HERE/settings.sh set global colour=red 2>/dev/null"
rm -f "$BUILD_TASK_SETTINGS"; cd "$T"

# ============================== run-cost ======================================
TR="$T/sess.jsonl"; mkdir -p "$T/sess/subagents"
cat > "$TR" <<'EOF'
{"type":"assistant","timestamp":"2026-09-18T09:00:00Z","message":{"id":"m0","content":[{"type":"tool_use"}],"usage":{"input_tokens":999,"output_tokens":999}}}
{"type":"assistant","timestamp":"2026-09-18T10:00:00Z","message":{"id":"m1","content":[{"type":"text"}],"usage":{"input_tokens":1000,"cache_creation_input_tokens":2000,"cache_read_input_tokens":50000,"output_tokens":300}}}
{"type":"assistant","timestamp":"2026-09-18T10:00:01Z","message":{"id":"m1","content":[{"type":"tool_use"}],"usage":{"input_tokens":1000,"cache_creation_input_tokens":2000,"cache_read_input_tokens":50000,"output_tokens":300}}}
{"type":"user","timestamp":"2026-09-18T10:05:00Z","message":{"content":"x"}}
{"type":"assistant","timestamp":"2026-09-18T10:30:00Z","message":{"id":"m2","content":[{"type":"tool_use"},{"type":"tool_use"}],"usage":{"input_tokens":500,"cache_read_input_tokens":60000,"output_tokens":700}}}
EOF
echo '{"type":"assistant","timestamp":"2026-09-18T10:10:00Z","message":{"id":"s1","content":[{"type":"tool_use"}],"usage":{"input_tokens":4000,"output_tokens":100}}}' > "$T/sess/subagents/a.jsonl"
out=$(bash "$HERE/run-cost.sh" --since 2026-09-18T10:00:00Z --transcript "$TR")
echo "$out"
check "cost: only turns since, ids deduped"  "grep -q 'main session: 2 turns · 3 tool calls · 4k new input · 110k re-read · 1k output' <<<\"\$out\""
check "cost: wall time"                      "grep -q '— 30 min wall time' <<<\"\$out\""
check "cost: subagents counted"              "grep -q 'subagents:    1 turns · 1 tool calls · 4k new input' <<<\"\$out\""

# ============================== close-out =====================================
cat > "$T/fake.py" <<'EOF'
import http.server, json, sys, urllib.parse
rows = []
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        want = {k: v[0][3:] for k, v in q.items() if k in ("repo", "task", "run_date")}
        hit = [r for r in rows if all(r.get(k) == v for k, v in want.items())]
        self.send_response(200); self.end_headers(); self.wfile.write(json.dumps(hit).encode())
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
risklines() { [ -f "$BUILD_TASK_RISK_LOG" ] && wc -l < "$BUILD_TASK_RISK_LOG" | tr -d ' ' || echo 0; }

git init -q --bare "$T/remote.git"
git clone -q "$T/remote.git" "$T/repo" 2>/dev/null
cd "$T/repo" && git config user.email t@t && git config user.name t && git config core.autocrlf false
newtask() {  # newtask <name> -> creates an active run with a feature commit, sets BASE
  R="agent-runs/active/2026-09-18_$1"; mkdir -p "$R" docs/maps
  for f in 00-PROMPT 01-FINDINGS RISK 02-CHECK 03-REVIEW 04-REPORT RESUME; do echo "$f" > "$R/$f.md"; done
  echo map > docs/maps/sys.md; git add -A; git commit -qm "start $1"; git push -q origin HEAD 2>/dev/null
  BASE=$(git rev-parse HEAD)
  echo "$1" >> app.txt; echo "map $1" >> docs/maps/sys.md; git add -A; git commit -qm "feature $1"
  echo log > "$R/02-CHECK-output.log"
}
echo "# readme" > "$T/readme.md"
run() { local name=$1; shift
  bash "$HERE/close-out.sh" --task-dir "agent-runs/active/2026-09-18_$name" --task "$name" --base "$BASE" \
    --readme "$T/readme.md" --outcome "done. test" --risk "3 1 2 2 1 3" "$@" \
    -- --verdict feasible --phases 0,1,2,3,4,5 --browser no --effort-signal none --lesson "a lesson" 2>&1; }
remote_head() { git -C "$T/remote.git" rev-parse HEAD; }

# 1) failed review: held, nothing moved or pushed, outcome logged
newtask bad; before=$(remote_head)
out=$(run bad --check pass --review fail); echo "$out"
check "fail: run stays in active"        "[ -d agent-runs/active/2026-09-18_bad ] && [ ! -e agent-runs/done/2026-09-18_bad ]"
check "fail: nothing pushed"             "[ \"\$(remote_head)\" = \"$before\" ]"
check "fail: says the user decides"      "grep -q 'the user decides' <<<\"\$out\""
check "fail: outcome in risk log"        "tail -1 $BUILD_TASK_RISK_LOG | jq -e '.review==\"fail\" and .level==\"MID\" and .score==15' >/dev/null"
check "fail: no history row"             "[ \$(rows) = 0 ]"
git reset -q --hard "$BASE"; rm -rf agent-runs/active/2026-09-18_bad

# 2) full pass run with default settings
newtask foo
out=$(run foo --check pass --review pass); echo "$out"
D=agent-runs/done/2026-09-18_foo
check "pass: moved + untracked log kept" "[ -d $D ] && [ -f $D/02-CHECK-output.log ] && [ ! -e agent-runs/active/2026-09-18_foo ]"
check "pass: run log committed"          "grep -q '— foo — done. test' agent-runs/done/README.md && git ls-files --error-unmatch agent-runs/done/README.md >/dev/null 2>&1"
check "pass: zip has RESUME, RISK, diff, map" "zlist $D/foo-*.zip | grep -q run/RESUME.md && zlist $D/foo-*.zip | grep -q run/RISK.md && zlist $D/foo-*.zip | grep -q code-changes.diff && zlist $D/foo-*.zip | grep -q docs/maps/sys.md"
check "pass: zip untracked"              "[ -z \"\$(git ls-files '*.zip')\" ]"
check "pass: one history row"            "[ \$(rows) = 1 ]"
check "pass: risk log has pass"          "tail -1 $BUILD_TASK_RISK_LOG | jq -e '.task==\"foo\" and .check==\"pass\" and .review==\"pass\"' >/dev/null"
check "pass: RESUME gone, all pushed"    "[ ! -e $D/RESUME.md ] && [ \$(git rev-parse HEAD) = \"\$(remote_head)\" ]"

# 3) rerun is a no-op
n=$(risklines)
out=$(run foo --check pass --review pass); echo "$out"
check "rerun: no FAILED, no duplicates"  "! grep -q FAILED <<<\"\$out\" && [ \$(rows) = 1 ] && [ \$(risklines) = $n ] && [ \$(grep -c '— foo —' agent-runs/done/README.md) = 1 ]"
check "rerun: zip still has RESUME.md"   "zlist $D/foo-*.zip | grep -q run/RESUME.md"

# 4) settings: push=ask holds, then --push-approved pushes; zip and history off
bash "$HERE/settings.sh" set global push=ask zip=false history=false >/dev/null
newtask bar; D=agent-runs/done/2026-09-18_bar
out=$(bash "$HERE/close-out.sh" --task-dir agent-runs/active/2026-09-18_bar --task bar --base "$BASE" \
  --outcome "ok" --check pass --review pass --risk "1 1 1 1 1 1" -- --verdict feasible 2>&1); echo "$out"
check "ask: held, not pushed"            "grep -q \"f) held: push is 'ask'\" <<<\"\$out\" && [ \$(git rev-parse HEAD) != \"\$(remote_head)\" ]"
check "zip off: no zip, no readme needed" "grep -q 'd) skip: zip is off' <<<\"\$out\" && ! ls $D/*.zip >/dev/null 2>&1"
check "history off: no row"              "grep -q 'e) skip: shared history is off' <<<\"\$out\" && [ \$(rows) = 1 ]"
out=$(bash "$HERE/close-out.sh" --task-dir agent-runs/active/2026-09-18_bar --task bar --base "$BASE" \
  --outcome "ok" --check pass --review pass --risk "1 1 1 1 1 1" --push-approved -- --verdict feasible 2>&1); echo "$out"
check "ask + approved: pushed"           "grep -q 'f) ok: pushed' <<<\"\$out\" && [ \$(git rev-parse HEAD) = \"\$(remote_head)\" ]"

bash "$HERE/settings.sh" set global push=never >/dev/null
newtask baz
out=$(bash "$HERE/close-out.sh" --task-dir agent-runs/active/2026-09-18_baz --task baz --base "$BASE" \
  --outcome "ok" --check pass --review pass --risk "1 1 1 1 1 1" --push-approved -- --verdict feasible 2>&1)
check "never: held even when approved"   "grep -q \"f) held: push is 'never'\" <<<\"\$out\" && [ \$(git rev-parse HEAD) != \"\$(remote_head)\" ]"

# 5) bad input is refused before anything moves
rm -f "$BUILD_TASK_SETTINGS"; newtask qux
check "refuses missing --review"         "! bash $HERE/close-out.sh --task-dir agent-runs/active/2026-09-18_qux --task qux --base $BASE --outcome x --check pass --risk '1 1 1 1 1 1' >/dev/null 2>&1 && [ -d agent-runs/active/2026-09-18_qux ]"
check "refuses bad --risk"               "! bash $HERE/close-out.sh --task-dir agent-runs/active/2026-09-18_qux --task qux --base $BASE --outcome x --check pass --review pass --risk '9 9' >/dev/null 2>&1 && [ -d agent-runs/active/2026-09-18_qux ]"
check "zip on needs --readme"            "! bash $HERE/close-out.sh --task-dir agent-runs/active/2026-09-18_qux --task qux --base $BASE --outcome x --check pass --review pass --risk '1 1 1 1 1 1' >/dev/null 2>&1"

[ "$fails" = 0 ] && echo "ALL PASS" || { echo "$fails FAILED"; exit 1; }
