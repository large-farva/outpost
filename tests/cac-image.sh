#!/usr/bin/env bash
set -euo pipefail
[[ $EUID != 0 ]] || { printf 'Run the container as an unprivileged user.\n' >&2; exit 1; }
rpm -q okular firefox glibc-langpack-en google-noto-sans-cjk-vf-fonts
for package in firefox-langpacks glibc-all-langpacks \
    google-noto-sans-mono-cjk-vf-fonts google-noto-serif-cjk-vf-fonts; do
    if rpm -q "$package" >/dev/null 2>&1; then
        printf 'Unexpected image package: %s\n' "$package" >&2
        exit 1
    fi
done
locales=$(locale -a)
for required in C C.utf8 POSIX en_US.utf8; do
    grep -Fxq "$required" <<< "$locales" || { printf 'Missing locale: %s\n' "$required" >&2; exit 1; }
done
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
test_home=$(mktemp -d)
trap 'rm -rf -- "$test_home"' EXIT
export HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config"
mkdir "$HOME/profile"
cac-nss-setup
cac-nss-setup
cac-pdf-setup
cac-pdf-setup
for attempt in 1 2; do
    MOZ_DISABLE_CONTENT_SANDBOX=1 timeout --kill-after=3s 40s firefox \
        --headless --no-remote --profile "$HOME/profile" \
        --screenshot "$HOME/firefox.png" about:blank > "$HOME/firefox.log" 2>&1 || {
        cat "$HOME/firefox.log"
        exit 1
    }
    modules=$(modutil -list -dbdir "sql:$HOME/profile")
    [[ $(grep -c 'library name:.*p11-kit-proxy' <<< "$modules") == 1 ]]
    if grep -qi 'Unable to add security device' "$HOME/firefox.log"; then
        cat "$HOME/firefox.log"
        exit 1
    fi
    test -s "$HOME/firefox.png"
    printf 'PASS: Firefox start %s, one system CAC provider\n' "$attempt"
done
printf 'PASS: English locales, CJK Sans fallback, RPM Firefox/Okular, and repeated CAC setup; hardware authentication not tested\n'
