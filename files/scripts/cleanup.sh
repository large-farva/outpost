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
       /Autumn \
       /BytheWater \
       /Canopee \
       /Cascade \
       /Cluster \
       /Coast \
       /ColdRipple \
       /ColorfulCups \
       /DarkestHour \
       /Dynamic \
       /Elarun \
       /EveningGlow \
       /F43 \
       /Fallenleaf \
       /Fedora \
       /FLow \
       FlyingKonqui \
       /Grey \
       /Honeywave \
       /IceCold \
       /Kay \
       /Kite \
       /Kokkini \
       /MilkyWay \
       /Mountain \
       /Next \
       /Nexus \
       /Nuvole \
       /OneStandsOut \
       /Opal \
       /PastelHills \
       /Patak \
       /Path \
       /SafeLanding \
       /ScarletTree \
       /Shell \
       /summer_1am \
       /Volna || true

# Remove background symlinks
ln -sf /usr/share/backgrounds/outpost/outpost-background.jxl \
       /usr/share/backgrounds/default.jxl

ln -sf /usr/share/backgrounds/outpost/outpost-background.jxl \
       /usr/share/backgrounds/default-dark.jxl

ln -sf /usr/share/backgrounds/outpost/outpost-background.jxl \
       /usr/share/backgrounds/default-light.jxl
