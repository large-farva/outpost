# Contributing to Outpost

Use a branch and open a pull request for changes to the image. The testing branch
is `testing/cac-and-desktop`. Its builds do not publish images; only `main` can
publish. A Git branch is not an installable image channel.

Keep documentation, build-tool updates, and CAC behavior changes in separate
commits where possible. Test each proposed change before promoting it to `main`;
a passing build alone does not establish that a CAC change is safe.

GitHub Actions are pinned to commits, and Dependabot proposes updates weekly.
Update the pinned BlueBuild CLI version through a PR with a successful image
build. Fedora packages and BlueBuild modules still follow upstream repositories.

## Local checks

Run from the repository root:

```bash
shellcheck -x -P files/system/usr/lib/outpost files/system/usr/bin/* files/scripts/*.sh files/system/usr/lib/outpost/lib.sh tests/cac-image.sh
python3 tests/helpers.py
python3 tests/customization.py
python3 tests/cac.py
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

ShellCheck, Bash syntax, Actionlint, all three Python checks, and both certificate
checksums passed. The final local image built with BlueBuild 0.9.37 and rootless
Podman:

`c3581d09f26b34fb0de350a647a5cef44fae57c1adea66dd202c2ec6d7b0a457`

The offline container test passed repeated NSS/Okular setup and two Firefox
starts with one system CAC provider. The policy uses Fedora's registered library
name to avoid loading the same provider twice.

Physical-card authentication, JKO access, PDF signing, and booted-VM recovery remain
untested. The build reported dracut xattr warnings, so boot validation is required.
Nothing was published. No build-speed improvement has been measured.
