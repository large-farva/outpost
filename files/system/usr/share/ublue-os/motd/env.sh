#!/usr/bin/env sh

export MOTD_IMAGE_NAME="$(jq -rc '."image-ref"' "${MOTD_IMAGE_INFO_FILE:-/usr/share/ublue-os/image-info.json}" | sed 's@ostree-image-signed:docker://@@')"

export MOTD_IMAGE_TAG="$(jq -rc '."image-tag"' "${MOTD_IMAGE_INFO_FILE:-/usr/share/ublue-os/image-info.json}")"