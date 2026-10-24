import os, shutil, subprocess, tempfile, unittest
from pathlib import Path
from fixtures import make_repo, remove

BT = Path(__file__).resolve().parents[1] / 'bt'
# PATH lookup, like a shell: on Windows a bare 'bash' in subprocess finds WSL's System32\bash.exe first
BASH = shutil.which('bash') or 'bash'
FILES = {'src/push.ts': 'export function sendPush() {}\n',
         'docs/index/cards/push.md': '# Web Push\nalso: notification, push\nfiles: src/push.ts\n'}


def run_bt(args, cwd, stdin='', env=None):
    return subprocess.run([BASH, str(BT), *args], cwd=cwd, input=stdin, capture_output=True, text=True,
                          encoding='utf-8', errors='replace', env=env)


class Cli(unittest.TestCase):
    def setUp(self):
        self.repo = make_repo(FILES)

    def tearDown(self):
        remove(self.repo)

    def test_index_ask(self):
        r = run_bt(['index', 'ask', 'push notification'], self.repo)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('1. Web Push', r.stdout)

    def test_new_task_from_stdin(self):
        r = run_bt(['new-task', 'demo'], self.repo, stdin='make it ring\n')
        self.assertEqual(r.returncode, 0, r.stderr)
        d = Path(r.stdout.strip().splitlines()[-1])
        self.assertIn('make it ring', (d / '00-PROMPT.md').read_text())

    def test_check_passes_exit_code_through(self):
        d = run_bt(['new-task', 'demo'], self.repo, stdin='x').stdout.strip().splitlines()[-1]
        r = run_bt(['check', d, '--', 'python', '-c', 'exit(4)'], self.repo)
        self.assertEqual(r.returncode, 4)

    def test_risk_passthrough(self):
        r = run_bt(['risk', '1', '1', '1', '1', '1', '1'], self.repo)
        self.assertIn('LOW', r.stdout)

    def test_secret_exit_code(self):
        (self.repo / 'docs/index/cards/bad.md').write_text('# Bad\nsk-abcdefghijklmnopqrstuvwx\n')
        r = run_bt(['index', 'build'], self.repo)
        self.assertEqual(r.returncode, 2)
        self.assertIn('bad.md:2', r.stdout + r.stderr)

    def test_wrapper_skips_broken_python3(self):  # Review Focus 5
        fake = Path(tempfile.mkdtemp())
        (fake / 'python3').write_text('#!/bin/sh\nexit 9\n')
        (fake / 'python3').chmod(0o755)
        env = dict(os.environ, PATH=str(fake) + os.pathsep + os.environ['PATH'])
        try:
            r = run_bt(['index', 'toc'], self.repo, env=env)
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertIn('push — Web Push', r.stdout)
        finally:
            shutil.rmtree(fake, ignore_errors=True)


if __name__ == '__main__':
    unittest.main()


class CliReviewFixes(unittest.TestCase):
    def test_M2_runs_from_a_subfolder(self):
        repo = make_repo(FILES)
        try:
            r = run_bt(['index', 'toc'], repo / 'src')
            self.assertIn('push — Web Push', r.stdout)
            self.assertFalse((repo / 'src' / 'docs').exists())
        finally:
            remove(repo)
