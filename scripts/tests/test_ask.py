import unittest
from fixtures import git, make_repo, remove

from btlib.index import ask, build, stale_cards, toc

CARDS = {
    'timer': '# The timer\nalso: pomodoro, session, clock\nfiles: src/timer.ts\n',
    'push': '# Web Push — notifications\nalso: notification, push, alert on phone\nfiles: src/push.ts\ntables: push_subscriptions\n',
    'login': '# Password Gate\nalso: login, password, cookie\nfiles: src/login.ts\n',
    'revision': '# Revision queue\nalso: revise, revision, due chapters\nfiles: src/revision.ts\n',
}
FILES = {f'docs/index/cards/{k}.md': v for k, v in CARDS.items()}
FILES.update({
    'src/timer.ts': 'export function saveSession() {}\n',
    'src/push.ts': 'export function sendPush() {}\n',
    'src/login.ts': 'export function checkPassword() {}\n',
    'src/revision.ts': 'export function dueChapters() {}\n',
    'src/lib/day-boundary.ts': 'export function studyDayOf() {}\n',
})


class Ask(unittest.TestCase):
    def setUp(self):
        self.repo = make_repo(FILES)

    def tearDown(self):
        remove(self.repo)

    def test_best_card_first(self):
        out = ask(self.repo, 'web push duplicate notification')
        self.assertTrue(out.splitlines()[0].startswith('mode: watch'))
        self.assertRegex(out.splitlines()[1], r'^1\. Web Push')

    def test_safety_net_finds_uncarded_code(self):
        self.assertIn('day-boundary.ts', ask(self.repo, 'day boundary midnight'))

    def test_not_confident_on_vague_query(self):
        self.assertIn('confident: no', ask(self.repo, 'where is my money going'))

    def test_confident_on_clear_query(self):
        self.assertIn('confident: yes', ask(self.repo, 'login password cookie'))

    def test_rebuilds_when_code_changes(self):
        ask(self.repo, 'timer')
        (self.repo / 'src/timer.ts').write_text('export function newName() {}\n')
        self.assertIn('newName', ask(self.repo, 'timer new name'))

    def test_missing_file_flagged(self):  # Review Focus 3
        build(self.repo)
        (self.repo / 'src/push.ts').unlink()
        self.assertIn('MISSING: src/push.ts', ask(self.repo, 'web push'))

    def test_changed_since_card_written(self):
        (self.repo / 'src/login.ts').write_text('export function checkPassword(x) {}\n')
        git(self.repo, 'commit', '-qam', 'change login')
        self.assertIn('CHANGED: src/login.ts', ask(self.repo, 'login password'))

    def test_no_git_repo(self):  # Review Focus 2
        plain = make_repo(FILES, commit=None)
        try:
            self.assertIn('1. The timer', ask(plain, 'timer session'))
        finally:
            remove(plain)

    def test_stale_cards(self):
        base = git(self.repo, 'rev-parse', 'HEAD')
        (self.repo / 'src/login.ts').write_text('x')
        self.assertEqual(stale_cards(self.repo, base), ['login'])

    def test_toc_lists_every_card(self):
        lines = toc(self.repo).splitlines()
        self.assertEqual(len(lines), 4)
        self.assertIn('login — Password Gate — also: login, password, cookie', lines)


if __name__ == '__main__':
    unittest.main()
