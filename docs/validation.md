# Validation notes

Local builds and automated checks have passed. Desktop boot behavior, Firefox CAC
authentication, and PDF signing with a physical card still need testing. No reader
was connected during these checks.

## Completed checks

- ShellCheck 0.11.0, Bash syntax checks, and desktop entry validation passed.
- Actionlint 1.7.12 passed. Local checks of the workflow expressions confirmed that
  testing pushes, testing manual runs, pull requests, and tags do not publish or
  receive signing credentials. Main-branch pushes, scheduled builds, and manual
  runs retain publication. GitHub Actions has not run this branch yet.
- The documentation and comment edit was checked for unchanged executable content
  and preserved license headers.
- `python3 tests/helpers.py` passed. It checks update progress, failure handling,
  user context, deployment status, cancellation, NSS repair, and reader errors.
  KConfig settings were also written and read back in a temporary home.
- `python3 tests/customization.py` passed. It checks cleanup's build guard,
  missing-asset refusal, repeated runs, and symlink handling. It also checks Bash
  defaults and Starship startup in interactive, noninteractive, and dumb terminals.
- Terminal checks confirmed Gum selection, the numbered fallback, blue rounded
  headers, status colors, and readable plain output.
- Both certificate archives match the recorded SHA-256 digest. Their contents are
  unchanged. Both checksum files now include the archive filename and pass
  `sha256sum -c`.

The Python tests use temporary files and command stubs. They do not perform real
system updates or access a CAC.

## Local build records

Both builds used BlueBuild 0.9.37 with rootless Podman:

```bash
bluebuild build recipes/recipe.yml --build-driver podman --run-driver podman --no-sign
```

| Build | Image ID | Result |
| --- | --- | --- |
| Helpers without desktop branding | `74f6c70bf94ec171356a7a84ac5304e2d3ca81a576454362372e9447deda7538` | Passed |
| Outpost branding, Starship, and fonts | `4626136580bbf527422c9b94108cbb369fc28e2dd45d25f2067c60cfa2286a2b` | Passed |

The branded build was tagged `localhost/outpost:latest` and
`localhost/outpost:latest_linux_amd64`. Neither build was pushed, and the host was
not rebased.

The first build used base digest
`sha256:7852e7b35a70d7e72d79933d078061b40d859beffe91017803d6c9a54761d5b3`.
Its reported image size was 8,306,724,513 bytes, before registry compression.
The interval from template creation to image creation was about 191 seconds;
that excludes initial CLI validation and is not a complete build benchmark.

Both builds completed despite dracut warnings:
`Failed to copy xattr ... Operation not supported`. A booted VM test is still
needed to assess the resulting initramfs.

## Checks inside the branded image

A disposable, unprivileged container confirmed:

- Starship 1.24.2-1.fc43 and both Symbols Nerd Font faces were installed under
  `/usr/share/fonts/nerd-fonts/NerdFontsSymbolsOnly`.
- Outpost's Plasma, SDDM, wallpaper, and Plymouth assets were present. Branding
  cleanup completed, and the stock Fedora global theme was absent.
- Fastfetch loaded the system configuration and identified Outpost 43.
- Repeated `cac-nss-setup` and `cac-pdf-setup` runs succeeded with real NSS and
  KConfig tools. Fedora NSS already exposed `p11-kit-proxy`, so setup did not add
  a duplicate provider. p11-kit listed OpenSC and system trust.
- The DoD trust bundle was installed. Okular's installed
  `/usr/share/config.kcfg/pdfsettings.kcfg` confirmed the `Signatures` group and
  the `UseDefaultCertDB` and `DBCertificatePath` keys in
  `okular-generator-popplerrc`.

The image contained Okular 26.04.3-1.fc43, Poppler 25.07.0-5.fc43, and
nss-tools 3.129.0-1.fc43. Successful configuration does not establish that a card
can authenticate or sign.

## Before merging CAC changes

- Boot the image and check the Outpost desktop and login screen with a new account.
  Verify that an existing account keeps its settings. Attach screenshots to the PR.
- Open both desktop launchers. Check menu navigation, terminal resizing,
  cancellation, the numbered fallback, and redirected output.
- Run updates as the desktop user and through sudo. Compare the final deployment
  and reboot status with `rpm-ostree status`; check system and user Flatpaks and
  Homebrew too.
- Run `cac-check` without a reader, with an empty reader, and with an inserted CAC.
- Authenticate with Firefox RPM using a CAC.
- Sign a PDF in Okular and inspect the saved signature. Test a missing card and a
  canceled PIN prompt. Confirm that helper logs contain no PINs.

Record the image digest, package versions, reader model, and results with each
hardware test. Keep personal certificate details out of public reports.

## Performance

There is no measured build-speed or image-size improvement yet. A useful comparison
needs the same builder, architecture, base digest, and package repository snapshot.
The small source payload from the unbranded build does not describe the branded
image.
