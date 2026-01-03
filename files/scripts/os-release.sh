#!/usr/bin/env bash
set -ouex pipefail

echo "::group:: === outpost-os-release ==="

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

sed -i "s|^NAME=.*|NAME=\"${IMAGE_PRETTY_NAME}\"|" "$OSRELEASE"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"${IMAGE_PRETTY_NAME} ${VERSION}\"|" "$OSRELEASE"
sed -i "s|^VARIANT_ID=.*|VARIANT_ID=${IMAGE_NAME}|" "$OSRELEASE"

sed -i "s|^ID=fedora|ID=${IMAGE_NAME}\nID_LIKE=\"${IMAGE_LIKE}\"|" "$OSRELEASE"

sed -i "s|^HOME_URL=.*|HOME_URL=\"${HOME_URL}\"|" "$OSRELEASE"
sed -i "s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"${DOCUMENTATION_URL}\"|" "$OSRELEASE"
sed -i "s|^SUPPORT_URL=.*|SUPPORT_URL=\"${SUPPORT_URL}\"|" "$OSRELEASE"
sed -i "s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"${BUG_REPORT_URL}\"|" "$OSRELEASE"

sed -i "s|^VERSION=.*|VERSION=\"${VERSION} (Silverblue base)\"|" "$OSRELEASE"
sed -i "s|^VERSION_CODENAME=.*|VERSION_CODENAME=\"outpost\"|" "$OSRELEASE"

if ! grep -q "^LOGO=" "$OSRELEASE"; then
  echo "LOGO=\"${LOGO_PATH}\"" >> "$OSRELEASE"
else
  sed -i "s|^LOGO=.*|LOGO=\"${LOGO_PATH}\"|" "$OSRELEASE"
fi

sed -i "/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d" "$OSRELEASE"

sed -i "s|^EFIDIR=.*|EFIDIR=\"fedora\"|" /usr/sbin/grub2-switch-to-blscfg

echo "IMAGE_ID=\"${IMAGE_NAME}\"" >> "$OSRELEASE"
echo "IMAGE_VERSION=\"${VERSION}\"" >> "$OSRELEASE"

echo "::endgroup::"
