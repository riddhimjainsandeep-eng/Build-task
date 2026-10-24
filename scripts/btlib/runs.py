"""Mechanical run steps, so the AI never does them by hand. Stdlib only."""
import hashlib, json, os, shutil, subprocess
from datetime import datetime, timezone
from pathlib import Path

PLAN_KINDS = ('minor', 'severe-asked', 'skip-agreed', 'afk-severe')
PROMPT = """# {name}

## Your words
{words}

## How I read it
- **Goal:**
- **Now:**
- **Done looks like:**
- **Not in this task:**
- **Assumed:**
- **Could also mean:**
"""


def home():
    return Path(os.environ.get('BUILD_TASK_HOME') or Path.home() / '.claude' / 'build-task')


def task_folder(repo):
    try:
        cfg = json.loads((Path(repo) / 'build-task.config.json').read_text(encoding='utf-8'))
    except (OSError, ValueError):
        cfg = {}
    return Path(repo) / cfg.get('taskFolder', 'agent-runs/active')


def _head(repo):
    r = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=repo, capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else 'none'


def new_task(repo, name, words, today):
    base = task_folder(repo) / f'{today:%Y-%m-%d}_{name}'
    d, n = base, 2
    while d.exists():  # never overwrite an earlier run's words or phase files
        d, n = base.with_name(f'{base.name}-{n}'), n + 1
    d.mkdir(parents=True)
    (d / '00-PROMPT.md').write_text(PROMPT.format(name=name, words=words.rstrip()), encoding='utf-8')
    started = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    (d / 'RESUME.md').write_text(f'started: {started}\nbase: {_head(repo)}\n', encoding='utf-8')
    write_resume(d, '0', 'nothing yet', 'Phase 0', 'nothing')
    return d


def write_resume(task_dir, phase, done, next_, half):
    keep = (Path(task_dir) / 'RESUME.md').read_text(encoding='utf-8').splitlines()[:2]
    body = keep + [f'phase: {phase}', f'done: {done}', f'next: {next_}', f'half-written: {half}']
    (Path(task_dir) / 'RESUME.md').write_text('\n'.join(body) + '\n', encoding='utf-8')


def run_check(task_dir, cmd, cwd=None):
    """Run one check; full output appended to 02-CHECK-output.log; print exit code and the last 40 lines."""
    if isinstance(cmd, str):  # card checks are written in bash syntax
        shown, argv = cmd, [shutil.which('bash') or 'bash', '-c', cmd]
    else:  # resolve npm -> npm.cmd etc. the way a shell would
        shown, argv = ' '.join(map(str, cmd)), [shutil.which(cmd[0]) or cmd[0], *cmd[1:]]
    try:
        r = subprocess.run(argv, cwd=cwd, capture_output=True, text=True, errors='replace')
        code, out = r.returncode, (r.stdout or '') + (r.stderr or '')
    except OSError as e:
        code, out = 127, f'bt: could not run {argv[0]}: {e}\n'
    with open(Path(task_dir) / '02-CHECK-output.log', 'a', encoding='utf-8') as log:
        log.write(f'$ {shown}\n{out}exit={code}\n\n')
    print(f'$ {shown}\nexit={code}')
    print('\n'.join(out.splitlines()[-40:]))
    return code


def saved_checks(repo, task_dir, slugs):
    from btlib.index import load_cards
    cards = {c['slug']: c for c in load_cards(repo)}
    unknown = [s for s in slugs if s not in cards]
    if unknown:  # a misspelt card must never mean "no checks, all passed"
        raise ValueError(f'no card named: {", ".join(unknown)}')
    failed = 0
    for s in slugs:
        if not cards[s]['checks']:
            print(f'no saved checks: {s}')
        for cmd in cards[s]['checks']:
            failed += run_check(task_dir, cmd, cwd=repo) != 0
    return failed


def save_report(task_dir, text):
    p = Path(task_dir) / '04-REPORT.md'
    p.write_text(text, encoding='utf-8')
    return p


def log_plan_change(task_dir, kind, text):
    if kind not in PLAN_KINDS:
        raise ValueError(f'kind must be one of {", ".join(PLAN_KINDS)}')
    row = json.dumps({'at': datetime.now(timezone.utc).isoformat(timespec='seconds'),
                      'task': Path(task_dir).name, 'kind': kind, 'text': text})
    home().mkdir(parents=True, exist_ok=True)
    for p in (Path(task_dir) / 'plan-changes.jsonl', home() / 'plan-changes.jsonl'):
        with open(p, 'a', encoding='utf-8') as f:
            f.write(row + '\n')


def _sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def backup(task_dir, paths):
    """Copy each path into <task_dir>/backups/<time>/, verify every copy, print how to restore."""
    dest = Path(task_dir) / 'backups' / datetime.now().strftime('%Y%m%d-%H%M%S')
    pairs = []
    for src in map(Path, paths):
        files = [f for f in src.rglob('*') if f.is_file()] if src.is_dir() else [src]
        if not src.exists() or not any(f.stat().st_size for f in files):
            raise ValueError(f'nothing to back up (missing or empty): {src}')
        try:
            rel = src.resolve().relative_to(Path.cwd().resolve())
        except ValueError:
            rel = Path(src.name)
        target = dest / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        (shutil.copytree if src.is_dir() else shutil.copy2)(src, target)
        for f in files:
            copy = target / f.relative_to(src) if src.is_dir() else target
            if _sha(f) != _sha(copy):
                raise ValueError(f'backup copy differs from the original: {f}')
        pairs.append((target, src))
    for target, src in pairs:  # a folder: copy its contents back, not the folder into itself
        print(f'restore: cp -r "{target}/." "{src}"' if src.is_dir() else f'restore: cp "{target}" "{src}"')
    return dest
