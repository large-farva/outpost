# Contributing to Outpost

Outpost is a Fedora Kinoite image built with BlueBuild and pinned to Fedora 43.

## Repository layout

- `recipes/recipe.yml` defines both production and testing images, including all
  packages, services, and build steps. BlueBuild always uses this recipe.
- `files/system/` mirrors the installed filesystem. Commands live in `usr/bin/`,
  shared Bash helpers in `usr/lib/outpost/lib.sh`, and desktop assets in `usr/share/`.
- `files/scripts/` contains image-build scripts for DoD trust and branding cleanup.
- `certificates/` holds the official DoD archive and checksum. The image payload
  has a second copy under `files/system/usr/share/outpost/certs/`.
- `assets/` contains repository branding. `.github/workflows/build.yml` runs checks
  and builds the image.

## Checks and builds

Run these commands from the repository root:

```bash
shellcheck -x -P files/system/usr/lib/outpost files/system/usr/bin/* files/scripts/*.sh
bash -n files/system/usr/bin/cac-check
(cd certificates && sha256sum -c unclass-certificates_pkcs7_DoD.zip.sha256)
```

Run `python3 tests/helpers.py`, `python3 tests/customization.py`,
`python3 tests/cac.py`, `python3 tests/channels.py`, and `python3 tests/tui.py`. They use temporary files
and command stubs; no host services or CACs are touched. See [contributor guide](CONTRIBUTING.md) for image and
hardware checks.

GitHub Actions builds pull requests, eligible pushes, weekly schedules, and manual
runs after lint and tests pass. `main` publishes Outpost. Pushes and manual runs
on `testing` publish Outpost Testing. Pull requests and other branches do not publish images.
CI's `.github/scripts/select-channel.sh` changes only the top-level `name` in the
working-tree `recipes/recipe.yml` to `outpost` or `outpost-testing`. Local builds
use the committed `outpost` name regardless of branch; see the contributor guide
for local testing-channel preparation. Image metadata, signing, and tag publishing
remain unchanged.

Test installed commands in an Outpost VM. Build scripts modify system paths and
must not be used as local development launchers.

## Code style

Follow `.editorconfig`: four spaces, UTF-8, LF endings, a final newline, and no
trailing whitespace. Preserve the surrounding YAML structure. Use hyphenated
command names such as `cac-check` and snake_case Bash functions. Reuse `lib.sh`
and retain ShellCheck directives. ShellCheck is the configured linter; there is
no configured formatter.

Comments should explain a constraint, workaround, or non-obvious decision.
Avoid comments that repeat the code or refer to a development conversation.
Discuss feature removals and changes to shipped customizations before making them.

## Validation and pull requests

Run lint and syntax checks for shell changes, then test the affected behavior in
a built image. CAC changes need `cac-check`, reader detection, and Firefox RPM
authentication tests with hardware. The offline smoke test explicitly verifies
RPM Okular. In a booted VM, run `rpm -q okular` and
`flatpak list --app --columns=application,installation`, confirm no Okular Flatpak
is installed, and verify PDFs open in RPM Okular. Okular changes also need a
signed PDF test. Record the tested image digest and any hardware limitations in
the pull request.

Use a conventional commit prefix: `feat:`, `fix:`, `refactor:`, `chore:`, or `docs:`.
Keep commits focused. Pull requests should describe the behavior change, link
relevant issues, and report validation. Include screenshots for desktop changes.

## Keys and certificates

Never commit signing private keys. CI uses `SIGNING_SECRET`; `cosign.pub` is public.
When updating DoD certificates, keep the official archive name, update both bundle
copies and their checksums, and verify integrity.
