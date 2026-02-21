#!/usr/bin/env bash
# Shared UI and utility functions for Outpost commands.

have() { command -v "$1" >/dev/null 2>&1; }

dim()  { gum style --foreground 244 "$*"; }
ok()   { gum style --foreground 42  --bold "✓"; }
warn() { gum style --foreground 214 --bold "!"; }
bad()  { gum style --foreground 196 --bold "✗"; }

log_info()  { gum log --level info "$@"; }
log_warn()  { gum log --level warn "$@"; }
log_error() { gum log --level error "$@"; }

line() {
  local icon="$1"; shift
  printf '%s %s\n' "$icon" "$*"
}

hdr() {
  gum style --border rounded --padding "0 1" --margin "0 0 1 0" \
    --border-foreground 68 --foreground 68 --bold "$1"
}

spin() {
  local title="$1"; shift
  gum spin --spinner points --spinner.foreground="68" --title "$title" -- "$@"
}

section() {
  gum style --foreground 15 --bold --margin "0 0 0 2" "$1"
}

box() {
  gum style --border rounded --padding "0 1" --border-foreground 244
}

accent() {
  gum style --foreground 68 --bold "$*"
}

confirm() {
  gum confirm --selected.background="68" "$@"
}

choose() {
  gum choose --cursor.foreground="75" --selected.foreground="68" "$@"
}

input() {
  gum input --cursor.foreground="68" --prompt.foreground="68" "$@"
}

pager() {
  gum pager --border-foreground="68" "$@"
}
