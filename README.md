<p align="center">
  <img src="assets/outpost-logo.png" alt="Outpost logo" width="300" />
</p>

<p align="center">
  <img src="https://github.com/large-farva/outpost/actions/workflows/build.yml/badge.svg" alt="Build status" />
</p>

# Outpost

Outpost is a Fedora Kinoite desktop image built with BlueBuild for people who use
Common Access Cards (CACs) and DoD PKI services. It includes the smart-card
middleware, DoD trust certificates, and tools for checking readers and diagnosing
connection problems.

The desktop has its own Plasma theme, wallpaper, login screen, and terminal
appearance. Fedora 43 is the current base.

## CAC support

Outpost uses OpenSC, PC/SC, and p11-kit. The `pcscd.socket` service starts the card
reader service when needed. CACKey, CoolKey, and proprietary middleware are not
included.

Firefox is installed as an RPM so it can use the system's NSS, PKCS#11, and trust
configuration. A login service checks the user's NSS database and registers a CAC
provider when one is missing. Flatpak browsers are not supported for CAC use.

The repository includes the official DoD PKCS#7 certificate archive. During the
build, its checksum is verified and its certificates are converted to PEM and
installed in the system trust store. See the [certificate notes](certificates/README.md)
for the source and verification command.

RPM Okular can be configured for CAC PDF signing with `cac-pdf-setup`. The setup
has passed container checks, but signing with a physical CAC still needs testing.
See the [validation notes](docs/validation.md) for completed checks and open work.

## Install Outpost

Start from Fedora Kinoite or a Kinoite-based image.

First, bootstrap the image:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/large-farva/outpost:latest
sudo systemctl reboot
```

After rebooting, switch to the signed image:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/large-farva/outpost:latest
sudo systemctl reboot
```

Images are signed with Sigstore Cosign. The repository includes the public key:

```bash
cosign verify --key cosign.pub ghcr.io/large-farva/outpost:latest
```

## Desktop and applications

Outpost provides a Plasma theme, wallpaper, SDDM login screen, Plymouth watermark,
panel layout, and icons. New profiles receive these defaults. Existing personal
settings are kept; the Outpost theme can be selected in **System Settings > Colors
& Themes**.

The Flatpak selection includes Flatseal, XCA, Kontainer, Warehouse, Bazaar, Kate,
OnlyOffice, and Signal. Firefox and Okular are RPMs for access to the CAC stack.

Starship comes from the `atim/starship` COPR and starts once per interactive Bash
shell. Scripts and dumb terminals skip prompt initialization. Bash also keeps
history between sessions, updates its window size, and supplies a fallback prompt
when Starship is unavailable.

`NerdFontsSymbolsOnly` is installed system-wide. Fastfetch uses the Outpost logo
and system configuration. Homebrew is optional and can be installed with
`brew-setup`.

OSTree may preserve local changes under `/etc`. If a default does not take effect,
compare the local Bash or SDDM configuration with `/usr/etc`. Back up personal
settings before editing them.

## System helpers

Open **Outpost** from the application menu or run `outpost` to see the terminal
menu. It includes system status, updates, CAC tools, PDF signing setup, Homebrew
setup, and rebasing.

`outpost --status` prints a status report without opening a menu. Redirected output
uses this mode too. `cac-help` opens the CAC menu, and each helper can also be run
on its own.

The interface uses Gum for menus, blue headers, and status colors. A numbered menu
is available when Gum is missing. Redirected output and `NO_COLOR` use plain text.
Actions that need confirmation require a terminal.

### Update the system

Run `update` as the desktop user. It updates the OS, system Flatpaks, user Flatpaks,
and Homebrew when installed. Native download and installation output stays visible,
followed by each stage's result and elapsed time.

A failed stage does not stop the remaining stages, but the command returns a
failure status. Ctrl+C stops further work; completed updates remain applied.
Reboot manually when the final deployment summary reports a pending OS update.
A deployment status query alone does not check whether a newer image is available.

Running through sudo uses the invoking user's home for user updates. A root login
without an invoking desktop user skips user Flatpaks and Homebrew.

### Sign a PDF with a CAC

1. Close Okular and run `cac-pdf-setup` as the desktop user, without sudo. It checks
   the CAC provider in `~/.pki/nssdb` and selects that database for RPM Okular.
   Existing certificates are kept. Replacing a different custom database requires
   confirmation, and changed settings are backed up beside
   `~/.config/okular-generator-popplerrc` or under `XDG_CONFIG_HOME`.
2. Insert the CAC and open the PDF in RPM Okular. Choose **Tools > Digitally Sign**,
   then draw the signature rectangle or use an existing signature field.
3. Choose the card's signing certificate, not its encryption certificate. Enter
   the PIN in Okular and save a new signed copy.
4. Open the **Signatures** panel to inspect the signature and certificate. Check
   any trust-chain or revocation warnings instead of disabling verification.

`cac-check` reports middleware, NSS, reader, and Okular configuration separately.
It does not test a PIN or prove that a card can sign. A missing card or canceled PIN
prevents signing. The helpers do not read PINs or export private keys.

Run `cac-nss-setup` to repair missing provider registration. `firefox-module` is
the entry point used by the login service; each run checks the database again.
[KDE's signing guide](https://docs.kde.org/trunk_kf6/en/okular/okular/signatures.html)
explains Okular's certificate database support.

## Testing and releases

Development work is kept on `testing/cac-and-desktop`. The workflow builds testing
branches and pull requests without publishing their images. Only builds from
`main` can publish to the image registry. A Git branch is not an installable image
channel; a public testing image would need its own publishing configuration.

Before merging CAC changes, test Firefox authentication and Okular signing with a
reader and card. A successful image build cannot replace those checks. The
[validation notes](docs/validation.md) include the hardware checklist.

Run these checks from the repository root:

```bash
shellcheck -x -P files/system/usr/lib/outpost files/system/usr/bin/* files/scripts/*.sh files/system/usr/lib/outpost/lib.sh
python3 tests/helpers.py
python3 tests/customization.py
(cd certificates && sha256sum -c unclass-certificates_pkcs7_DoD.zip.sha256)
(cd files/system/usr/share/outpost/certs && sha256sum -c unclass-certificates_pkcs7_DoD.zip.sha256)
bluebuild build recipes/recipe.yml
```

The Python checks use temporary files and command stubs. They do not update the
host or access a CAC. KConfig checks run when `kreadconfig6` and `kwriteconfig6` are
available. Build scripts modify system paths and should only run inside an image
build.

## Help and future work

The [wiki](https://github.com/large-farva/outpost/wiki) covers CAC architecture,
Firefox behavior, trust stores, diagnostics, and network or captive-portal issues.
Include relevant diagnostic output when reporting a problem, with personal
certificate details removed.

The [development recommendations](docs/recommendations.md) describe proposed
release, testing, and desktop improvements. Diagnostics improvements and an
NVIDIA-compatible image remain areas for future work.
