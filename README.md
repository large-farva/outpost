# Atlas

&nbsp; [![bluebuild build badge](https://github.com/large-farva/atlas/actions/workflows/build.yml/badge.svg)](https://github.com/large-farva/atlas/actions/workflows/build.yml)


Atlas is a custom Fedora Silverblue-based image built with BlueBuild.
It extends the [ublue-os/silverblue-main](https://github.com/ublue-os?utm_source=chatgpt.com) base image to provide:

- DoD CAC smart card support out of the box
- Firefox (RPM version) pre-layered for reliable CAC + PKCS#11 integration
- System-wide DoD root certificates installed automatically
- Curated Flatpak defaults for productivity and desktop essentials

Chrome/Chromium CAC support is a work in progress.
Flatpak browsers are not supported (Flatpak sandboxing prevents PKCS#11 access).

---

### Features

- **Smart card middleware preinstalled**: ```pcsc-lite```, ```pcsc-lite-ccid```, ```opensc```, ```p11-kit```, and supporting tools
- **Automatic socket activation**: ```pcscd.socket``` is enabled so readers/cards work without manual configuration
- **DoD trust anchors**: DISA's PKI bundle is fetched, converted, and added to system trust at build time
- **RPM Firefox** layered into the image for **native NSS & PKCS#11 support**.
- **Flatpak baseline**: Papers, Loupe, Clapper, Inspector, Signal, Extension Manager, Bottles, OnlyOffice, etc.

---

### Installation

1. First rebase to the unsigned image to bootstrap signing policy:

``` bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/large-farva/atlas:latest
sudo systemctl reboot
```

2. Then rebase to the signed image:

``` bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/large-farva/atlas:latest
sudo systemctl reboot
```

The ```latest``` tag always points to the newest build, but Atlas stays pinned to the Fedora release defined in ```recipe.yml``` (eg.42). You won't be bumped to the next major Fedora automatically.

---

### Verification

Atlas images are signed with [Sigstore](https://www.sigstore.dev/)'s [Cosign](https://github.com/sigstore/cosign).

Verify an image with the included public key:
``` bash
cosign verify --key cosign.pub ghcr.io/large-farva/atlas:latest
```

---

### CAC Usage

Atlas includes all the components needed for **Common Access Card (CAC)** authentication:

- **Smart card middleware**
  - ```pcsc-lite``` and ```pcsc-lite-ccid```: industry-standard service and CCID driver for USB smart card readers.
  - ```pcscd.socket``` is enabled for on-demand activation when a card is inserted.
- **PKCS#11 provider**
  -```opensc```: open-source middleware widely used across Linux distributions for CAC and PIV cards.
  - Provides the ```/usr/lib64/opensc-pkcs11.so``` module for integration with applications like Firefox.
- **System trust**
  - DISA's **DoD PKI bundle** is fetched during the image build, converted, and installed into Fedora's CA trust store.
  - Applications using ```p11-kit``` and ```ca-certificates``` (including Firefox, curl, and OpenSSL) trust DoD TLS endpoints by default.
- **Browser support**
  - The **RPM version of Firefox** is layered into the image for direct NSS/PKCD#11 integration.
  - Flatpak browsers are not supported due to sandbox restrictions on PKCS#11 modules.
  - Chrome/Chromium support is planned for the future.

⚠️ Atlas does not ship **CACKey** or vendor-specific middleware - OpenSC is the only supported provider for simplicity and maintainability.

---

### Troubleshooting

If CAC authentication does not work as expected:

- **Reader not detected**
  ``` bash
  pcsc_scan
  ```
  If nothing appears, check:
  ``` bash
  systemctl status pcscd.socket
  ```
- **OpenSC not recognizing the card**
  ``` bash
  opensc-tool -l
  ```
  Should list your card reader. If not, the reader may not be CCID-compliant.
- **DoD sites not trusted**
  ``` bash
  trust list | grep DoD
  ```
  If no results, re-run:
  ``` bash
  sudo update-ca-trust
  ```
- **Firefox not showing CAC certs**
  Add the OpenSC PKCS#11 module manually:
  - Firefox → ```about:preferences``` → **Certificates** → **Security Devices** → Load
- **General debugging**
  View logs related to PC/SC:
  ``` bash
  journalctl -u pcscd.socket
  ```
  Or check kernel-level USB events:
  ``` bash
  journalctl -k | grep -i usb
  ```

---

### Roadmap

**Chromium (RPM) CAC Support**
- Layer ```google-chrome-stable``` or ```chromium``` RPM + document PKCS#11 setup (or auto-load OpenSC via NSS DB).
- Optionally add a launcher wrapper that ensures the PKCS#11 module is registered.

---

### Issues

Please open issues in this repository if you encounter bugs, build failures, or CAC impompaibilities. Include logs from:

``` bash
journalctl -u pcscd.socket
```
and
``` bash
opensc-tool -l
```