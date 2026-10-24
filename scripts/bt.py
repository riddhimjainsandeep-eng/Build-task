"""bt — the mechanical half of build-task. Called through the `bt` wrapper from the project root.

  bt index build | ask "<query>" | toc | stale --since <commit> | record right|wrong | mode
  bt new-task <name>                         (the user's words on stdin; prints the folder)
  bt resume <task-dir> --phase P --done D --next N --half H
  bt check <task-dir> -- <command ...>       (exit code = the command's)
  bt saved-checks <task-dir> <card-slug ...>
  bt report <task-dir>                       (report text on stdin)
  bt plan-change <task-dir> <kind> "<text>"  (minor | severe-asked | skip-agreed | afk-severe)
  bt backup <task-dir> <path ...>
  bt hook install
  bt close | risk | cost | settings | history ...   (handled by the wrapper)
"""
import argparse, json, subprocess, sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from btlib import index, runs

for stream in (sys.stdout, sys.stderr):
    stream.reconfigure(encoding='utf-8', errors='replace')


def stdin_text():
    return sys.stdin.buffer.read().decode('utf-8', errors='replace')


def hook_install(repo):
    hooks = subprocess.run(['git', 'rev-parse', '--git-path', 'hooks'], cwd=repo, capture_output=True, text=True)
    if hooks.returncode != 0:
        print('bt: not a git repository; no hook installed (the index still rebuilds itself on every ask)')
        return 0
    hook = (Path(repo) / hooks.stdout.strip() / 'post-commit')
    line = f'bash "{Path(__file__).resolve().parent.as_posix()}/bt" index build >/dev/null 2>&1 || true'
    text = hook.read_text(encoding='utf-8') if hook.exists() else '#!/bin/sh\n'
    if line not in text:
        hook.parent.mkdir(parents=True, exist_ok=True)
        hook.write_text(text.rstrip('\n') + '\n' + line + '\n', encoding='utf-8')
        hook.chmod(0o755)
    print(f'hook: {hook}')
    return 0


def main(argv):
    repo = Path.cwd()
    if argv[:1] == ['check']:  # bt check <task-dir> -- <command ...>, kept verbatim
        if len(argv) < 4 or argv[2] != '--':
            print('usage: bt check <task-dir> -- <command ...>', file=sys.stderr)
            return 2
        return runs.run_check(argv[1], argv[3:])

    p = argparse.ArgumentParser(prog='bt', description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    ix = sub.add_parser('index').add_subparsers(dest='action', required=True)
    ix.add_parser('build')
    ix.add_parser('ask').add_argument('query')
    ix.add_parser('toc')
    ix.add_parser('stale').add_argument('--since', required=True)
    ix.add_parser('record').add_argument('result', choices=['right', 'wrong'])
    ix.add_parser('mode')
    sub.add_parser('new-task').add_argument('name')
    r = sub.add_parser('resume')
    r.add_argument('task_dir')
    for opt in ('--phase', '--done', '--next', '--half'):
        r.add_argument(opt, required=True)
    sc = sub.add_parser('saved-checks')
    sc.add_argument('task_dir')
    sc.add_argument('slugs', nargs='+')
    sub.add_parser('report').add_argument('task_dir')
    pc = sub.add_parser('plan-change')
    pc.add_argument('task_dir')
    pc.add_argument('kind', choices=runs.PLAN_KINDS)
    pc.add_argument('text')
    b = sub.add_parser('backup')
    b.add_argument('task_dir')
    b.add_argument('paths', nargs='+')
    sub.add_parser('hook').add_argument('action', choices=['install'])
    sub.add_parser('check', help='bt check <task-dir> -- <command ...>')
    a = p.parse_args(argv)

    if a.cmd == 'index':
        if a.action == 'build':
            try:
                built = index.build(repo)
            except index.SecretFound as e:
                print(f'bt: a card looks like it holds a secret — remove it and rebuild: {e}', file=sys.stderr)
                return 2
            print(f"built: {len(built['cards'])} cards, {len(built['symbols'])} code files, "
                  f"{sum(len(v) for v in built['symbols'].values())} functions")
        elif a.action == 'ask':
            print(index.ask(repo, a.query))
        elif a.action == 'toc':
            print(index.toc(repo))
        elif a.action == 'stale':
            print('\n'.join(index.stale_cards(repo, a.since)))
        elif a.action == 'record':
            print(json.dumps(index.record(repo, a.result == 'right')))
        else:
            print(json.dumps(index.trust_state(repo)))
    elif a.cmd == 'new-task':
        print(runs.new_task(repo, a.name, stdin_text(), date.today()))
    elif a.cmd == 'resume':
        runs.write_resume(a.task_dir, a.phase, a.done, a.next, a.half)
    elif a.cmd == 'saved-checks':
        failed = runs.saved_checks(repo, a.task_dir, a.slugs)
        print(f'saved checks failed: {failed}')
        return 1 if failed else 0
    elif a.cmd == 'report':
        print(runs.save_report(a.task_dir, stdin_text()))
    elif a.cmd == 'plan-change':
        runs.log_plan_change(a.task_dir, a.kind, a.text)
    elif a.cmd == 'backup':
        try:
            print(f'backup: {runs.backup(a.task_dir, a.paths)}')
        except ValueError as e:
            print(f'bt: backup FAILED — do not go ahead: {e}', file=sys.stderr)
            return 1
    elif a.cmd == 'hook':
        return hook_install(repo)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
