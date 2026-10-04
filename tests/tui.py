#!/usr/bin/env python3
"""Exercise terminal actions with fake system commands; never change the host."""
import errno
import json
import os
import pty
import select
import shutil
import subprocess
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='outpost-tui-') as directory:
    tmp = Path(directory)
    bin_dir = tmp / 'bin'
    bin_dir.mkdir()
    calls = tmp / 'calls'
    state = tmp / 'state'
    count = tmp / 'count'
    env = dict(os.environ, PATH=str(bin_dir), HOME=str(tmp), USER='desktop',
               TERM='xterm', CALLS=str(calls), STATE=str(state), COUNT=str(count),
               MENU_STATE=str(tmp / 'menu-state'))
    env.pop('SUDO_USER', None)
    for command in ('bash', 'env', 'jq', 'cat', 'touch'):
        (bin_dir / command).symlink_to(shutil.which(command))

    def stub(name, body):
        path = bin_dir / name
        path.write_text('#!/bin/bash\nset -eu\n' + body + '\n')
        path.chmod(0o755)

    for name in ('outpost', 'update', 'rebase', 'outpost-rollback', 'cac-help'):
        source = (ROOT / 'files/system/usr/bin' / name).read_text()
        source = source.replace('/usr/lib/outpost/lib.sh', str(ROOT / 'files/system/usr/lib/outpost/lib.sh'))
        source = source.replace('/var/home/linuxbrew/.linuxbrew/bin/brew', str(tmp / 'absent'))
        path = bin_dir / name
        path.write_text(source)
        path.chmod(0o755)
    stub('id', 'if [[ "$1" == -u ]]; then echo "${INVOKING_UID:-1000}"; else echo desktop; fi')
    stub('getent', 'printf "desktop:x:1000:1000::%s:/bin/bash\\n" "$HOME"')
    stub('sudo', '''printf 'sudo %s\n' "$*" >> "$CALLS"
if [[ "$1" == -H ]]; then shift 3; fi
exec "$@"''')
    stub('rpm-ostree', '''if [[ "$1" == status ]]; then
    n=0; [[ ! -f "$COUNT" ]] || read -r n < "$COUNT"
    echo "$((n+1))" > "$COUNT"
    if [[ "${CHANGE:-0}" == 1 && "$n" != 0 ]]; then echo '{"deployments":[]}'; else cat "$STATE"; fi
else
    printf 'rpm-ostree %s\n' "$*" >> "$CALLS"
    exit "${OS_RC:-0}"
fi''')
    stub('ostree', 'printf "ostree %s\\n" "$*" >> "$CALLS"')
    stub('distrobox', '''printf 'distrobox %s USER=%s HOME=%s\n' "$*" "$USER" "$HOME" >> "$CALLS"
if [[ "$1" == list ]]; then
    [[ "${LIST_RC:-0}" == 0 ]] || { echo 'container engine unavailable' >&2; exit "$LIST_RC"; }
    echo 'ID | NAME | STATUS | IMAGE'
    [[ "${EMPTY:-0}" == 1 ]] || echo 'abcdef012345 | dev | Exited | fedora:43'
else
    echo 'Native container update progress'
    exit "${BOX_RC:-0}"
fi''')
    stub('gum', '''printf 'gum %s\n' "$*" >> "$CALLS"
case "$1" in
    confirm) exit "${CONFIRM_RC:-0}" ;;
    choose)
        if [[ "${CYCLE:-0}" == 1 ]]; then
            if [[ -f "$MENU_STATE" ]]; then echo Quit; else touch "$MENU_STATE"; echo 'System status'; fi
            exit 0
        fi
        shift
        while [[ "$1" != -- ]]; do shift; done
        shift
        for option in "$@"; do
            if [[ "$option" == "${CHOICE:-Back}"* ]]; then echo "$option"; exit 0; fi
        done
        exit 1 ;;
esac''')
    # Prevent the user's login profile from running while looking for Homebrew.
    (bin_dir / 'bash').unlink()
    stub('bash', 'if [[ "${1:-}" == -lc ]]; then exit 1; fi\nexec /bin/bash "$@"')
    stub('systemctl', 'exit 0')
    stub('uname', 'echo test-kernel')

    def deployments(channel='outpost'):
        return {'deployments': [
            {'booted': True, 'checksum': 'a' * 64, 'serial': 0, 'osname': 'fedora',
             'container-image-reference': f'ostree-image-signed:docker://ghcr.io/large-farva/{channel}:latest'},
            {'booted': False, 'checksum': 'b' * 64, 'serial': 0, 'osname': 'fedora', 'version': '43-old'},
            {'booted': False, 'checksum': 'c' * 64, 'serial': 1, 'osname': 'fedora', 'version': '43-pinned', 'pinned': True}]}

    def run(name, code=0, terminal=True, data=None, **overrides):
        state.write_text(json.dumps(data if data is not None else deployments()))
        count.write_text('0\n')
        calls.write_text('')
        if not terminal:
            result = subprocess.run([str(bin_dir / name)], check=False, env=env | overrides, capture_output=True, text=True, timeout=10)
            assert result.returncode == code, result
            output = result.stdout + result.stderr
            assert '\x1b[' not in output
        else:
            master, slave = pty.openpty()
            process = subprocess.Popen([str(bin_dir / name)], env=env | overrides, stdin=slave, stdout=slave, stderr=slave)
            os.close(slave)
            chunks = []
            deadline = time.monotonic() + 10
            try:
                while time.monotonic() < deadline:
                    if select.select([master], [], [], .1)[0]:
                        try:
                            chunk = os.read(master, 65536)
                        except OSError as error:
                            if error.errno == errno.EIO:
                                break
                            raise
                        if not chunk:
                            break
                        chunks.append(chunk)
                        if b'Press Enter to return' in chunk:
                            os.write(master, b'\n')
                else:
                    process.kill()
                    raise AssertionError('terminal command timed out')
                output = b''.join(chunks).decode()
                assert process.wait(timeout=2) == code, output
            finally:
                os.close(master)
                if process.poll() is None:
                    process.kill()
                    process.wait()
        return output, calls.read_text()

    for channel, target in [('outpost', 'outpost-testing'), ('outpost-testing', 'outpost'),
                            ('outpost-personal', 'outpost')]:
        _, log = run('rebase', data=deployments(channel))
        assert f'rebase ostree-image-signed:docker://ghcr.io/large-farva/{target}:latest' in log
    for kwargs in ({'CONFIRM_RC': '1'}, {'CHANGE': '1'}, {'data': deployments('other')}):
        _, log = run('rebase', code=0 if 'CONFIRM_RC' in kwargs else 1, **kwargs)
        assert 'rpm-ostree rebase' not in log
    pending = deployments()
    pending['deployments'].insert(0, {'booted': False, 'checksum': 'pending'})
    for name in ('rebase', 'outpost-rollback'):
        _, log = run(name, 1, data=pending)
        assert 'gum confirm' not in log
    _, log = run('rebase', 1, terminal=False)
    assert 'rpm-ostree rebase' not in log
    output, log = run('outpost-rollback', CHOICE='2:')
    assert 'ostree admin set-default 2' in log and 'cccccccc' in output, (output, log)
    assert '--header= --header.foreground=' in log and '--prompt.foreground=' in log
    for kwargs in ({'CONFIRM_RC': '1'}, {'CHANGE': '1'}, {'CHOICE': 'Back'}):
        _, log = run('outpost-rollback', 1 if 'CHANGE' in kwargs else 0, CHOICE=kwargs.pop('CHOICE', '1:'), **kwargs)
        assert 'ostree admin set-default' not in log
    single = deployments()
    single['deployments'] = single['deployments'][:1]
    output, log = run('outpost-rollback', data=single)
    assert 'No saved rollback' in output and not log
    _, log = run('rebase', 5, OS_RC='5')
    assert 'rpm-ostree rebase' in log
    output, log = run('outpost-rollback', terminal=False)
    assert 'sudo rpm-ostree rollback' in output and not log
    output, log = run('outpost', CHOICE='Quit')
    assert '\x1b[H\x1b[2J' in output
    output, _ = run('outpost', CYCLE='1')
    assert output.count('\x1b[H\x1b[2J') == 3, output
    for kwargs, expected in [({}, 'success'), ({'CONFIRM_RC': '1'}, 'skipped'),
                             ({'EMPTY': '1'}, 'skipped'), ({'terminal': False}, 'skipped'),
                             ({'BOX_RC': '2'}, 'failed'), ({'LIST_RC': '1'}, 'failed')]:
        output, log = run('update', 1 if 'BOX_RC' in kwargs or 'LIST_RC' in kwargs else 0, **kwargs)
        assert f'Distrobox: {expected}' in output, output
        assert ('distrobox upgrade --all' in log) == (expected == 'success' or 'BOX_RC' in kwargs)
    output, log = run('update', SUDO_USER='desktop', INVOKING_UID='0')
    assert 'sudo -H -u desktop' in log and f'USER=desktop HOME={tmp}' in log
    _, log = run('update', 130, BOX_RC='130')
    assert 'distrobox upgrade --all' in log
    _, log = run('update', 130, CONFIRM_RC='130')
    assert 'distrobox upgrade' not in log
    output, _ = run('outpost', terminal=False)
    assert '1 container(s)' in output and 'dev' in output
    print('PASS: TUI redraw, neutral prompts, channel switching, rollback selection, Distrobox updates and user context')
