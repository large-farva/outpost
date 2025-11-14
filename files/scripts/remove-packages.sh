#!/bin/bash
set -ouex pipefail

dnf5 remove \
  fedora-bookmarks \
  fedora-chromium-config* \
  gdouros-symbola-fonts \
  gnome-shell-extension-background-logo \
  gnome-shell-extension-launch-new-instance \
  gnome-shell-extension-window-list \
  google-noto-naskh-arabic-vf-fonts \
  google-noto-sans* \
  google-noto-serif* \
  htop \
  jomolhari-fonts \
  julietaula-montserrat-fonts \
  madan-fonts \
  nvtop \
  paktype-naskh-basic-fonts \
  rit-meera-new-fonts \
  rit-rachana-fonts \
  sil-padauk-fonts \
  tmux \
  vazirmatn-vf-fonts \
  vim* \
  || true

# Something is causing the build to delete 400 packages at build time. WTF
# gnome-tour \
# yelp* \
# default-fonts* \
