#!/usr/bin/env python3
"""Check publishing boundaries and channel metadata without modifying the host."""
import json
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    selector = ROOT / '.github/scripts/select-channel.sh'
    workflow = (ROOT / '.github/workflows/build.yml').read_text()
    assert re.search(r'^ +recipe: recipe\.yml$', workflow, re.MULTILINE)
    assert re.search(r'^ +skip_checkout: true$', workflow, re.MULTILINE)
    cases = (
        ('push', 'refs/heads/main', '', 'outpost', True),
        ('schedule', 'refs/heads/main', '', 'outpost', True),
        ('workflow_dispatch', 'refs/heads/main', '', 'outpost', True),
        ('push', 'refs/heads/testing', '', 'outpost-testing', True),
        ('workflow_dispatch', 'refs/heads/testing', '', 'outpost-testing', True),
        ('schedule', 'refs/heads/testing', '', 'outpost-testing', False),
        ('push', 'refs/heads/personal', '', 'outpost-personal', True),
        ('workflow_dispatch', 'refs/heads/personal', '', 'outpost-personal', True),
        ('schedule', 'refs/heads/personal', '', 'outpost-personal', False),
        ('pull_request', 'refs/pull/1/merge', 'personal', 'outpost-personal', False),
        ('pull_request', 'refs/heads/personal', '', 'outpost-personal', False),
        ('pull_request_target', 'refs/heads/personal', '', 'outpost-personal', False),
        ('push', 'refs/tags/personal', '', 'outpost', False),
        ('workflow_dispatch', 'refs/tags/personal', '', 'outpost', False),
        ('push', 'refs/heads/personal-extra', '', 'outpost', False),
        ('workflow_dispatch', 'refs/heads/personal/feature', '', 'outpost', False),
        ('schedule', 'refs/heads/personal-extra', '', 'outpost', False),
        ('pull_request', 'refs/pull/1/merge', 'personal-extra', 'outpost', False),
        ('push', '', '', 'outpost', False),
        ('push', 'refs/heads/test/cac-desktop', '', 'outpost', False),
        ('workflow_dispatch', 'refs/heads/test/cac-desktop', '', 'outpost', False),
        ('push', 'refs/tags/testing', '', 'outpost', False),
        ('pull_request', 'refs/pull/1/merge', 'testing', 'outpost-testing', False),
        ('pull_request', 'refs/pull/1/merge', 'main', 'outpost', False),
        ('pull_request', 'refs/heads/main', '', 'outpost', False),
        ('pull_request_target', 'refs/heads/testing', '', 'outpost-testing', False),
    )
    # Evaluate each independent workflow guard, including a forged selector output.
    guards = dict(re.findall(r'^\s+(push|cosign_private_key|registry_token|if): \$\{\{ (.+) \}\}$',
                             workflow, re.MULTILINE))
    assert set(guards) == {'push', 'cosign_private_key', 'registry_token', 'if'}
    assert re.search(r'^permissions:\n +contents: read$', workflow, re.MULTILINE)
    assert re.search(r'^( +)permissions:\n\1( +)contents: read\n\1\2packages: write\n\1\2id-token: write$', workflow, re.MULTILINE)
    assert 'pull_request_target:' not in workflow
    for event, ref, base, image, publish in cases:
        for repository in ('large-farva/outpost', 'someone/fork'):
            for selected in ('true', 'false'):
                context = {'github.event_name': event, 'github.ref': ref,
                           'github.repository': repository, 'steps.channel.outputs.publish': selected,
                           'secrets.SIGNING_SECRET': 'TEST_KEY', 'github.token': 'TEST_TOKEN'}
                allowed = publish and repository == 'large-farva/outpost' and selected == 'true'
                expected = {'push': bool(allowed), 'cosign_private_key': 'TEST_KEY' if allowed else '',
                            'registry_token': 'TEST_TOKEN' if allowed else '',
                            'if': bool(allowed and ref in ('refs/heads/testing', 'refs/heads/personal'))}
                for field, guard in guards.items():
                    expression = re.sub(r'\b(?:github|steps|secrets)\.[a-zA-Z_.]+',
                                        lambda match: repr(context[match[0]]), guard)
                    result = eval(expression.replace('&&', ' and ').replace('||', ' or '),
                                  {'__builtins__': {}})
                    assert result == expected[field], (field, event, ref, repository, selected, result)
    original = (ROOT / 'recipes/recipe.yml').read_text()
    assert original.count('\nname: outpost\n') == 1
    with tempfile.TemporaryDirectory(prefix='outpost-recipe-') as directory:
        tmp = Path(directory)
        recipe = tmp / 'recipes/recipe.yml'
        recipe.parent.mkdir()
        recipe.write_text(original)
        for event, ref, base, image, publish in cases:
            result = subprocess.run(['bash', str(selector)], cwd=tmp, check=True,
                                    capture_output=True, text=True,
                                    env=os.environ | {'EVENT_NAME': event, 'REF': ref, 'BASE_REF': base})
            values = dict(line.split('=', 1) for line in result.stdout.splitlines())
            assert values == {'publish': str(publish).lower()}, (event, ref, values)
            assert recipe.read_text() == original.replace('\nname: outpost\n', f'\nname: {image}\n')

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
        for name, channel in (('outpost', 'production'), ('outpost-testing', 'testing'),
                              ('outpost-personal', 'personal')):
            (etc / 'pki/containers/outpost.pub').write_text('stale public key')
            (etc / f'pki/containers/{name}.pub').write_text('test public key')
            metadata.write_text((ROOT / 'files/system/usr/share/outpost/image-info.json').read_text())
            policy.write_text(json.dumps(original_policy))
            env = os.environ | {'IMAGE_NAME': name, 'CONFIG_DIRECTORY': str(payload.parent)}
            for _ in range(2):
                subprocess.run(['bash', str(script)], check=True, env=env)
            info = json.loads(metadata.read_text())
            assert info['image-name'] == name
            assert info['image-ref'] == f'ghcr.io/large-farva/{name}'
            assert info['image-channel'] == channel
            assert (etc / 'pki/containers/outpost.pub').read_text() == 'test public key'
            trust = json.loads(policy.read_text())
            assert trust['transports']['docker']['registry.example.org'] == [{'type': 'reject'}]
            assert trust['default'] == [{'type': 'reject'}]
            for image in ('outpost', 'outpost-testing', 'outpost-personal'):
                rule, = trust['transports']['docker'][f'ghcr.io/large-farva/{image}']
                assert rule == {'type': 'sigstoreSigned', 'keyPath': str(etc / 'pki/containers/outpost.pub'),
                                'signedIdentity': {'type': 'matchRepository'}}
                assert f'ghcr.io/large-farva/{image}:' in (etc / f'containers/registries.d/large-farva-{image}.yaml').read_text()
        before = policy.read_bytes()
        for env in ({'IMAGE_NAME': 'unrelated', 'CONFIG_DIRECTORY': str(payload.parent)},
                    {'IMAGE_NAME': 'outpost', 'CONFIG_DIRECTORY': str(tmp / 'absent')}):
            result = subprocess.run(['bash', str(script)], check=False, env=os.environ | env, capture_output=True)
            assert result.returncode != 0
            assert policy.read_bytes() == before
        for name in ('outpost-personal', 'outpost-testing', 'outpost'):
            (etc / f'pki/containers/{name}.pub').unlink()
            previous_metadata = metadata.read_bytes()
            result = subprocess.run(['bash', str(script)], check=False, env=os.environ | {
                'IMAGE_NAME': name, 'CONFIG_DIRECTORY': str(payload.parent)}, capture_output=True)
            assert result.returncode != 0 and policy.read_bytes() == before
            assert metadata.read_bytes() == previous_metadata
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
        stub('docker', '''printf 'docker %s\\n' "$*" >> "$CALLS"
if [[ "$1" == login ]]; then cat >/dev/null; exit "${LOGIN_RC:-0}"; fi
if [[ "$1" == run ]]; then exit "${RUN_RC:-0}"; fi
if [[ "$3" == create ]]; then exit "${CREATE_RC:-0}"; fi
if [[ "$3" == inspect ]]; then
    if [[ "$4" == *:latest ]]; then
        printf '{"digest":"%s"}\\n' "${LATEST_DIGEST:-$DIGEST}"
        exit "${LATEST_INSPECT_RC:-0}"
    fi
    printf '{"digest":"%s"}\\n' "$DIGEST"
    exit "${INSPECT_RC:-0}"
fi''')
        stub('cosign', '''printf 'verify %s\\n' "$*" >> "$CALLS"
if [[ "$4" == *:latest ]]; then exit "${LATEST_VERIFY_RC:-0}"; fi
exit "${VERIFY_RC:-0}"''')
        env = os.environ | {'PATH': str(bin_dir), 'CALLS': str(calls), 'DIGEST': digest,
            'GITHUB_REPOSITORY': 'large-farva/outpost', 'GITHUB_REF': 'refs/heads/testing',
            'GITHUB_EVENT_NAME': 'push', 'GITHUB_SHA': 'a' * 40, 'GITHUB_ACTOR': 'tester',
            'GH_TOKEN': 'TEST_SECRET', 'GITHUB_STEP_SUMMARY': str(tmp / 'summary')}
        script = ROOT / '.github/scripts/publish-testing-tag.sh'
        summary = tmp / 'summary'
        for channel in ('testing', 'personal'):
            image = f'ghcr.io/large-farva/outpost-{channel}'
            env['GITHUB_REF'] = f'refs/heads/{channel}'
            for event in ('push', 'workflow_dispatch'):
                calls.write_text('')
                summary.write_text('')
                subprocess.run(['/bin/bash', str(script)], env=env | {'GITHUB_EVENT_NAME': event},
                               check=True, cwd=tmp)
                log = calls.read_text()
                lines = log.splitlines()
                assert f'inspect {image}:aaaaaaa-43 ' in lines[1]
                assert lines[2] == f'verify verify --key cosign.pub {image}@{digest}'
                assert 'docker run --rm --network none --user 1000:1000 --tmpfs /tmp:rw,mode=1777' in lines[3]
                assert f'{image}@{digest} bash /tmp/test.sh' in lines[3]
                assert lines[4] == f'docker buildx imagetools create --prefer-index=false --tag {image}:latest {image}@{digest}'
                assert f'inspect {image}:latest ' in lines[5]
                assert lines[6] == f'verify verify --key cosign.pub {image}:latest'
                assert len(lines) == 7
                assert set(re.findall(r'ghcr\.io/large-farva/[^:@\s]+', log)) == {image}
                assert 'TEST_SECRET' not in log
                assert summary.read_text() == f'Channel image: {image}:latest\n\nDigest: {digest}\n'

            for overrides in ({'GITHUB_REF': 'refs/heads/main'},
                              {'GITHUB_REF': 'refs/tags/' + channel},
                              {'GITHUB_REF': 'refs/heads/' + channel + '-extra'},
                              {'GITHUB_REF': 'refs/heads/' + channel + '/feature'},
                              {'GITHUB_REF': ''}, {'GITHUB_SHA': ''}, {'GITHUB_SHA': 'not-a-sha'},
                              {'GITHUB_EVENT_NAME': 'pull_request'},
                              {'GITHUB_EVENT_NAME': 'pull_request_target'},
                              {'GITHUB_EVENT_NAME': 'schedule'},
                              {'GITHUB_EVENT_NAME': ''}, {'GITHUB_REPOSITORY': 'someone/fork'}):
                calls.write_text('')
                summary.write_text('')
                result = subprocess.run(['/bin/bash', str(script)], check=False, env=env | overrides,
                                        cwd=tmp, capture_output=True)
                assert result.returncode != 0, overrides
                assert calls.read_text() == '' and summary.read_text() == '', overrides
            for overrides, created in (({'LOGIN_RC': '1'}, False), ({'INSPECT_RC': '1'}, False),
                                       ({'DIGEST': 'invalid'}, False), ({'VERIFY_RC': '1'}, False),
                                       ({'RUN_RC': '1'}, False), ({'CREATE_RC': '1'}, True),
                                       ({'LATEST_INSPECT_RC': '1'}, True),
                                       ({'LATEST_DIGEST': 'sha256:' + 'b' * 64}, True),
                                       ({'LATEST_VERIFY_RC': '1'}, True)):
                calls.write_text('')
                summary.write_text('')
                result = subprocess.run(['/bin/bash', str(script)], check=False, env=env | overrides,
                                        cwd=tmp, capture_output=True)
                assert result.returncode != 0, overrides
                log = calls.read_text()
                assert ('create ' in log) == created, overrides
                assert summary.read_text() == '', overrides
                assert set(re.findall(r'ghcr\.io/large-farva/[^:@\s]+', log)) <= {image}
                assert 'TEST_SECRET' not in log
                if 'VERIFY_RC' in overrides:
                    assert 'docker run ' not in log
                if 'LATEST_DIGEST' in overrides or 'LATEST_INSPECT_RC' in overrides:
                    assert f'verify verify --key cosign.pub {image}:latest' not in log
    print('PASS: channel selection, signed tag publication, signature policy, metadata, and build guards')


if __name__ == '__main__':
    main()
