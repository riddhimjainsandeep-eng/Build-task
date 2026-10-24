"""Score the index on real questions (not part of the unit suite).

  python eval_index.py <repo> <questions.json> [rewrites.json]

questions.json: [{"task": ..., "question": ..., "expected": [file or table, ...]}]
rewrites.json (optional, same order): [{"search": "<question in the app's words>"}]
"""
import json, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from btlib.index import SHOW, ask, code_hits, load, rank

repo, qs = Path(sys.argv[1]), json.loads(Path(sys.argv[2]).read_text(encoding='utf-8'))
rw = json.loads(Path(sys.argv[3]).read_text(encoding='utf-8')) if len(sys.argv) > 3 else [{}] * len(qs)
ix = load(repo)
complete = top_right = 0
tokens = 0
for q, r in zip(qs, rw):
    query = r.get('search') or q['question']
    shown = [c for s, c in rank(ix, query)[:SHOW] if s > 0]
    listed = {f for c in shown for f in c['files']} | {t for c in shown for t in c['tables']}
    listed |= {f for f, _, _ in code_hits(ix, query, {f for c in shown for f in c['files']})}
    found = [e for e in q['expected'] if e in listed]
    right = bool(shown) and any(e in shown[0]['files'] or e in shown[0]['tables'] for e in q['expected'])
    tok = len(ask(repo, query)) // 4
    complete += len(found) == len(q['expected']); top_right += right; tokens += tok
    print(f"{'COMPLETE' if len(found) == len(q['expected']) else 'PARTIAL ' if found else 'MISS    '} "
          f"top {'right' if right else 'wrong'}  ~{tok:4} tok  {q['task']}")
n = len(qs)
print(f'\ncomplete {complete}/{n}   top card right {top_right}/{n}   avg ~{tokens // n} tokens')
