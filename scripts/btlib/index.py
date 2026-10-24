"""The project index: cards (meaning layer, committed) + a mechanical layer
(functions, file list, word weights) rebuilt from the code. Stdlib only.

Cards live in docs/index/cards/<slug>.md, one per behaviour/system:
    # Title
    also: words people use
    files: path, path
    tables: name, name
    connects: other systems
    symptoms: what a user sees when this breaks
    checks: shell command; another command
    any other line is a note
"""
import hashlib, json, math, os, re, subprocess
from collections import Counter
from pathlib import Path

CARD_DIR = Path('docs/index/cards')
INDEX_FILE = Path('docs/index/index.json')
TRUST_FILE = Path('docs/index/trust.json')
SHOW = 3            # cards shown: the best in full, the next two as one-liners
LEAD = 1.3          # confident only if the best card scores >= LEAD x the second ...
COVERAGE = 0.5      # ... and holds at least this share of the question's words
RARE = 0.2          # safety net: a word in <= 20% of functions counts as specific
TRUST_AFTER = 5     # correct answers in a row before the index is trusted (watch -> trust)

CODE = ('.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.py', '.sql', '.kt', '.java')
SKIP_DIRS = {'.git', 'node_modules', '__pycache__', '.next', 'dist', 'build', '.venv'}
STOP = set('a an the and or of to in on for is it its be by as at with from this that my me i we you he his '
           'do does not no so if when what how why which make can should must want just all any every '
           'into out up there here now only also than then them they are was were has have had will'.split())
SYM = [re.compile(p, re.M) for p in (
    r'^\s*export\s+(?:default\s+)?(?:async\s+)?function\s+(\w+)',
    r'^\s*(?:export\s+)?const\s+(\w+)\s*=\s*(?:async\s*)?(?:\(|function)',
    r'^\s*(?:async\s+)?function\s+(\w+)',
    r'^\s*export\s+(?:interface|type|class)\s+(\w+)',
    r'^\s*(?:async\s+)?def\s+(\w+)', r'^\s*class\s+(\w+)',
    r'(?i)^\s*create\s+(?:or\s+replace\s+)?(?:table|function|trigger)\s+(?:if\s+not\s+exists\s+)?(?:public\.)?(\w+)',
    r'^\s*(?:private |internal |public |override )*(?:suspend )?fun\s+(\w+)',
    r'^\s*(?:data |sealed |enum |abstract |open )*(?:class|object|interface)\s+(\w+)',
    r'^\s*(?:public|private|protected)[\w<>\[\],\s]*\s(\w+)\s*\(')]
WEIGHTS = dict(title=2.0, also=3.0, notes=1.0, path=1.0, symbol=0.5, connects=1.5, symptoms=2.0)
SECRETS = [re.compile(p) for p in (
    r'sk-[A-Za-z0-9_-]{20,}', r'AKIA[0-9A-Z]{16}', r'ghp_[A-Za-z0-9]{30,}',
    r'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}', r'-----BEGIN [A-Z ]*PRIVATE KEY-----',
    r'(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*\S{12,}')]


class SecretFound(Exception):
    pass


def words(text):
    text = re.sub(r'([a-z])([A-Z])', r'\1 \2', text)  # camelCase -> camel Case
    out = []
    for w in re.findall(r'[a-z0-9]+', text.lower()):
        if w in STOP or len(w) < 2:
            continue
        for suf in ('ing', 'ed', 'es', 's'):  # crude stemming, same on both sides; no spelling correction
            if w.endswith(suf) and len(w) - len(suf) >= 3 and not w.endswith('ss'):
                w = w[:-len(suf)]
                break
        out.append(w)
    return out


def _split(v, sep=','):
    return [x.strip() for x in v.split(sep) if x.strip()]


def parse_card(path):
    path = Path(path)
    c = dict(slug=path.stem, title=path.stem, also='', files=[], tables=[], connects='', symptoms='', checks=[], notes='')
    notes = []
    for ln in path.read_text(encoding='utf-8', errors='replace').splitlines():
        key, _, val = ln.partition(':')
        key = key.strip().lower()
        if ln.startswith('# ') and c['title'] == path.stem:
            c['title'] = ln[2:].strip()
        elif key in ('also', 'connects', 'symptoms'):
            c[key] = val.strip()
        elif key in ('files', 'tables'):
            c[key] = _split(val)
        elif key == 'checks':
            c['checks'] = _split(val, ';')
        else:
            notes.append(ln)
    c['notes'] = '\n'.join(notes).strip()
    return c


def load_cards(repo):
    d = Path(repo) / CARD_DIR
    return [parse_card(p) for p in sorted(d.glob('*.md'))] if d.is_dir() else []


