"""The project index: cards (meaning layer, committed) + a mechanical layer
(functions, fingerprints, word weights) rebuilt from the code. Stdlib only.

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
import hashlib, json, os, re, subprocess
from collections import Counter
from pathlib import Path

CARD_DIR = Path('docs/index/cards')
INDEX_FILE = Path('docs/index/index.json')

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
    out = _run(repo, 'git', 'status', '--porcelain', '-uall') or b''
    return hashlib.sha1(out).hexdigest()[:12]


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


def fingerprint(path):
    try:
        return hashlib.sha1(Path(path).read_bytes()).hexdigest()[:12]
    except OSError:
        return None


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
    symbols = {}
    for f in code_files(repo):
        if not f.endswith(CODE):
            continue
        text = _text(repo / f)
        if text is not None:
            symbols[f] = [[n, ln] for n, ln in extract_symbols(text, Path(f).suffix)]
    cards = load_cards(repo)
    for c in cards:
        c['fingerprints'] = {f: fingerprint(repo / f) for f in c['files']}
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
    ix = dict(head=head(repo), dirty=dirty(repo), cards=cards, symbols=symbols)
    (repo / INDEX_FILE).parent.mkdir(parents=True, exist_ok=True)
    (repo / INDEX_FILE).write_text(json.dumps(ix), encoding='utf-8')
    return ix
