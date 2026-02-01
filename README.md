<p align="center">
  <img src="assets/outpost-logo.png" alt="Outpost logo" width="300" />
</p>

<p align="center">
  <img src="https://github.com/large-farva/outpost/actions/workflows/build.yml/badge.svg">
</p>

# Outpost

Outpost is a custom **Fedora Kinoite** immutable desktop image built with **BlueBuild**.

It is based on the **official upstream Fedora Kinoite image** and provides a **CAC-ready Fedora workstation** with curated defaults and **no post-install configuration required**.

Outpost is designed for environments where **Common Access Card (CAC)** authentication and DoD PKI trust are required.

## Features

### DoD CAC support
- `opensc`
- `pcsc-lite`, `pcsc-lite-ccid`
- `pcsc-tools`
- `p11-kit`
- `pcscd.socket` enabled for on-demand activation

Outpost does **not** ship CACKey, CoolKey, or proprietary vendor middleware.  
**OpenSC** is the supported and tested provider.

---

### DoD trust anchors
- Official **DoD PKCS#7 certificate bundle** is **vendored in the repository**
- ZIP filename is unchanged from the official distribution
- Certificates are extracted, converted to PEM, and installed into the system trust store at build time

---

### Firefox
- Firefox is installed as an **RPM**, not a Flatpak
- Uses system NSS, PKCS#11, and CA trust integration
- CAC works without per-user manual setup in normal cases
---

### Curated Flatpak baseline
- Kontainer
- OnlyOffice
- Signal
- XCA

## Installation

⚠️ You must rebase from **Fedora Kinoite** or a Kinoite-based image.  

### 1. Bootstrap
```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/large-farva/outpost:latest
sudo systemctl reboot
```

### 2. Rebase to the signed image
```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/large-farva/outpost:latest
sudo systemctl reboot
```

## Verification

Outpost images are signed using **Sigstore Cosign**.

Verify with the included public key:

```bash
cosign verify --key cosign.pub ghcr.io/large-farva/outpost:latest
```

## CAC Support

Outpost includes all middleware and trust components required for CAC authentication.

Supported:
- Firefox (RPM)
- System-wide PKCS#11 and CA trust integration

Not supported:
- Flatpak browsers
- Proprietary middleware

## Documentation

Detailed documentation is available in the [Wiki](https://github.com/large-farva/outpost/wiki).

This includes:
- CAC architecture and behavior
- Diagnostics and troubleshooting
- Firefox-specific behavior
- Trust store handling
- Network and captive portal considerations

Please review the wiki before opening an issue.

## Roadmap

### Near-term
- Documentation polish
- Diagnostics refinement

### Longer-term
- Okular support for CAC based PDF signing
- Optional NVIDIA-compatibile image variant

## Issues

When reporting issues, include relevant diagnostics from the wiki where applicable.