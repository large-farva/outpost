#!/usr/bin/env bash
have() { command -v "$1" >/dev/null 2>&1; }
interactive() { [[ -t 0 && -t 2 ]]; }
# Command substitution redirects stdout, so terminal detection happens first.
OUTPOST_COLOR=0
if [[ -t 1 && ${TERM:-dumb} != dumb && ! ${NO_COLOR+x} ]]; then
    OUTPOST_COLOR=1
fi
styled() {
    local color="$1"; shift
    if ((OUTPOST_COLOR)); then printf '\033[%sm%s\033[0m' "$color" "$*"
    else printf '%s' "$*"; fi
}
dim() { styled '38;5;244' "$*"; printf '\n'; }
ok() { if ((OUTPOST_COLOR)); then styled '1;38;5;42' '✓'; else printf 'OK'; fi; }
warn() { if ((OUTPOST_COLOR)); then styled '1;38;5;214' '!'; else printf 'WARN'; fi; }
bad() { if ((OUTPOST_COLOR)); then styled '1;38;5;196' '✗'; else printf 'ERROR'; fi; }
log_info() { printf 'INFO: %s\n' "$*"; }
log_warn() { printf 'WARN: %s\n' "$*" >&2; }
log_error() { printf 'ERROR: %s\n' "$*" >&2; }
line() { printf '%s ' "$1"; shift; printf '%s\n' "$*"; }
hdr() {
    if ((OUTPOST_COLOR)) && have gum; then
        gum style --border rounded --padding '0 1' --margin '0 0 1 0' \
            --border-foreground 68 --foreground 68 --bold "$1"
    else printf '\n%s\n\n' "$1"; fi
}
section() { printf '\n'; styled '1' "$1"; printf '\n'; }
accent() { styled '1;38;5;68' "$*"; printf '\n'; }
box() {
    if ((OUTPOST_COLOR)) && have gum; then
        gum style --border rounded --padding '0 1' --border-foreground 244
    else cat; fi
}
# A spinner would hide package-manager progress and authentication prompts.
spin() { local title="$1"; shift; section "$title"; "$@"; }
confirm() {
    interactive && [[ -t 1 ]] || { log_warn 'Confirmation requires a terminal.'; return 1; }
    if have gum; then
        local colors=()
        ((OUTPOST_COLOR)) && colors+=(--selected.background=68)
        gum confirm "${colors[@]}" "$@"
    else
        local answer
        printf '%s [y/N] ' "$*" >&2
        read -r answer || return 1
        [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]
    fi
}
# Menu output is captured; stderr still points to the terminal.
choose() {
    interactive || return 1
    if have gum; then
        local colors=()
        ((OUTPOST_COLOR)) && colors+=(--cursor.foreground=75 --selected.foreground=68)
        gum choose "${colors[@]}" --height 12 -- "$@"
    else
        local choice
        PS3='Select a number: '
        select choice in "$@"; do
            [[ -n "$choice" ]] && { printf '%s\n' "$choice"; return; }
        done
        return 1
    fi
}
pause() {
    interactive || return 0
    printf '\nPress Enter to return' >&2
    read -r _ || true
}
run_cmd() {
    local rc=0
    "$@" || rc=$?
    printf '\nExit status: %s\n' "$rc"
    pause
}
deployment_status() {
    local status
    status=$(rpm-ostree status --json) || return 1
    jq -er '
        .deployments | select(type == "array" and length > 0) |
        (.[] | select(.booted) | "Booted: \(.version // .checksum) [\(.origin // "unknown origin")]"),
        (if .[0].booted == false then
            "Pending: \(.[0].version // .[0].checksum) [\(.[0].origin // "unknown origin")]\nReboot required to apply the pending deployment."
        else "No pending deployment (availability has not been checked by this status query)." end)
    ' <<< "$status"
}
