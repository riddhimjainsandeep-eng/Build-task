"""Throwaway git repos for the bt tests. Never touches a real project."""
import os, shutil, subprocess, sys, tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))  # scripts/ -> import btlib

ENV = dict(os.environ, GIT_AUTHOR_NAME='t', GIT_AUTHOR_EMAIL='t@t', GIT_COMMITTER_NAME='t', GIT_COMMITTER_EMAIL='t@t')


def git(repo, *args):
    return subprocess.run(['git', *args], cwd=repo, env=ENV, capture_output=True, text=True, check=True).stdout.strip()


def make_repo(files: dict, name='repo', commit=True) -> Path:
    """files: {relative path: str or bytes}. Returns the repo path; removed at exit by the caller's tearDown."""
    root = Path(tempfile.mkdtemp()) / name
    root.mkdir(parents=True)
    for rel, body in files.items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        (p.write_bytes if isinstance(body, bytes) else p.write_text)(body)
    if commit is not None:
        git(root, 'init', '-q')
        if commit:
            git(root, 'add', '-A')
            git(root, 'commit', '-q', '-m', 'init')
    return root


def remove(path: Path):
    shutil.rmtree(path.parent, ignore_errors=True)


TIMER_CARD = ("# The timer\nalso: pomodoro, session\nfiles: src/timer.ts\ntables: sessions\n"
              "connects: Study Log\nsymptoms: block shows nothing\nchecks: node check.mjs; npm test\nSaves runs.\n")
