#!/usr/bin/env bash
set -oue pipefail

rm -rf /usr/share/backgrounds/aurora/
rm -rf /usr/share/backgrounds/f43/
rm -rf /usr/share/backgrounds/fedora-workstation/
rm -rf /usr/share/backgrounds/images/

rm /usr/share/icons/hicolor/scalable/places/auroalogo*

rm /etc/xdg/autostart/orca-autostart.desktop
rm /etc/xdg/autostart/vboxclient.desktop
rm /etc/xdg/autostart/vmware-user.desktop

