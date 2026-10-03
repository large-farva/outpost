#!/usr/bin/env bash
set -euo pipefail
umask 022

# Filesystem cleanup is restricted to image builds.
if [[ ( ${IMAGE_NAME:-} != outpost && ${IMAGE_NAME:-} != outpost-testing ) || ! -d ${CONFIG_DIRECTORY:-/nonexistent}/system ]]; then
    printf 'cleanup.sh must run in the Outpost image build.\n' >&2
    exit 1
fi

# Missing replacements would leave the desktop without its theme or wallpaper.
for asset in \
    /usr/share/plasma/look-and-feel/org.outpost.desktop/metadata.json \
    /usr/share/plasma/look-and-feel/org.outpost.desktop/contents/splash/Splash.qml \
    /usr/share/plasma/look-and-feel/org.outpost.desktop/contents/splash/images/logo.svg \
    /usr/share/wallpapers/Outpost/contents/images/1920x1080.png \
    /usr/share/sddm/themes/outpost/Main.qml \
    /usr/share/plymouth/themes/spinner/watermark.png; do
    [[ -s "$asset" ]] || { printf 'Missing Outpost asset: %s\n' "$asset" >&2; exit 1; }
done

# Reuse Plasma's spinner while keeping the Outpost splash self-contained.
install -m 0644 \
    /usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/splash/images/busywidget.svgz \
    /usr/share/plasma/look-and-feel/org.outpost.desktop/contents/splash/images/busywidget.svgz

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
    /usr/share/icons/oxygen/*/places/start-here-kde-fedora.png
    /usr/share/icons/oxygen/scalable/apps/org.fedoraproject.AnacondaInstaller.svg
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
# Keep shared data and default English manuals, not just directories named en.
for root in /usr/share/locale /usr/share/doc/HTML /usr/share/man /usr/share/speech-dispatcher/locale; do
    [[ -d "$root" && ! -L "$root" ]] || continue
    for path in "$root"/*; do
        [[ -d "$path" || -L "$path" ]] || continue
        case "${path##*/}" in
            en|en.*|en_[A-Z][A-Z]|en_[A-Z][A-Z].*|C|C.*|POSIX) continue ;;
        esac
        case "$path" in
            /usr/share/locale/locale.alias|/usr/share/locale/l10n|/usr/share/doc/HTML/common|/usr/share/man/man*|/usr/share/speech-dispatcher/locale/base) continue ;;
        esac
        rm -rf -- "$path"
    done
done
printf 'Outpost branding and English-only cleanup complete.\n'
