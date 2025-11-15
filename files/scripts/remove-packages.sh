#!/bin/bash
set -ouex pipefail

dnf5 remove \
  fedora-bookmarks \
  fedora-chromium-config* \
  gnome-shell-extension-background-logo \
  gnome-shell-extension-launch-new-instance \
  gnome-shell-extension-window-list \
  gnome-tour \
  htop \
  nvtop \
  tmux \
  vim* \
  yelp* \
  || true

# Something is causing the build to delete 400 packages at build time.

# default-fonts* \
# gdouros-symbola-fonts \
# google-noto-naskh-arabic-vf-fonts \
# google-noto-sans* \
# google-noto-serif* \
# jomolhari-fonts \
# julietaula-montserrat-fonts \
# madan-fonts \
# paktype-naskh-basic-fonts \
# rit-meera-new-fonts \
# rit-rachana-fonts \
# sil-padauk-fonts \
# vazirmatn-vf-fonts \

# It's one or more of these font packs.
