# Contributing to Outpost

Outpost is a Fedora Kinoite image built with BlueBuild and pinned to Fedora 43.

## Repository layout

- `recipes/recipe.yml` defines packages, Flatpaks, services, branding, and build steps.
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

Run `python3 tests/helpers.py`, `python3 tests/customization.py`, and
`python3 tests/cac.py`. They use temporary files and command stubs; no host
services or CACs are touched. See [contributor guide](CONTRIBUTING.md) for image and
hardware checks.

GitHub Actions builds pull requests, eligible pushes, weekly schedules, and manual
runs after lint and tests pass. Testing branches and pull requests do not publish
images. Publication is limited to `main`.

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
authentication tests with hardware. Okular changes also need a signed PDF test.
Record the tested image digest and any hardware limitations in the pull request.

Use a conventional commit prefix: `feat:`, `fix:`, `refactor:`, `chore:`, or `docs:`.
Keep commits focused. Pull requests should describe the behavior change, link
relevant issues, and report validation. Include screenshots for desktop changes.

## Keys and certificates

Never commit signing private keys. CI uses `SIGNING_SECRET`; `cosign.pub` is public.
When updating DoD certificates, keep the official archive name, update both bundle
copies and their checksums, and verify integrity.
