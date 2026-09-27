<p align="center">
  <img src="assets/outpost-logo.png" alt="Outpost logo" width="300" />
</p>

<p align="center">
  <img src="https://github.com/large-farva/outpost/actions/workflows/build.yml/badge.svg" alt="Build status" />
</p>

# Outpost

Outpost is a Fedora Kinoite desktop image with DoD certificates, CAC middleware,
and tools for troubleshooting smart-card connections. It uses KDE Plasma and is
built with BlueBuild on Fedora 43.

## Install

From Fedora Kinoite or a compatible image, run:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/large-farva/outpost:latest
systemctl reboot
```

After rebooting, switch to the signed image:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/large-farva/outpost:latest
systemctl reboot
```

The first step bootstraps the signing configuration. Subsequent updates use the
signed image. The public verification key is [cosign.pub](cosign.pub).

The [user guide](docs/README.md) covers setup, applications, CAC troubleshooting,
PDF signing, and recovery.

## Everyday use

Open **Outpost** from the application menu or run `outpost` in a terminal.

| Command | What it does |
| --- | --- |
| `update` | Updates the OS, Flatpaks, Homebrew, and reports failures and pending reboots |
| `outpost --status` | Shows system and deployment status |
| `cac-help` | Opens the CAC tools menu |
| `cac-check` | Checks the reader, card detection, services, and certificate configuration |
| `cac-recover` | Walks through restarting the card service and reconnecting the CAC |
| `cac-report` | Saves a local diagnostic report for troubleshooting |
| `cac-pdf-setup` | Sets up RPM Okular for CAC signing |
| `outpost-rollback` | Shows how to return to the previous OS deployment |

Run these as your desktop user. Updates show native progress and never reboot
automatically. Reboot when an OS update is pending.

## Using a CAC

Use the included **RPM Firefox** for CAC websites. If a site stops seeing your
card, choose **Fix CAC connection** in Outpost. The helper asks you to close
Firefox and Okular, restarts the reader service, and checks the card after you
reinsert it. See [CAC troubleshooting](docs/cac.md) if it still fails.

For PDF signing, close Okular and run `cac-pdf-setup`. Reopen the PDF, choose
**Tools > Digitally Sign**, select the signing certificate, and enter the PIN in
Okular. Save a signed copy and inspect its **Signatures** panel. Physical-card
signing still needs verification on the testing branch.

## Testing and help

The `testing` branch publishes a separate signed `outpost-testing` image.
The production image follows `main`. See [contributor guide](CONTRIBUTING.md) for test commands and
checks required before merging CAC changes.

[Report a problem](https://github.com/large-farva/outpost/issues) with the steps
that failed and a reviewed `cac-report`. Reports stay on your computer until you
choose to share them. [Recovery instructions](docs/recovery.md) cover rollback.
