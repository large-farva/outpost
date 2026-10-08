#!/usr/bin/env bash
if [ -n "${BASH_VERSION:-}" ]; then
    case "$-" in
        *i*)
            if [[ ${TERM:-dumb} != dumb && ${__OUTPOST_STARSHIP_INITIALIZED:-0} != 1 ]] &&
                command -v starship >/dev/null 2>&1; then
                if outpost_starship_init=$(starship init bash); then
                    eval "$outpost_starship_init"
                    # This marker stays local so nested shells initialize their own hooks.
                    __OUTPOST_STARSHIP_INITIALIZED=1
                fi
                unset outpost_starship_init
            fi
            ;;
    esac
fi
