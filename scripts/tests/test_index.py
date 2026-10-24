import os, unittest
from fixtures import TIMER_CARD, make_repo, remove

from btlib.index import INDEX_FILE, SecretFound, build, parse_card, words

FILES = {
    'src/timer.ts': 'export function saveSession() {}\n',
    'src/App.kt': 'fun startTimer() {}\n',
    'assets/bell.mp3': os.urandom(64) + b'\x00' + os.urandom(64),
    'src/blob.js': bytes([0, 1]) + b'binary' * 10,
    'src/latin.py': b'def caf' + bytes([233]) + b'_menu():' + bytes([10]) + b'    pass' + bytes([10]),
    'docs/index/cards/timer.md': TIMER_CARD,
}


class IndexBuild(unittest.TestCase):
    def setUp(self):
        self.repo = make_repo(FILES)

    def tearDown(self):
        remove(self.repo)

    def test_parse_card(self):
        c = parse_card(self.repo / 'docs/index/cards/timer.md')
        self.assertEqual(c['slug'], 'timer')
        self.assertEqual(c['title'], 'The timer')
        self.assertEqual(c['files'], ['src/timer.ts'])
        self.assertEqual(c['tables'], ['sessions'])
        self.assertEqual(c['checks'], ['node check.mjs', 'npm test'])
        self.assertIn('Saves runs.', c['notes'])

    def test_symbols_ts_and_kotlin(self):
        ix = build(self.repo)
        self.assertIn(['saveSession', 1], ix['symbols']['src/timer.ts'])
        self.assertIn(['startTimer', 1], ix['symbols']['src/App.kt'])

    def test_binary_tracked_file_skipped(self):  # Review Focus 4
        ix = build(self.repo)
        self.assertNotIn('assets/bell.mp3', ix['symbols'])
        self.assertNotIn('src/blob.js', ix['symbols'])   # binary with a code extension
        self.assertIn('src/latin.py', ix['symbols'])     # non-UTF-8 text still indexed

    def test_space_in_repo_path(self):  # Review Focus 1
        spaced = make_repo(FILES, name='Notebook digitalizer')
        try:
            ix = build(spaced)
            self.assertEqual(ix['cards'][0]['slug'], 'timer')
            self.assertIn('src/timer.ts', ix['files'])
        finally:
            remove(spaced)

    def test_secret_blocks_build(self):
        (self.repo / 'docs/index/cards/bad.md').write_text('# Bad\nkey sk-abcdefghijklmnopqrstuvwx\n')
        with self.assertRaises(SecretFound):
            build(self.repo)

    def test_no_spelling_correction(self):
        self.assertEqual(words('accounts protected'), ['account', 'protect'])

    def test_index_file_written(self):
        build(self.repo)
        self.assertTrue((self.repo / INDEX_FILE).exists())


if __name__ == '__main__':
    unittest.main()
