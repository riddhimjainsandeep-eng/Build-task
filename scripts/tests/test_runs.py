import json, os, sys, tempfile, unittest
from datetime import date
from pathlib import Path
from fixtures import make_repo, remove

from btlib.index import record, trust_state
from btlib.runs import backup, log_plan_change, new_task, run_check, save_report, saved_checks, task_folder, write_resume

FILES = {'src/a.ts': 'export function a() {}\n',
         'docs/index/cards/a.md': '# A\nfiles: src/a.ts\nchecks: python -c "exit(0)"; python -c "exit(5)"\n'}


class Runs(unittest.TestCase):
    def setUp(self):
        self.repo = make_repo(FILES)
        self.home = tempfile.mkdtemp()
        os.environ['BUILD_TASK_HOME'] = self.home  # plan-change log goes here, not ~/.claude
        self.d = new_task(self.repo, 'demo', 'fix it', date(2026, 10, 24))

    def tearDown(self):
        remove(self.repo)

    def test_watch_to_trust_after_five(self):
        self.assertEqual(trust_state(self.repo), {'mode': 'watch', 'streak': 0})
        for _ in range(5):
            s = record(self.repo, True)
        self.assertEqual(s, {'mode': 'trust', 'streak': 5})
        self.assertEqual(record(self.repo, False), {'mode': 'watch', 'streak': 0})

    def test_new_task_keeps_words_verbatim(self):
        d = new_task(self.repo, 'login-fix', 'yaa the lohin is too annoyying', date(2026, 10, 24))
        self.assertEqual(d.name, '2026-10-24_login-fix')
        self.assertEqual(d.parent, self.repo / 'agent-runs/active')
        prompt = (d / '00-PROMPT.md').read_text(encoding='utf-8')
        self.assertIn('yaa the lohin is too annoyying', prompt)
        self.assertIn('## How I read it', prompt)
        self.assertRegex((d / 'RESUME.md').read_text(), r'base: [0-9a-f]{40}')

    def test_task_folder_from_config(self):
        (self.repo / 'build-task.config.json').write_text(json.dumps({'taskFolder': 'runs/now'}))
        self.assertEqual(task_folder(self.repo), self.repo / 'runs/now')

    def test_resume_keeps_start_and_base(self):
        before = (self.d / 'RESUME.md').read_text().splitlines()[:2]
        write_resume(self.d, '2', 'code committed', 'run check', 'nothing')
        after = (self.d / 'RESUME.md').read_text()
        self.assertEqual(after.splitlines()[:2], before)
        self.assertIn('next: run check', after)

    def test_run_check_logs_and_returns_code(self):
        code = run_check(self.d, [sys.executable, '-c', "import sys; print('hi'); sys.exit(3)"])
        self.assertEqual(code, 3)
        log = (self.d / '02-CHECK-output.log').read_text()
        self.assertIn('hi', log)
        self.assertIn('exit=3', log)

    def test_saved_checks_counts_failures(self):
        self.assertEqual(saved_checks(self.repo, self.d, ['a']), 1)

    def test_save_report(self):
        self.assertEqual(save_report(self.d, 'Done.\n').read_text(), 'Done.\n')

    def test_plan_change_logged_in_both_places(self):
        log_plan_change(self.d, 'minor', 'checked stats page first')
        row = json.loads((self.d / 'plan-changes.jsonl').read_text().splitlines()[-1])
        self.assertEqual((row['kind'], row['text']), ('minor', 'checked stats page first'))
        self.assertTrue((Path(self.home) / 'plan-changes.jsonl').exists())
        with self.assertRaises(ValueError):
            log_plan_change(self.d, 'whatever', 'x')

    def test_backup_verifies_and_handles_spaces(self):  # Review Focus 1
        f = self.repo / 'my notes.txt'
        f.write_text('data')
        out = backup(self.d, [f])
        self.assertEqual((out / 'my notes.txt').read_text(), 'data')

    def test_backup_refuses_empty(self):
        e = self.repo / 'empty.txt'
        e.write_text('')
        with self.assertRaises(ValueError):
            backup(self.d, [e])


if __name__ == '__main__':
    unittest.main()
