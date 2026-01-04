#!/usr/bin/env bash
set -ouex pipefail
umask 022

IMAGE_NAME="outpost"
IMAGE_PRETTY_NAME="Outpost"
IMAGE_LIKE="fedora"
HOME_URL="https://github.com/large-farva/outpost"
DOCUMENTATION_URL="https://github.com/large-farva/outpost"
SUPPORT_URL="https://github.com/large-farva/outpost/issues"
BUG_REPORT_URL="https://github.com/large-farva/outpost/issues"
VERSION="${VERSION:-43}"
LOGO_PATH="/usr/share/pixmaps/outpost.png"

OSRELEASE="/usr/lib/os-release"

set_kv() {
  local key="$1"
  local value="$2"
  if grep -qE "^${key}=" "$OSRELEASE"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$OSRELEASE"
  else
    printf '%s=%s\n' "$key" "$value" >> "$OSRELEASE"
  fi
}

set_kv "NAME" "\"${IMAGE_PRETTY_NAME}\""
set_kv "PRETTY_NAME" "\"${IMAGE_PRETTY_NAME} ${VERSION}\""
set_kv "VARIANT_ID" "${IMAGE_NAME}"
set_kv "ID_LIKE" "\"${IMAGE_LIKE}\""

set_kv "HOME_URL" "\"${HOME_URL}\""
set_kv "DOCUMENTATION_URL" "\"${DOCUMENTATION_URL}\""
set_kv "SUPPORT_URL" "\"${SUPPORT_URL}\""
set_kv "BUG_REPORT_URL" "\"${BUG_REPORT_URL}\""

set_kv "VERSION" "\"${VERSION} (Kinoite base)\""
set_kv "VERSION_CODENAME" "\"outpost\""
set_kv "LOGO" "\"${LOGO_PATH}\""

sed -i "/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d" "$OSRELEASE"

if [[ -f /usr/sbin/grub2-switch-to-blscfg ]]; then
  sed -i "s|^EFIDIR=.*|EFIDIR=\"fedora\"|" /usr/sbin/grub2-switch-to-blscfg || true
fi

set_kv "IMAGE_ID" "\"${IMAGE_NAME}\""
set_kv "IMAGE_VERSION" "\"${VERSION}\""
