# Contributing to Outpost

Make your changes on a branch, then open a pull request. Successful pushes and
manual runs on `testing` publish the signed
`ghcr.io/large-farva/outpost-testing:latest` image. `main` publishes
`ghcr.io/large-farva/outpost:latest`, with a scheduled build each week.
Pushes and manual runs on `personal` publish `ghcr.io/large-farva/outpost-personal:latest`.
Pull requests and other branches build without publishing.

Personal additions stay on `personal`. Bring production updates into that branch
by merging `main` into it, never by merging `personal` back. See the
[personal image guide](docs/personal.md) for setup.

Use `main` for production and `testing` to collect changes awaiting validation.
The current CAC and desktop work is also kept on `test/cac-desktop`. Create focused
work branches with names such as `feat/cac-recovery`, `fix/reader-detection`,
`docs/recovery-guide`, or `ci/build-checks`. Use `test/` for testing work or
experiments, followed by a short description.

Open work-branch PRs against `testing` when they need image or hardware testing.
Merge `testing` into `main` only when all included changes are ready. To release
only selected changes, prepare a separate PR from `main` and review its dependencies.
Branch names alone do not configure publishing or require reviews.

Keep documentation, build-tool updates, and CAC behavior changes in separate
commits where possible. Test changes before merging them into `main`. A successful
build can't tell us whether a CAC works with a reader and website.

GitHub Actions are pinned to commits, and Dependabot proposes updates weekly.
Update the pinned BlueBuild CLI version through a PR with a successful image
build. Fedora packages and BlueBuild modules still follow upstream repositories.

## Image channels

Each branch uses `recipes/recipe.yml`. Personal packages are added directly to
that recipe on `personal`, without a second recipe. CI's
`.github/scripts/select-channel.sh` changes only the top-level `name` to `outpost`,
`outpost-testing`, or `outpost-personal`. Publishing follows the branch and event
rules above.

The channel build script sets the rebase target and signature policy after the
signing module runs. All channels use `SIGNING_SECRET` and the repository's
`cosign.pub`.

The pinned BlueBuild CLI gives non-main branches commit tags. Before publishing
`latest`, the workflow verifies the testing or personal image's signature and runs the offline
container smoke test. It then copies the same manifest to `latest` and checks that
the digest hasn't changed. Testing and personal images each stay in their own repository.

After the first publication, check the `outpost-testing` package's visibility and
repository access in GitHub settings. Public installation instructions require
public read access. Confirm the workflow's signature verification step succeeds
before sharing a testing image.

## Local checks

Run from the repository root:

```bash
shellcheck -x -P files/system/usr/lib/outpost files/system/usr/bin/* files/scripts/*.sh files/system/usr/lib/outpost/lib.sh tests/cac-image.sh .github/scripts/*.sh
python3 tests/helpers.py
python3 tests/customization.py
python3 tests/cac.py
python3 tests/channels.py
python3 tests/tui.py
(cd certificates && sha256sum -c unclass-certificates_pkcs7_DoD.zip.sha256)
(cd files/system/usr/share/outpost/certs && sha256sum -c unclass-certificates_pkcs7_DoD.zip.sha256)
bluebuild build recipes/recipe.yml --build-driver podman --run-driver podman --no-sign
```

Local builds default to the committed production name `outpost` regardless of
branch. For a local testing-channel build, run
`EVENT_NAME=push REF=refs/heads/testing bash .github/scripts/select-channel.sh`
before the build command above. This only prepares the recipe. It does not publish.
Use `localhost/outpost-testing:latest` for the smoke test below, and restore
`name: outpost` in the recipe before committing.

The Python tests use temporary files and command stubs. They do not update the
host, restart its services, or use a CAC. Build scripts belong inside an image
build. Do not run them directly on the host.

After building, run the offline container smoke test:

```bash
podman run --rm --network none --user 1000:1000 --security-opt label=disable \
  --tmpfs /tmp:rw,mode=1777 \
  -v "$PWD/tests/cac-image.sh:/tmp/test.sh:ro" \
  localhost/outpost:latest bash /tmp/test.sh
```

