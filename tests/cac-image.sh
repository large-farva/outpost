#!/usr/bin/env bash
# Run inside a disposable Outpost container without a reader or network access.
set -euo pipefail
[[ $EUID != 0 ]] || { printf 'Run the container as an unprivileged user.\n' >&2; exit 1; }
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
printf 'PASS: repeated NSS and Okular setup; hardware authentication not tested\n'
