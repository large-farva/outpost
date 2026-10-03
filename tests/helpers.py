#!/usr/bin/env python3
"""Run helpers against disposable command stubs; never update the host or use a CAC."""
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    with tempfile.TemporaryDirectory(prefix='outpost-test-') as directory:
        tmp = Path(directory)
        bin_dir = tmp / 'bin'
        bin_dir.mkdir()
        home = tmp / 'home'
        home.mkdir()
        calls = tmp / 'calls'
        provider = tmp / 'opensc-pkcs11.so'
        provider.touch()
        lib = ROOT / 'files/system/usr/lib/outpost/lib.sh'
        env = dict(os.environ, PATH=str(bin_dir), HOME=str(home), USER='desktop',
                   CALLS=str(calls), TEST_HOME=str(home), TEST_UID=str(os.getuid()),
                   XDG_CONFIG_HOME=str(home / '.config'), PROVIDER=str(provider))
        env.pop('SUDO_USER', None)
        for command in ('env', 'jq', 'mkdir', 'flock', 'grep', 'cat', 'id', 'cp', 'mktemp', 'dirname',
                        'kreadconfig6', 'kwriteconfig6'):
            real = shutil.which(command)
            if real:
                (bin_dir / command).symlink_to(real)

        def stub(name, body):
            path = bin_dir / name
            path.write_text('#!/bin/bash\nset -eu\n' + body + '\n')
            path.chmod(0o755)

        def install(name):
            source = (ROOT / 'files/system/usr/bin' / name).read_text()
            source = source.replace('/usr/lib/outpost/lib.sh', str(lib))
            source = source.replace('/var/home/linuxbrew/.linuxbrew/bin/brew', str(tmp / 'absent-brew'))
            source = source.replace('/usr/lib64/pkcs11/opensc-pkcs11.so', str(provider))
            path = bin_dir / name
            path.write_text(source)
            path.chmod(0o755)

        def run(name, code=0, **overrides):
            result = subprocess.run([str(bin_dir / name)], check=False, env=env | overrides,
                                    text=True, capture_output=True, timeout=10)
            assert result.returncode == code, (name, result.returncode, result.stdout, result.stderr)
            assert '\x1b[' not in result.stdout, result.stdout
            return result.stdout + result.stderr

        stub('bash', '''if [[ "${1:-}" == -lc ]]; then
    [[ -n "${BREW_FAKE:-}" ]] && printf '%s\\n' "$BREW_FAKE"
    exit 0
fi
exec /bin/bash "$@"''')
        stub('getent', 'printf "desktop:x:%s:1000::%s:/bin/bash\\n" "$TEST_UID" "$TEST_HOME"')
        stub('rpm-ostree', '''if [[ "$1" == status ]]; then
    [[ "${STATUS_FAIL:-0}" == 0 ]] || exit 1
    printf '%s\\n' "$DEPLOYMENTS"
else
    printf 'os\\n' >> "$CALLS"
    printf 'Downloading OS objects\\n'
    exit "${OS_RC:-0}"
fi''')
        stub('flatpak', '''printf 'flatpak %s HOME=%s USER=%s\\n' "$*" "$HOME" "$USER" >> "$CALLS"
printf 'Flatpak native progress\\n'
exit "${FLATPAK_RC:-0}"''')
        stub('brew', 'printf "brew\\n" >> "$CALLS"; exit "${BREW_RC:-0}"')
        stub('sudo', '''printf 'sudo %s\\n' "$*" >> "$CALLS"
[[ "$1" == -H && "$2" == -u && "$3" == desktop ]]
shift 3
exec "$@"''')
        env['DEPLOYMENTS'] = json.dumps({'deployments': [{'booted': True, 'version': '43'}]})
        for name in ('update', 'cac-nss-setup', 'cac-pdf-setup', 'reader-list', 'cac-help'):
            install(name)

        output = run('update', BREW_FAKE=str(bin_dir / 'brew'))
        assert 'Downloading OS objects' in output and 'Flatpak native progress' in output
        assert 'No pending deployment' in output and 'Homebrew: success' in output
        output = run('update', 1, OS_RC='1', BREW_RC='2', BREW_FAKE=str(bin_dir / 'brew'))
        assert 'OS: failed' in output and 'User Flatpaks: success' in output and 'Homebrew: failed' in output
        pending = json.dumps({'deployments': [{'booted': False, 'version': 'new'}, {'booted': True, 'version': 'old'}]})
        assert 'Reboot required' in run('update', DEPLOYMENTS=pending)
        assert 'Unable to determine final' in run('update', 1, STATUS_FAIL='1')
        calls.write_text('')
        run('update', 130, OS_RC='130')
        assert calls.read_text() == 'os\n', calls.read_text()
        # Emulate sudo by making the invoking uid differ from the desktop uid.
        (bin_dir / 'id').unlink()
        stub('id', 'if [[ "$1" == -u ]]; then printf "0\\n"; else printf "root\\n"; fi')
        calls.write_text('')
        run('update', SUDO_USER='desktop', HOME=str(tmp / 'wrong-home'))
        assert f'HOME={home} USER=desktop' in calls.read_text(), calls.read_text()
        (bin_dir / 'flatpak').unlink()
        output = run('update')
        assert 'System Flatpaks: skipped' in output and 'Homebrew: skipped' in output

        stub('certutil', '''printf 'initialize\\n' >> "$CALLS"
: > "$HOME/.pki/nssdb/cert9.db"''')
        stub('modutil', '''if [[ "$1" == -list ]]; then
    [[ ! -f "$HOME/.pki/nssdb/provider" ]] || cat "$HOME/.pki/nssdb/provider"
else
    printf 'register\\n' >> "$CALLS"
    printf '%s\\n' "$PROVIDER" > "$HOME/.pki/nssdb/provider"
fi''')
        calls.write_text('')
        run('cac-nss-setup')
        run('cac-nss-setup')
        assert calls.read_text() == 'initialize\nregister\n', calls.read_text()
        (home / '.pki/nssdb/provider').unlink()
        run('cac-nss-setup')
        assert calls.read_text().count('register') == 2
        (home / '.pki/nssdb/provider').write_text('/usr/lib64/p11-kit-proxy.so\n')
        run('cac-nss-setup')
        assert calls.read_text().count('register') == 2

        if shutil.which('kreadconfig6') and shutil.which('kwriteconfig6'):
            stub('okular', 'exit 0')
            stub('pgrep', 'exit 1')
            run('cac-pdf-setup')
            config = home / '.config/okular-generator-popplerrc'
            assert 'UseDefaultCertDB=false' in config.read_text()
            assert f'DBCertificatePath={home}/.pki/nssdb' in config.read_text()
            config.write_text('[Signatures]\nUseDefaultCertDB=false\nDBCertificatePath=/custom/store\n')
            before = config.read_text()
            run('cac-pdf-setup', 1)
            assert config.read_text() == before
        else:
            print('SKIP: Okular configuration round-trip (KConfig tools not installed)')
        stub('opensc-tool', 'printf "Nr. Card Features Name\\n0 Yes Reader A\\n"')
        assert 'detected' in run('reader-list')
        stub('opensc-tool', 'printf "reader failure\\n" >&2; exit 1')
        assert 'reader failure' in run('reader-list', 1)
        assert 'cac-pdf-setup' in run('cac-help')
        print('PASS: update progress, failures, optional tools, sudo context, deployment status, cancellation, NSS repair, PDF configuration, and reader diagnostics')


if __name__ == '__main__':
    main()