The smoke test checks that RPM Firefox/Okular and the English glibc locale package
are installed, the Firefox/all-glibc language packs are absent, and `en_US.UTF-8`,
`C`, `C.UTF-8`, and `POSIX` are available. It also checks that Noto CJK Sans is
installed without the CJK Serif and Mono packages. Finally, it repeats NSS/Okular
setup and starts Firefox under US English to catch duplicate providers. It uses
a temporary browser profile, not your own.

## English-only image

The recipe installs `glibc-langpack-en` before removing `glibc-all-langpacks`,
and removes `firefox-langpacks` while excluding it from the install transaction.
Firefox uses its built-in US English interface. Other weak dependencies remain enabled.

The build-only `files/scripts/cleanup.sh` removes non-English translation,
HTML-help, man-page, and speech-dispatcher language directories. It retains
English regional variants, default man sections, shared speech dictionaries,
and shared locale/help data. Oxygen cleanup targets only the Fedora icons.
General documentation, license notices, Adobe PDF mappings, RPM metadata,
compiler tooling, and DNF remain untouched by this trim. There's still a couple Fedora
packages that are not removed by this trim because it's not really the highest priority.

Noto CJK Sans is explicitly installed as the Chinese/Japanese/Korean fallback.
The CJK Serif and Mono font packages are excluded from installation and removed
with automatic dependency cleanup disabled. Their dependent `default-fonts-cjk-serif`
and `default-fonts-cjk-mono` metapackages are also removed. Regular English fonts,
symbol fonts, and emoji fonts are not targeted. CJK text can fall back to Sans,
but serif styling and monospace alignment may change.

Validate a new image in a VM or bare metal:
- PDF rendering/signing, and CAC authentication.
- Measure the resulting filesystem and published image separately

## Before merging CAC changes

- Boot the image in a VM or on bare metal. Check both desktop launchers and menu cancellation.
- Run `rpm -q okular` and `flatpak list --app --columns=application,installation`.
  Confirm RPM Okular is installed, no Okular Flatpak is installed, and PDFs open
  in RPM Okular.
- Check updates, pending-deployment reporting, and rollback.
- Run CAC checks with no reader, an empty reader, and an inserted card.
- Test Firefox authentication, then remove/reinsert the card and run recovery.
  Check `about:policies` for errors and confirm the card appears in Security Devices.
- Sign a PDF in Okular and inspect the saved signature. Test a canceled PIN prompt.
- Review a local diagnostic report for identifying data before sharing it.

Record the image digest, package versions, reader model, and results in the PR.

## Validation status

### Historical container checks

These results are from when I tried useing multiple recipes (it didn't work out). They're kept here for
reference, not as test results for the current recipe or newer smoke checks.

ShellCheck, Bash syntax, Actionlint, helper regression tests, and certificate
checksums passed locally. The former `recipes/testing.yml` built with BlueBuild
0.9.37 and rootless Podman without publishing or signing the local image:

`1285f06d861fdaff94efcb9aea82512d056a20e852ab04e0c6b10dbc56997c24`

Container checks confirmed testing-channel metadata, both signature-policy entries,
and the shared public-key path. Repeated NSS/Okular setup and two Firefox starts
passed with one system CAC provider. At that point, publishing had only been tested
with command stubs. Registry publication and signature verification still needed
a GitHub run.

At that time, physical-card authentication, JKO access, PDF signing, and booted-VM
recovery were untested. The build reported dracut xattr warnings, so boot validation
was still required.

### User-reported hardware test (2026-10-03)

JKO login in Firefox worked after running **Fix CAC connection** in `outpost-testing` after the TUI overhaul. The
first attempt ran into a problem after CAC selection and PIN entry. I forgot to save the Firefox error code. Clean-start and repeated logins test fine.

CAC PDF signing in Okular worked as expected.

If the login problem comes back, note the exact Firefox error and save a
`cac-report` before running recovery. Check the report for personal information
before sharing it.
