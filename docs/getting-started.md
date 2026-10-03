# Get started with Outpost

These instructions are for an existing Fedora Kinoite or compatible Kinoite-based
installation. They switch the installed OS image rather than install to a new disk.
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

This first deployment includes Outpost's signing configuration. After logging in,
switch to the signed image:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/large-farva/outpost:latest
systemctl reboot
```

Again, reboot only after the rebase succeeds. Future updates should use the signed
image. The project's public verification key is [cosign.pub](../cosign.pub).

If either command fails, keep the error output and fix the problem before
moving on. If the new deployment won't start, use the previous deployment from
the boot menu. See [recovery](recovery.md) for help.

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

Use RPM Firefox for this workflow. Outpost's CAC setup doesn't cover Flatpak
browsers. If the site does not see the card, run `cac-check` or choose **Fix CAC
connection** in Outpost. The [CAC guide](cac.md) explains the checks and recovery
steps.

For PDFs, follow [Sign a PDF](pdf-signing.md). Website authentication and document
signing can use different certificates on the same card.

## Testing versions

The `testing` branch publishes `ghcr.io/large-farva/outpost-testing:latest` after
its build checks pass. This is separate from the production image at
`ghcr.io/large-farva/outpost:latest`. Work branches and pull requests do not publish
installable images.

Testing images can contain changes that have not passed physical CAC or VM tests.
Start in a VM and keep a known-good deployment before trying one on your working
machine. Follow the [recovery instructions](recovery.md) to pin that deployment.

Both channels use Outpost's signing key. New images include trust entries for
both addresses. An older production installation may need a trust entry for the
testing address before a signed rebase will work. Do not bypass a signature error
or treat a successful build as proof that CAC login works.

Follow [Try the testing image](testing.md) for signed switching commands and the
one-time trust setup needed by older installations.
