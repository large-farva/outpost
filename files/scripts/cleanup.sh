#!/usr/bin/env bash
set -oue pipefail

# Temperary solution for cleaning up branding form base image.

# Remove Aurora and Fedora backgrounds
rm -rf /usr/share/backgrounds/aurora/
rm -rf /usr/share/backgrounds/f43/
rm -rf /usr/share/backgrounds/fedora-workstation/
rm -rf /usr/share/backgrounds/images/

# Remove Aurora's other watermark in Spinner plymouth theme.
rm /usr/share/plymouth/themes/spinner/kinoite-watermark.png

# Remove Aurora's icons
rm /usr/share/icons/hicolor/scalable/places/auroalogo*

# Remove Aurora's autostart entries that don't apply to Outpost
rm /etc/xdg/autostart/orca-autostart.desktop
rm /etc/xdg/autostart/vboxclient.desktop
rm /etc/xdg/autostart/vmware-user.desktop

