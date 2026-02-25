#!/usr/bin/env bash
set -euo pipefail
umask 022

# Remove base image branding.

shopt -s nullglob

# --- Plasma ---

# Remove Fedora global themes from System Settings > Appearance
rm -rf /usr/share/plasma/look-and-feel/org.fedoraproject.fedora.desktop/ \
       /usr/share/plasma/look-and-feel/org.fedoraproject.fedoradark.desktop/ \
       /usr/share/plasma/look-and-feel/org.fedoraproject.fedoralight.desktop/ || true

# Remove stock avatars
rm -f /usr/share/plasma/avatars/*.png || true

# --- Wallpapers and backgrounds ---

rm -rf /usr/share/backgrounds/f*/ || true
rm -rf /usr/share/backgrounds/images/ || true
rm -f /usr/share/backgrounds/default.xml || true

for d in /usr/share/wallpapers/*/; do
  [[ "$(basename "$d")" == "Outpost" ]] && continue
  rm -rf "$d"
done

# Remove broken symlinks left after directory cleanup (e.g., Default, Fedora)
for f in /usr/share/wallpapers/*; do
  [[ -L "$f" ]] && rm -f "$f"
done

# --- SDDM ---

rm -rf /usr/share/sddm/themes/01-breeze-fedora/ || true

# --- Plymouth ---

rm -f /usr/share/plymouth/themes/spinner/kinoite-watermark.png || true

# --- Fedora logos and branding ---

rm -rf /usr/share/fedora-logos/ || true
rm -rf /usr/share/anaconda/ || true
rm -f /usr/share/pixmaps/fedora* || true
rm -f /etc/favicon.png || true

# --- Legacy icon themes with Fedora branding ---

rm -rf /usr/share/icons/Bluecurve/ || true
rm -rf /usr/share/icewm/ || true # Why is IceWM even here?

# --- Software identification ---

rm -rf /usr/lib/swidtag/fedoraproject.org/ || true
