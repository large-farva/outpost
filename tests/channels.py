#!/usr/bin/env python3
"""Check publishing boundaries and channel metadata without modifying the host."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import shutil

ROOT = Path(__file__).resolve().parents[1]


def main():
    selector = ROOT / '.github/scripts/select-channel.sh'
    cases = (
        ('push', 'refs/heads/main', '', 'recipe.yml', True),
        ('schedule', 'refs/heads/main', '', 'recipe.yml', True),
        ('workflow_dispatch', 'refs/heads/main', '', 'recipe.yml', True),
        ('push', 'refs/heads/testing', '', 'testing.yml', True),
        ('workflow_dispatch', 'refs/heads/testing', '', 'testing.yml', True),
        ('schedule', 'refs/heads/testing', '', 'testing.yml', False),
        ('push', 'refs/heads/test/cac-desktop', '', 'recipe.yml', False),
        ('workflow_dispatch', 'refs/heads/test/cac-desktop', '', 'recipe.yml', False),
        ('push', 'refs/tags/testing', '', 'recipe.yml', False),
        ('pull_request', 'refs/pull/1/merge', 'testing', 'testing.yml', False),
        ('pull_request', 'refs/pull/1/merge', 'main', 'recipe.yml', False),
        ('pull_request', 'refs/heads/main', '', 'recipe.yml', False),
        ('pull_request_target', 'refs/heads/testing', '', 'testing.yml', False),
    )
    for event, ref, base, recipe, publish in cases:
        result = subprocess.run(['bash', str(selector)], check=True, capture_output=True, text=True,
                                env=os.environ | {'EVENT_NAME': event, 'REF': ref, 'BASE_REF': base})
        values = dict(line.split('=', 1) for line in result.stdout.splitlines())
        assert values == {'recipe': recipe, 'publish': str(publish).lower()}, (event, ref, values)

    with tempfile.TemporaryDirectory(prefix='outpost-channels-') as directory:
        tmp = Path(directory)
        etc = tmp / 'etc'
        (etc / 'containers/registries.d').mkdir(parents=True)
        (etc / 'pki/containers').mkdir(parents=True)
        metadata = tmp / 'usr/share/outpost/image-info.json'
        metadata.parent.mkdir(parents=True)
        payload = tmp / 'files/system'
        payload.mkdir(parents=True)
        policy = etc / 'containers/policy.json'
        original_policy = {'default': [{'type': 'reject'}], 'transports': {'docker': {
            'registry.example.org': [{'type': 'reject'}]}}}
        script = tmp / 'image-channel.sh'
        script.write_text((ROOT / 'files/scripts/image-channel.sh').read_text()
                          .replace('/etc/', str(etc) + '/').replace('/usr/', str(tmp / 'usr') + '/'))
        for name in ('outpost', 'outpost-testing'):
            (etc / f'pki/containers/{name}.pub').write_text('test public key')
            metadata.write_text((ROOT / 'files/system/usr/share/outpost/image-info.json').read_text())
            policy.write_text(json.dumps(original_policy))
            env = os.environ | {'IMAGE_NAME': name, 'CONFIG_DIRECTORY': str(payload.parent)}
            for _ in range(2):
                subprocess.run(['bash', str(script)], check=True, env=env)
            info = json.loads(metadata.read_text())
            assert info['image-ref'] == f'ghcr.io/large-farva/{name}'
            assert info['image-channel'] == ('testing' if name.endswith('-testing') else 'production')
            trust = json.loads(policy.read_text())
            assert trust['transports']['docker']['registry.example.org'] == [{'type': 'reject'}]
            assert trust['default'] == [{'type': 'reject'}]
            for image in ('outpost', 'outpost-testing'):
                rule, = trust['transports']['docker'][f'ghcr.io/large-farva/{image}']
                assert rule == {'type': 'sigstoreSigned', 'keyPath': str(etc / 'pki/containers/outpost.pub'),
                                'signedIdentity': {'type': 'matchRepository'}}
                assert f'ghcr.io/large-farva/{image}:' in (etc / f'containers/registries.d/large-farva-{image}.yaml').read_text()
        before = policy.read_bytes()
        for env in ({'IMAGE_NAME': 'unrelated', 'CONFIG_DIRECTORY': str(payload.parent)},
                    {'IMAGE_NAME': 'outpost', 'CONFIG_DIRECTORY': str(tmp / 'absent')}):
            result = subprocess.run(['bash', str(script)], env=os.environ | env, capture_output=True)
            assert result.returncode != 0
            assert policy.read_bytes() == before
        (etc / 'pki/containers/outpost.pub').unlink()
        result = subprocess.run(['bash', str(script)], env=os.environ | {
            'IMAGE_NAME': 'outpost', 'CONFIG_DIRECTORY': str(payload.parent)}, capture_output=True)
        assert result.returncode != 0 and policy.read_bytes() == before
    with tempfile.TemporaryDirectory(prefix='outpost-tag-') as directory:
        tmp = Path(directory)
        bin_dir = tmp / 'bin'
        bin_dir.mkdir()
        for command in ('jq', 'cat'):
            (bin_dir / command).symlink_to(shutil.which(command))
        calls = tmp / 'calls'
        digest = 'sha256:' + 'a' * 64
        def stub(name, body):
            path = bin_dir / name
            path.write_text('#!/bin/bash\nset -eu\n' + body + '\n')
            path.chmod(0o755)
        stub('docker', '''if [[ "$1" == login ]]; then cat >/dev/null; exit 0; fi
printf 'docker %s\\n' "$*" >> "$CALLS"
if [[ "$1" == run ]]; then exit "${RUN_RC:-0}"; fi
if [[ "$3" == inspect ]]; then printf '{"digest":"%s"}\\n' "$DIGEST"; fi''')
        stub('cosign', 'printf "verify %s\\n" "$*" >> "$CALLS"; exit "${VERIFY_RC:-0}"')
        env = os.environ | {'PATH': str(bin_dir), 'CALLS': str(calls), 'DIGEST': digest,
            'GITHUB_REPOSITORY': 'large-farva/outpost', 'GITHUB_REF': 'refs/heads/testing',
            'GITHUB_EVENT_NAME': 'push', 'GITHUB_SHA': 'a' * 40, 'GITHUB_ACTOR': 'tester',
            'GH_TOKEN': 'TEST_SECRET', 'GITHUB_STEP_SUMMARY': str(tmp / 'summary')}
        script = ROOT / '.github/scripts/publish-testing-tag.sh'
        subprocess.run(['/bin/bash', str(script)], env=env, check=True)
        log = calls.read_text()
        assert 'outpost-testing:aaaaaaa-43' in log
        assert 'create --prefer-index=false --tag ghcr.io/large-farva/outpost-testing:latest' in log
        assert log.index('verify ') < log.index('docker run ') < log.index('create ')
        assert 'TEST_SECRET' not in log
        for overrides in ({'GITHUB_REF': 'refs/heads/main'}, {'GITHUB_EVENT_NAME': 'pull_request'},
                          {'GITHUB_REPOSITORY': 'someone/fork'}, {'VERIFY_RC': '1'}, {'RUN_RC': '1'}):
            calls.write_text('')
            result = subprocess.run(['/bin/bash', str(script)], env=env | overrides)
            assert result.returncode != 0
            assert 'create ' not in calls.read_text()
    print('PASS: channel selection, signed tag publication, signature policy, metadata, and build guards')


if __name__ == '__main__':
    main()