def _run(repo, *args):
    try:
        r = subprocess.run(args, cwd=repo, capture_output=True)
        return r.stdout if r.returncode == 0 else None
    except OSError:
        return None


def head(repo):
    out = _run(repo, 'git', 'rev-parse', 'HEAD')
    return out.decode().strip() if out else None


def dirty(repo):
    """Hash of uncommitted state: each changed path plus its size and mtime, so editing
    an already-modified file again still counts. The index's own files are left out."""
    out = _run(repo, 'git', 'status', '--porcelain', '-uall', '-z', '--', '.',
               ':!' + INDEX_FILE.as_posix(), ':!' + TRUST_FILE.as_posix()) or b''
    h = hashlib.sha1(out)
    for entry in out.decode('utf-8', 'replace').split('\0'):
        try:
            st = (Path(repo) / entry[3:]).stat()
            h.update(f'{st.st_size}:{st.st_mtime_ns}'.encode())
        except OSError:
            pass
    return h.hexdigest()[:12]


def code_files(repo):
    out = _run(repo, 'git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard')
    if out is not None:
        return [f for f in out.decode('utf-8', 'replace').split('\0') if f]
    files = []  # not a git repo: walk the tree
    for dirpath, dirnames, filenames in os.walk(repo):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        files += [os.path.relpath(os.path.join(dirpath, f), repo).replace(os.sep, '/') for f in filenames]
    return files


def _text(path):
    try:
        data = Path(path).read_bytes()
    except OSError:
        return None
    if b'\0' in data[:8192]:
        return None  # binary
    return data.decode('utf-8', errors='replace')


def extract_symbols(text, suffix=''):
    found = {}
    for rx in SYM:
        for m in rx.finditer(text):
            found.setdefault(m.group(1), text.count('\n', 0, m.start()) + 1)
    return sorted(found.items(), key=lambda x: x[1])


def find_secrets(repo):
    hits = []
    for p in sorted((Path(repo) / CARD_DIR).glob('*.md')):
        for i, ln in enumerate(p.read_text(encoding='utf-8', errors='replace').splitlines(), 1):
            for rx in SECRETS:
                m = rx.search(ln)
                if m:
                    hits.append((str(p.relative_to(repo)).replace(os.sep, '/'), i, m.group(0)[:20]))
                    break
    return hits


def build(repo):
    repo = Path(repo)
    secrets = find_secrets(repo)
    if secrets:
        raise SecretFound('; '.join(f'{p}:{n} ({s}...)' for p, n, s in secrets))
    symbols, files = {}, code_files(repo)
    for f in files:
        if not f.endswith(CODE):
            continue
        text = _text(repo / f)
        if text is not None:
            symbols[f] = [[n, ln] for n, ln in extract_symbols(text, Path(f).suffix)]
    cards = load_cards(repo)
    for c in cards:
        bag = Counter()
        for field, text in (('title', c['title']), ('also', c['also']), ('notes', c['notes'] + ' ' + ' '.join(c['tables'])),
                            ('path', ' '.join(c['files'])), ('connects', c['connects']), ('symptoms', c['symptoms'])):
            for w in words(text):
                bag[w] += WEIGHTS[field]
        for f in c['files']:
            for name, _ in symbols.get(f, []):
                for w in words(name):
                    bag[w] += WEIGHTS['symbol']
        c['bag'] = dict(bag)
    ix = dict(head=head(repo), dirty=dirty(repo), cards=cards, symbols=symbols, files=files)
    (repo / INDEX_FILE).parent.mkdir(parents=True, exist_ok=True)
    (repo / INDEX_FILE).write_text(json.dumps(ix), encoding='utf-8')
    return ix


def load(repo):
    """The saved index, rebuilt first if the code changed since it was built."""
    repo = Path(repo)
    try:
        ix = json.loads((repo / INDEX_FILE).read_text(encoding='utf-8'))
    except (OSError, ValueError):
        return build(repo)
    if ix.get('head') is None or ix['head'] != head(repo) or ix.get('dirty') != dirty(repo):
        return build(repo)
    return ix


def rank(ix, query):
    cards, q = ix['cards'], set(words(query))
    if not cards:
        return []
    avg = sum(sum(c['bag'].values()) for c in cards) / len(cards) or 1
    df = Counter(w for c in cards for w in c['bag'])
    scored = []
    for c in cards:
        L, s = sum(c['bag'].values()), 0.0
        for w in q:
            tf = c['bag'].get(w, 0)
            if tf:
                idf = math.log(1 + (len(cards) - df[w] + 0.5) / (df[w] + 0.5))
                s += idf * tf * 2.2 / (tf + 1.2 * (0.25 + 0.75 * L / avg))  # BM25, k1=1.2 b=0.75
        scored.append((s, c))
    return sorted(scored, key=lambda x: -x[0])


