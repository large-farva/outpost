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

- Plug in you CAC and run:
``` bash
pcsc_scan
```
You shouold see your reader and card recognized.
- If you hit issues, check:
``` bash
systemctl status pcscd.socket
```

- In Firefox:
  - Navigate to ```about:preferences``` → **Certificates** → **Security Devices**.
  - If **OpenSC PKCS#11 Module** is not listed, load it manually:
  ``` bash
  /usr/lib64/opensc-pkcs11.so
  ```
  - You should then be able to authenticate to DoD web apps.

⚠️ **Flatpak Firefox/Chromium will not work** with CAC. Only the layered RPM Firefox is supported.

---

### Troubleshooting

- **Reader not detected:** Run ```pcsc_scan``` while the card is inserted. If nothing shows, check ```systemctl status pcscd.socket```.
- **Certificates not trusted:** Ensure the DoD trust anchors were installed:
``` bash
trust list | grep DoD
```
- **Firefox not prompting for certs:** Verify the OpenSC PKCS#11 module is loaded.

---

### Roadmap

- Addsupport Chrome/Chromium CAC integration.
- Optional build flavors (e.g., minimal, developer-oriented).
- Better documentation on updating DoD CA bundles.

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