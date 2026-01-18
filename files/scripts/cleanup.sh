#!/usr/bin/env bash
set -euo pipefail
umask 022

# Temporary solution for cleaning up branding from base image.

shopt -s nullglob

# Remove backgrounds
rm -rf /usr/share/backgrounds/aurora/ \
       /usr/share/backgrounds/f43/ \
       /usr/share/backgrounds/fedora-workstation/ \
       /usr/share/backgrounds/images/ || true

# Remove watermark in Spinner plymouth theme.
rm -f /usr/share/plymouth/themes/spinner/kinoite-watermark.png || true

# Remove icons
rm -f /usr/share/icons/hicolor/scalable/places/auroralogo* || true

# Remove autostart entries that don't apply to Outpost
rm -f /etc/xdg/autostart/orca-autostart.desktop \
      /etc/xdg/autostart/vboxclient.desktop \
      /etc/xdg/autostart/vmware-user.desktop || true

# Remove avatars
rm -f /usr/share/plasma/avatars/*.png || true

# Remove look-and-feel package (base theme)
rm -rf /usr/share/plasma/look-and-feel/dev.getaurora.aurora.desktop/ || true

# Remove SDDM theme
rm -rf /usr/share/sddm/themes/01-breeze-aurora/ || true

# Remove wallpapers
rm -rf /usr/share/wallpapers/Altai/ \
       /usr/share/wallpapers/Autumn/ \
       /usr/share/wallpapers/BytheWater/ \
       /usr/share/wallpapers/Canopee/ \
       /usr/share/wallpapers/Cascade/ \
       /usr/share/wallpapers/Cluster/ \
       /usr/share/wallpapers/Coast/ \
       /usr/share/wallpapers/ColdRipple/ \
       /usr/share/wallpapers/ColorfulCups/ \
       /usr/share/wallpapers/DarkestHour/ \
       /usr/share/wallpapers/Dynamic/ \
       /usr/share/wallpapers/Elarun/ \
       /usr/share/wallpapers/EveningGlow/ \
       /usr/share/wallpapers/F43/ \
       /usr/share/wallpapers/Fallenleaf/ \
       /usr/share/wallpapers/Fedora/ \
       /usr/share/wallpapers/FLow/ \
       /usr/share/wallpapers/FlyingKonqui/ \
       /usr/share/wallpapers/Grey/ \
       /usr/share/wallpapers/Honeywave/ \
       /usr/share/wallpapers/IceCold/ \
       /usr/share/wallpapers/Kay/ \
       /usr/share/wallpapers/Kite/ \
       /usr/share/wallpapers/Kokkini/ \
       /usr/share/wallpapers/MilkyWay/ \
       /usr/share/wallpapers/Mountain/ \
       /usr/share/wallpapers/Next/ \
       /usr/share/wallpapers/Nexus/ \
       /usr/share/wallpapers/Nuvole/ \
       /usr/share/wallpapers/OneStandsOut/ \
       /usr/share/wallpapers/Opal/ \
       /usr/share/wallpapers/PastelHills/ \
       /usr/share/wallpapers/Patak/ \
       /usr/share/wallpapers/Path/ \
       /usr/share/wallpapers/SafeLanding/ \
       /usr/share/wallpapers/ScarletTree/ \
       /usr/share/wallpapers/Shell/ \
       /usr/share/wallpapers/summer_1am/ \
       /usr/share/wallpapers/Volna/ || true

# Remove background symlinks
ln -sf /usr/share/backgrounds/outpost/outpost-background.jxl \
       /usr/share/backgrounds/default.jxl

ln -sf /usr/share/backgrounds/outpost/outpost-background.jxl \
       /usr/share/backgrounds/default-dark.jxl

ln -sf /usr/share/backgrounds/outpost/outpost-background.jxl \
       /usr/share/backgrounds/default-light.jxl

# Remove bazaar-install-count and fastetch-user-count
rm -f /usr/share/ublue-os/bazaar-install-count \
      /usr/share/ublue-os/fastetch-user-count || true

# Remove motd tips
rm -rf /usr/share/ublue-os/motd/tips/