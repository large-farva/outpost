#!/usr/bin/env bash
set -euo pipefail
recipe=recipe.yml
publish=false
case "${REF:-}" in
    refs/heads/main)
        case "${EVENT_NAME:-}" in push|workflow_dispatch|schedule) publish=true ;; esac ;;
    refs/heads/testing)
        recipe=testing.yml
        case "${EVENT_NAME:-}" in push|workflow_dispatch) publish=true ;; esac ;;
esac
if [[ ${EVENT_NAME:-} == pull_request && ${BASE_REF:-} == testing ]]; then
    recipe=testing.yml
fi
printf 'recipe=%s\npublish=%s\n' "$recipe" "$publish"
