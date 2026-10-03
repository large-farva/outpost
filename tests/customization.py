#!/usr/bin/env python3
"""Check branding cleanup in a disposable filesystem and stub Starship startup."""
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    with tempfile.TemporaryDirectory(prefix='outpost-branding-') as directory:
        tmp = Path(directory)
        fixture = tmp / 'image'
        fixture.mkdir()
        script = tmp / 'cleanup.sh'
        # Relocate every absolute removal/asset path, never run against the host.
        source = (ROOT / 'files/scripts/cleanup.sh').read_text()
        script.write_text(source.replace('/usr/', f'{fixture}/usr/').replace('/etc/', f'{fixture}/etc/'))
        env = dict(os.environ)
        env.pop('IMAGE_NAME', None)
        env.pop('CONFIG_DIRECTORY', None)
        result = subprocess.run(['bash', str(script)], check=False, env=env, capture_output=True)
        assert result.returncode == 1 and b'image build' in result.stderr
        payload = tmp / 'files/system'
        payload.mkdir(parents=True)
        env.update(IMAGE_NAME='outpost', CONFIG_DIRECTORY=str(payload.parent))
        result = subprocess.run(['bash', str(script)], check=False, env=env, capture_output=True)
        assert result.returncode == 1 and b'Missing Outpost asset' in result.stderr
        for relative in (
            'usr/share/plasma/look-and-feel/org.outpost.desktop/metadata.json',
            'usr/share/wallpapers/Outpost/contents/images/1920x1080.png',
            'usr/share/sddm/themes/outpost/Main.qml',
            'usr/share/plymouth/themes/spinner/watermark.png',
            'usr/share/plasma/look-and-feel/org.fedoraproject.fedora.desktop/metadata.json',
            'usr/share/wallpapers/Fedora/image.png',
            'usr/share/backgrounds/default.jxl',
        ):
            path = fixture / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('asset')
        wallpapers = fixture / 'usr/share/wallpapers'
        (wallpapers / 'Default').symlink_to('Outpost', target_is_directory=True)
        (wallpapers / 'Broken').symlink_to('missing', target_is_directory=True)
        outside = tmp / 'outside'
        outside.mkdir()
        (outside / 'keep').write_text('keep')
        (fixture / 'usr/share/backgrounds/f-link').symlink_to(outside, target_is_directory=True)
        locale_roots = ('locale', 'doc/HTML', 'man', 'speech-dispatcher/locale')
        kept = [
            'usr/share/locale/locale.alias',
            'usr/share/locale/l10n/resource',
            'usr/share/doc/HTML/common/style.css',
            'usr/share/doc/example/README',
            'usr/share/doc/example/fr/guide.txt',
            'usr/share/licenses/example/LICENSE',
            'usr/share/man/man1/example.1',
            'usr/share/man/man3type/example.3type',
            'usr/share/speech-dispatcher/locale/base/messages',
            'usr/share/adobe/resources/mapping/Japan1',
            'usr/share/adobe/resources/mapping/Korea1',
            'usr/share/rpm/rpmdb.sqlite',
            'usr/share/icons/oxygen/32x32/places/folder.png',
            'usr/share/icons/oxygen/32x32/apps/start-here-kde-fedora.png',
            'usr/share/icons/oxygen/32x32/apps/org.fedoraproject.AnacondaInstaller.svg',
            'usr/share/icons/oxygen/scalable/apps/unrelated.svg',
        ]
        icons_removed = [
            f'usr/share/icons/oxygen/{size}/places/start-here-kde-fedora.png'
            for size in ('16x16', '32x32', 'scalable')
        ] + ['usr/share/icons/oxygen/scalable/apps/org.fedoraproject.AnacondaInstaller.svg']
        removed = icons_removed.copy()
        for root in locale_roots:
            kept.append(f'usr/share/{root}/README')
            for language in ('en', 'en_US', 'en_GB', 'en.UTF-8', 'en_US.UTF-8', 'C', 'C.utf8', 'POSIX'):
                kept.append(f'usr/share/{root}/{language}/resource')
            for language in ('fr', 'de_DE', 'zh_CN'):
                relative = f'usr/share/{root}/{language}'
                path = fixture / relative
                path.mkdir(parents=True)
                (path / 'resource').write_text('remove')
                removed.append(relative)
        for relative in kept + icons_removed:
            path = fixture / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('asset')
        for root in locale_roots:
            for language, target in (('es', outside), ('ja', tmp / 'missing')):
                relative = f'usr/share/{root}/{language}'
                (fixture / relative).symlink_to(target, target_is_directory=True)
                removed.append(relative)
        for image_name in ('outpost', 'outpost-testing'):
            env['IMAGE_NAME'] = image_name
            for _ in range(2):
                subprocess.run(['bash', str(script)], env=env, check=True, capture_output=True)
                for relative in kept:
                    assert (fixture / relative).read_text() == 'asset', relative
                for relative in removed:
                    path = fixture / relative
                    assert not path.exists() and not path.is_symlink(), relative
                assert (outside / 'keep').read_text() == 'keep'
            # Exercise locale.alias as both a regular shared file and a symlink.
            alias = fixture / 'usr/share/locale/locale.alias'
            if image_name == 'outpost':
                alias.rename(outside / 'locale.alias')
                alias.symlink_to(outside / 'locale.alias')
            else:
                assert alias.is_symlink()

        # A symlink at the cleanup root must not expose its target to pruning.
        root_targets = []
        for index, root in enumerate(locale_roots):
            path = fixture / 'usr/share' / root
            target = tmp / f'locale-root-{index}'
            path.rename(target)
            path.symlink_to(target, target_is_directory=True)
            (target / 'fr').mkdir()
            (target / 'fr/resource').write_text('keep')
            root_targets.append((path, target))
        for image_name in ('outpost', 'outpost-testing'):
            env['IMAGE_NAME'] = image_name
            for _ in range(2):
                subprocess.run(['bash', str(script)], env=env, check=True, capture_output=True)
                for path, target in root_targets:
                    assert path.is_symlink(), path
                    assert (target / 'fr/resource').read_text() == 'keep', target
                for relative in kept:
                    assert (fixture / relative).read_text() == 'asset', relative
        assert (wallpapers / 'Default').is_dir()
        assert not (wallpapers / 'Broken').is_symlink()
        assert not (wallpapers / 'Fedora').exists()
        assert (fixture / 'usr/share/backgrounds/default.jxl').read_text() == 'asset'
        assert (outside / 'keep').read_text() == 'keep'

        bin_dir = tmp / 'bin'
        bin_dir.mkdir()
        calls = tmp / 'calls'
        starship = bin_dir / 'starship'
        starship.write_text('#!/bin/bash\nprintf "init\\n" >> "$CALLS"\nprintf \'PS1="outpost> "\\n\'\n')
        starship.chmod(0o755)
        hook = ROOT / 'files/system/etc/profile.d/outpost-starship.sh'
        env.update(PATH=f'{bin_dir}:/usr/bin:/bin', TERM='xterm-256color', CALLS=str(calls), HOOK=str(hook))
        env.pop('__OUTPOST_STARSHIP_INITIALIZED', None)
        command = 'source "$HOOK"; source "$HOOK"; [[ "$PS1" == "outpost> " ]]'
        subprocess.run(['bash', '--noprofile', '--norc', '-ic', command], env=env,
                       check=True, capture_output=True)
        assert calls.read_text() == 'init\n'
        subprocess.run(['bash', '--noprofile', '--norc', '-c', 'source "$HOOK"'], env=env, check=True)
        subprocess.run(['bash', '--noprofile', '--norc', '-ic', 'source "$HOOK"'],
                       env=env | {'TERM': 'dumb'}, check=True, capture_output=True)
        assert calls.read_text() == 'init\n'
        # Exercise Bash defaults without sourcing the host's profile scripts.
        profile_dir = tmp / 'profile.d'
        profile_dir.mkdir()
        bashrc = tmp / 'bashrc'
        bashrc.write_text((ROOT / 'files/system/etc/bashrc').read_text().replace('/etc/profile.d', str(profile_dir)))
        command = 'set -e; unset BASHRCSOURCED; PROMPT_COMMAND=(existing_hook); source "$TEST_BASHRC"; [[ ${PROMPT_COMMAND[0]} == existing_hook ]]; shopt -q histappend checkwinsize; printf "%s" "$PS1"'
        result = subprocess.run(['bash', '--noprofile', '--norc', '-ic', command],
                                env=env | {'TEST_BASHRC': str(bashrc)}, text=True,
                                check=True, capture_output=True)
        assert result.stdout == r'[\u@\h:\l \W]\$ ', result.stdout
        print('PASS: cleanup guard, missing assets, locale and icon pruning, preserved resources, '
              'idempotence, symlink safety, Bash defaults, and Starship startup')


if __name__ == '__main__':
    main()
