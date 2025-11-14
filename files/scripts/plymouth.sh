#!/usr/bin/env bash
set -oue pipefail

THEME="outpost"

/usr/bin/plymouth-set-default-theme "$THEME"
