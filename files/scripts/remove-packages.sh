#!/bin/bash
set -ouex pipefail

rpm-ostree override remove \
  gnome-extensions-app \
  vim \
  tmux \
  gnome-shell-extension-background-logo \
  gnome-backgrounds \
  fedora-bookmarks \
  || true
