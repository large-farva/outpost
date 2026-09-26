# Get started with Outpost

These instructions are for an existing Fedora Kinoite or compatible Kinoite-based
installation. They switch the installed OS image; they are not a disk installer.
Back up important files and save your work before starting.

## Install the image

Open a terminal and run:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/large-farva/outpost:latest
```

Wait for the command to finish successfully, then reboot:

```bash
systemctl reboot
```

This first deployment supplies Outpost's signing configuration. After logging in,
switch to the signed image:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/large-farva/outpost:latest
systemctl reboot
```

Again, reboot only after the rebase succeeds. Future updates should use the signed
image. The project's public verification key is [cosign.pub](../cosign.pub).

If either command fails, keep the error output and resolve that failure before
moving on. If the new deployment will not start, use the previous deployment from
the boot menu; see [recovery](recovery.md).

## Check the installation

Open **Outpost** from the application menu, or run:

```bash
outpost --status
rpm-ostree status
```

The deployment marked as booted is the one currently running. A pending deployment
will take effect after a reboot. Status alone does not check for new updates.

Your existing account keeps its saved settings. Image defaults may not replace
personal settings or locally changed files under `/etc`.

## Connect a CAC

1. Connect the reader and insert the CAC fully.
2. Open the included RPM Firefox and visit the CAC sign-in page for the service.
3. When asked, choose the authentication certificate and enter the PIN in the
   application's prompt.

Use RPM Firefox for this workflow; Flatpak browsers are not covered by Outpost's
CAC setup. If the site does not see the card, run `cac-check` or choose **Fix CAC
connection** in Outpost. The [CAC guide](cac.md) explains the checks and recovery
steps.

For PDFs, follow [Sign a PDF](pdf-signing.md). Website authentication and document
signing can use different certificates on the same card.

## Testing versions

The `testing` Git branch holds changes under development. Pushing
to that branch does not publish an installable testing image. Do not use a Git
branch name as an image tag unless a release explicitly provides that tag and
its installation instructions.
