#!/usr/bin/env bash
set -euo pipefail
umask 022

# Branding cleanup is restricted to image builds.
if [[ ${IMAGE_NAME:-} != outpost || ! -d ${CONFIG_DIRECTORY:-/nonexistent}/system ]]; then
    printf 'cleanup.sh must run in the Outpost image build.\n' >&2
    exit 1
fi

# Missing replacements would leave the desktop without its theme or wallpaper.
for asset in \
    /usr/share/plasma/look-and-feel/org.outpost.desktop/metadata.json \
    /usr/share/wallpapers/Outpost/contents/images/1920x1080.png \
    /usr/share/sddm/themes/outpost/Main.qml \
    /usr/share/plymouth/themes/spinner/watermark.png; do
    [[ -s "$asset" ]] || { printf 'Missing Outpost asset: %s\n' "$asset" >&2; exit 1; }
done

shopt -s nullglob

paths=(
    /usr/share/plasma/look-and-feel/org.fedoraproject.fedora.desktop
    /usr/share/plasma/look-and-feel/org.fedoraproject.fedoradark.desktop
    /usr/share/plasma/look-and-feel/org.fedoraproject.fedoralight.desktop
    /usr/share/plasma/avatars/*.png
    /usr/share/backgrounds/f*/
    /usr/share/backgrounds/images
    /usr/share/backgrounds/default.xml
    /usr/share/sddm/themes/01-breeze-fedora
    /usr/share/plymouth/themes/spinner/kinoite-watermark.png
    /usr/share/fedora-logos
    /usr/share/anaconda
    /usr/share/pixmaps/fedora*
    /etc/favicon.png
    /usr/share/icons/Bluecurve
    /usr/share/icewm
    /usr/lib/swidtag/fedoraproject.org
)
# Trailing slashes can cause removal tools to follow directory symlinks.
for path in "${paths[@]}"; do
    rm -rf -- "${path%/}"
done

for path in /usr/share/wallpapers/*; do
    [[ ${path##*/} == Outpost || -L "$path" ]] && continue
    [[ -d "$path" ]] && rm -rf -- "$path"
done
# Working wallpaper aliases may point to the Outpost wallpaper.
for path in /usr/share/wallpapers/*; do
    if [[ -L "$path" && ! -e "$path" ]]; then
        rm -- "$path"
    fi
done
printf 'Outpost branding cleanup complete.\n'
