# Contributing to Outpost

Use a branch and open a pull request for changes to the image. The testing branch
is `testing`. Successful pushes and manual runs publish the signed
`ghcr.io/large-farva/outpost-testing:latest` image. `main` publishes
`ghcr.io/large-farva/outpost:latest` and retains its weekly build schedule.
Pull requests and other branches build without publishing.

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
commits where possible. Test each proposed change before promoting it to `main`;
a passing build alone does not establish that a CAC change is safe.

GitHub Actions are pinned to commits, and Dependabot proposes updates weekly.
Update the pinned BlueBuild CLI version through a PR with a successful image
build. Fedora packages and BlueBuild modules still follow upstream repositories.

## Image channels

Both recipes use `recipes/common.yml`. Keep base-image versions aligned in
`recipe.yml` and `testing.yml`. The channel build script sets the rebase target
and signature policy after the signing module runs. Both channels use
`SIGNING_SECRET` and the repository's `cosign.pub`.

The pinned BlueBuild CLI gives non-main branches commit tags. The workflow verifies
the testing signature, runs the offline container smoke test, copies the same manifest to `latest`, and checks that the
digest is unchanged. It never retags testing into the production repository.

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
(cd certificates && sha256sum -c unclass-certificates_pkcs7_DoD.zip.sha256)
(cd files/system/usr/share/outpost/certs && sha256sum -c unclass-certificates_pkcs7_DoD.zip.sha256)
bluebuild build recipes/recipe.yml --build-driver podman --run-driver podman --no-sign
```

The Python tests use temporary files and command stubs. They do not update the
host, restart its services, or use a CAC. Build scripts belong inside an image
build; do not run them directly on the host.

After building, run the offline container smoke test:

```bash
podman run --rm --network none --user 1000:1000 --security-opt label=disable \
  --tmpfs /tmp:rw,mode=1777 \
  -v "$PWD/tests/cac-image.sh:/tmp/test.sh:ro" \
  localhost/outpost:latest bash /tmp/test.sh
```

This checks repeated NSS/Okular setup and Firefox startup without duplicate
providers. It creates a temporary browser profile; no personal profile is used.

## Before merging CAC changes

- Boot the image in a VM. Check both desktop launchers and menu cancellation.
- Check updates, pending-deployment reporting, and rollback.
- Run CAC checks with no reader, an empty reader, and an inserted card.
- Test Firefox authentication, then remove/reinsert the card and run recovery.
  Check `about:policies` for errors and confirm the card appears in Security Devices.
- Sign a PDF in Okular and inspect the saved signature. Test a canceled PIN prompt.
- Review a local diagnostic report for identifying data before sharing it.

Record the image digest, package versions, reader model, and results in the PR.

## Validation status

ShellCheck, Bash syntax, Actionlint, helper regression tests, and certificate
checksums have passed locally. The testing recipe built with BlueBuild 0.9.37 and
rootless Podman without publishing or signing the local image:

`1285f06d861fdaff94efcb9aea82512d056a20e852ab04e0c6b10dbc56997c24`

Container checks confirmed testing-channel metadata, both signature-policy entries,
and the shared public-key path. Repeated NSS/Okular setup and two Firefox starts
passed with one system CAC provider. Publishing tests use command stubs; actual
registry publication and signature verification still need a GitHub run.

Physical-card authentication, JKO access, PDF signing, and booted-VM recovery remain
untested. The build reported dracut xattr warnings, so boot validation is required.
