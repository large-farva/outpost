#!/usr/bin/env python3
"""Exercise CAC diagnosis, report privacy, and recovery with disposable stubs."""
import json
import os
from pathlib import Path
import pty
import select
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]


def main():
    with tempfile.TemporaryDirectory(prefix='outpost-cac-') as directory:
        tmp = Path(directory)
        bin_dir = tmp / 'bin'
        bin_dir.mkdir()
        home = tmp / 'home'
        (home / '.pki/nssdb').mkdir(parents=True)
        (home / '.pki/nssdb/cert9.db').touch()
        provider = tmp / 'opensc-pkcs11.so'
        provider.touch()
        proxy = tmp / 'p11-kit-proxy.so'
        proxy.touch()
        anchor = tmp / 'trust.pem'
        anchor.write_text('test trust')
        policy = tmp / 'policies.json'
        policy.write_text(json.dumps({'policies': {'SecurityDevices': {'Add': {'CAC': str(proxy)}}}}))
        calls = tmp / 'calls'
        env = dict(os.environ, HOME=str(home), PATH=str(bin_dir), CALLS=str(calls),
                   XDG_STATE_HOME=str(home / 'state'), TERM='dumb')
        for command in ('bash', 'env', 'grep', 'jq', 'mkdir', 'mktemp', 'cat', 'date'):
            (bin_dir / command).symlink_to(shutil.which(command))

        def stub(name, body):
            path = bin_dir / name
            path.write_text('#!/bin/bash\nset -eu\n' + body + '\n')
            path.chmod(0o755)

        def install(name):
            text = (ROOT / 'files/system/usr/bin' / name).read_text()
            for old, new in (
                ('/usr/lib/outpost/lib.sh', str(ROOT / 'files/system/usr/lib/outpost/lib.sh')),
                ('/usr/lib64/pkcs11/opensc-pkcs11.so', str(provider)),
                ('/usr/lib64/p11-kit-proxy.so', str(proxy)),
                ('/etc/pki/ca-trust/source/anchors/dod-trust-bundle.pem', str(anchor)),
                ('/usr/lib64/firefox/distribution/policies.json', str(policy)),
            ):
                text = text.replace(old, new)
            # Exercise user-only commands even when CI itself runs as root.
            text = text.replace('[[ $EUID != 0 ]]', '[[ 1000 != 0 ]]')
            path = bin_dir / name
            path.write_text(text)
            path.chmod(0o755)

        def run(name, *args, code=0, **overrides):
            result = subprocess.run([str(bin_dir / name), *args], env=env | overrides,
                                    capture_output=True, text=True, timeout=10)
            assert result.returncode == code, (name, result.returncode, result.stdout, result.stderr)
            assert '\x1b[' not in result.stdout
            return result.stdout + result.stderr

        stub('timeout', '''[[ "$1" == --kill-after=2s && "$2" == 12s ]]
shift 2
if [[ "${TIMEOUT:-}" == "$1" ]]; then exit 124; fi
exec "$@"''')
        stub('systemctl', '''printf 'systemctl %s\n' "$*" >> "$CALLS"
case "$1" in
    is-active|is-enabled) exit "${SERVICE_RC:-0}" ;;
    is-failed) exit 1 ;;
    restart) exit "${RESTART_RC:-0}" ;;
    *) exit 99 ;;
esac''')
        stub('timedatectl', 'printf "yes\n"')
        stub('p11-kit', 'printf "module: opensc-pkcs11.so\n"')
        stub('trust', 'printf "label: DoD ROOT CA\n"')
        stub('firefox', 'exit 99')
        stub('pgrep', 'exit "${BROWSER_RC:-1}"')
        stub('modutil', 'printf "p11-kit-proxy.so\n"')
        stub('rpm', 'printf "firefox-123.fc43\n"')
        stub('rpm-ostree', 'printf \'{"deployments":[{"booted":true,"checksum":"%064d","origin":"PRIVATE_REGISTRY_SECRET"}]}\n\' 0')
        stub('opensc-tool', '''[[ "${READER_RC:-0}" == 0 ]] || { printf 'PERSONAL_CERT_NAME diagnostic failure\n' >&2; exit 1; }
case "${CARD:-present}" in
    present) printf 'Nr. Card Features Name\n0 Yes Reader SERIAL_SECRET\n' ;;
    absent) printf 'Nr. Card Features Name\n0 No Reader SERIAL_SECRET\n' ;;
    none) printf 'No readers found\n' ;;
esac''')
        stub('pkcs11-tool', '''[[ "$*" != *--login* && "$*" != *--pin* ]]
printf 'token label : PERSONAL_CERT_NAME\ntoken serial : SERIAL_SECRET\n' ''')
        stub('sudo', 'printf "sudo %s\n" "$*" >> "$CALLS"; exec "$@"')
        stub('cac-nss-setup', 'printf "nss setup\n" >> "$CALLS"; exit "${NSS_RC:-0}"')
        stub('gum', '''[[ "$1" == confirm ]]
if [[ "$*" == *'Run connection checks now?'* ]]; then exit "${SECOND_CONFIRM_RC:-0}"; fi
exit "${CONFIRM_RC:-0}"''')
        for name in ('cac-check', 'cac-report', 'cac-recover', 'outpost-rollback'):
            install(name)
        output = run('cac-check')
        assert '1 inserted card' in output and '1 PKCS#11 token' in output
        assert 'PERSONAL_CERT_NAME' not in output and 'SERIAL_SECRET' not in output
        assert 'PRIVATE_REGISTRY_SECRET' not in output
        assert 'no inserted card' in run('cac-check', CARD='absent')
        assert 'No reader detected' in run('cac-check', CARD='none')
        assert 'exit 124' in run('cac-check', code=1, TIMEOUT='opensc-tool')
        assert 'PERSONAL_CERT_NAME' in run('cac-check', code=1, READER_RC='1')
        assert 'PERSONAL_CERT_NAME' not in run('cac-check', '--report', code=1, READER_RC='1')
        assert 'Reader socket is inactive' in run('cac-check', code=1, SERVICE_RC='1')
        (bin_dir / 'p11-kit').unlink()
        assert 'Missing command: p11-kit' in run('cac-check', code=1)
        stub('p11-kit', 'printf "module: opensc-pkcs11.so\n"')
        output = run('cac-report', code=1, READER_RC='1')
        report = next((home / 'state/outpost').glob('cac-report-*.txt'))
        assert report.stat().st_mode & 0o777 == 0o600
        assert 'PERSONAL_CERT_NAME' not in report.read_text()
        assert 'Diagnostic exit status: 1' in report.read_text()
        run('cac-report')
        assert len(list(report.parent.glob('*.txt'))) == 2
        assert 'requires a terminal' in run('cac-recover', code=1)

        def recovery(code, **overrides):
            calls.write_text('')
            master, slave = pty.openpty()
            proc = subprocess.Popen([str(bin_dir / 'cac-recover')], env=env | overrides,
                                    stdin=slave, stdout=slave, stderr=slave)
            os.close(slave)
            output = b''
            deadline = time.monotonic() + 10
            try:
                while time.monotonic() < deadline:
                    if select.select([master], [], [], 0.1)[0]:
                        try:
                            chunk = os.read(master, 65536)
                        except OSError:
                            break
                        if not chunk:
                            break
                        output += chunk
                    if proc.poll() is not None:
                        break
                assert proc.wait(timeout=2) == code, output.decode()
            finally:
                if proc.poll() is None:
                    proc.kill()
                    proc.wait()
                os.close(master)
            return calls.read_text()

        assert not recovery(130, CONFIRM_RC='1')
        assert not recovery(1, BROWSER_RC='0')
        assert not recovery(1, BROWSER_RC='2')
        assert 'nss setup' not in recovery(1, RESTART_RC='1')
        assert 'systemctl is-active' not in recovery(1, NSS_RC='1')
        assert 'systemctl is-active' not in recovery(130, SECOND_CONFIRM_RC='1')
        log = recovery(0)
        assert 'sudo systemctl restart pcscd.socket pcscd.service' in log
        assert log.count('nss setup') == 1
        calls.write_text('')
        assert 'sudo rpm-ostree rollback' in run('outpost-rollback')
        assert not calls.read_text()
        policy_data = json.loads((ROOT / 'files/system/usr/lib64/firefox/distribution/policies.json').read_text())
        # NSS compares library names literally; Fedora registers this soname.
        assert policy_data['policies']['SecurityDevices']['Add']['p11-kit-proxy'] == 'p11-kit-proxy.so'
        print('PASS: reader/card checks, timeouts, failures, missing tools, private reports, recovery cancellation and service errors, rollback help')


if __name__ == '__main__':
    main()
