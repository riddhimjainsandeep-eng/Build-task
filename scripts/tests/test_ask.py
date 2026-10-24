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


class AskReviewFixes(unittest.TestCase):
    def setUp(self):
        files = dict(FILES)
        files['src/My Comp/login form.ts'] = 'export function loginForm() {}\n'
        files['docs/index/cards/form.md'] = '# Login form\nalso: form\nfiles: ' + r'src\My Comp\login form.ts' + '\n'
        files['docs/index/cards/empty.md'] = '# No files card\nalso: nothing\n'
        self.repo = make_repo(files)

    def tearDown(self):
        remove(self.repo)

    def test_I3_backslash_paths_normalised(self):
        from btlib.index import parse_card
        self.assertEqual(parse_card(self.repo / 'docs/index/cards/form.md')['files'], ['src/My Comp/login form.ts'])

    def test_I3_stale_handles_spaces(self):
        base = git(self.repo, 'rev-parse', 'HEAD')
        (self.repo / 'src/My Comp/login form.ts').write_text('export function x() {}\n')
        self.assertIn('form', stale_cards(self.repo, base))

    def test_I5_checked_clears_changed(self):
        from btlib.index import mark_checked
        (self.repo / 'src/login.ts').write_text('export function checkPassword(x) {}\n')
        git(self.repo, 'commit', '-qam', 'change login')
        self.assertIn('CHANGED: src/login.ts', ask(self.repo, 'login password'))
        mark_checked(self.repo, ['login'])
        self.assertNotIn('CHANGED', ask(self.repo, 'login password'))

    def test_I5_card_without_files_never_changed(self):
        from btlib.index import card_changes, parse_card
        (self.repo / 'src/login.ts').write_text('y')
        git(self.repo, 'commit', '-qam', 'touch')
        self.assertEqual(card_changes(self.repo, parse_card(self.repo / 'docs/index/cards/empty.md')), ([], []))

    def test_M1_secret_card_does_not_crash_ask(self):
        (self.repo / 'docs/index/cards/bad.md').write_text('# Bad\nsk-abcdefghijklmnopqrstuvwx\n')
        self.assertIn('secret', ask(self.repo, 'login'))