def confident(ranked, query):
    q = set(words(query))
    if not ranked or ranked[0][0] <= 0 or not q:
        return False
    second = ranked[1][0] if len(ranked) > 1 else 0
    covered = len(q & set(ranked[0][1]['bag'])) / len(q)
    return ranked[0][0] >= LEAD * second and covered >= COVERAGE


def code_hits(ix, query, skip, k=4):
    """Safety net over every function name and file path not on the shown cards."""
    q = set(words(query))
    docs = [(f, n, ln, set(words(n)) | set(words(f))) for f, syms in ix['symbols'].items() if f not in skip for n, ln in syms]
    docs += [(f, '', 0, set(words(f))) for f in ix.get('files', []) if f not in skip and not ix['symbols'].get(f)]
    if not docs or not q:
        return []
    df = Counter(w for *_, ws in docs for w in ws)
    rare = {w for w in q if df[w] and df[w] <= max(1, RARE * len(docs))}
    scored = sorted(((sum(math.log(len(docs) / df[w]) for w in q & ws), f, n, ln)
                     for f, n, ln, ws in docs if rare & ws), reverse=True)
    best, seen = [], set()
    for s, f, n, ln in scored:
        if f not in seen:
            seen.add(f)
            best.append((f, n, ln))
        if len(best) == k:
            break
    return best


def card_changes(repo, card):
    """(changed, missing): card files changed since the card file was last committed, and files gone."""
    repo = Path(repo)
    missing = [f for f in card['files'] if not (repo / f).exists()]
    since = _run(repo, 'git', 'log', '-1', '--format=%H', '--', (CARD_DIR / f"{card['slug']}.md").as_posix())
    changed = []
    if since and since.strip():
        out = _run(repo, 'git', 'diff', '--name-only', since.decode().strip(), '--', *card['files']) or b''
        changed = [f for f in out.decode().split('\n') if f and f not in missing]
    return changed, missing


def trust_state(repo):
    try:
        return json.loads((Path(repo) / TRUST_FILE).read_text(encoding='utf-8'))
    except (OSError, ValueError):
        return {'mode': 'watch', 'streak': 0}


def ask(repo, query):
    ix = load(repo)
    ranked = rank(ix, query)
    top = [r for r in ranked[:SHOW] if r[0] > 0]
    out = [f"mode: {trust_state(repo)['mode']} · confident: {'yes' if confident(ranked, query) else 'no'}"]
    if not top:
        out.append('No card matches.')
    q = set(words(query))
    for i, (s, c) in enumerate(top):
        out.append(f"{i + 1}. {c['title']}  (score {s:.1f})")
        out.append(f"   files: {', '.join(c['files'])}")
        out.append(f"   tables: {', '.join(c['tables'])}")
        changed, missing = card_changes(repo, c)
        out += [f'   CHANGED: {f}' for f in changed] + [f'   MISSING: {f}' for f in missing]
        if i == 0:
            for key in ('connects', 'symptoms'):
                if c[key]:
                    out.append(f'   {key}: {c[key]}')
            out += ['   ' + ln for ln in c['notes'].splitlines() if ln.strip()]
            hits = [(f, n, ln) for f in c['files'] for n, ln in ix['symbols'].get(f, []) if set(words(n)) & q]
            if hits:
                out.append('   matching functions: ' + ', '.join(f'{n} ({f}:{ln})' for f, n, ln in hits[:6]))
    net = code_hits(ix, query, {f for _, c in top for f in c['files']})
    if net:
        out.append('Other code matching: ' + ', '.join(f'{n} ({f}:{ln})' if n else f for f, n, ln in net))
    return '\n'.join(out)


def toc(repo):
    return '\n'.join(f"{c['slug']} — {c['title']} — also: {c['also']}" for c in load_cards(repo))


def stale_cards(repo, since):
    out = (_run(repo, 'git', 'diff', '--name-only', since) or b'').decode()
    out += (_run(repo, 'git', 'ls-files', '--others', '--exclude-standard') or b'').decode()
    changed = set(out.split())
    return [c['slug'] for c in load_cards(repo) if changed & set(c['files'])]


def record(repo, right):
    """Watch mode until the index has been right TRUST_AFTER times in a row; one miss resets it."""
    s = trust_state(repo)
    s = {'mode': 'watch', 'streak': 0} if not right else {'streak': s['streak'] + 1, 'mode': 'watch'}
    if s['streak'] >= TRUST_AFTER:
        s['mode'] = 'trust'
    (Path(repo) / TRUST_FILE).parent.mkdir(parents=True, exist_ok=True)
    (Path(repo) / TRUST_FILE).write_text(json.dumps(s), encoding='utf-8')
    return {'mode': s['mode'], 'streak': s['streak']}
