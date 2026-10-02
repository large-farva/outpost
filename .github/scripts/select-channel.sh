#!/usr/bin/env bash
set -euo pipefail
image=outpost
publish=false
case "${REF:-}" in
    refs/heads/main)
        case "${EVENT_NAME:-}" in push|workflow_dispatch|schedule) publish=true ;; esac ;;
    refs/heads/testing)
        image=outpost-testing
        case "${EVENT_NAME:-}" in push|workflow_dispatch) publish=true ;; esac ;;
esac
if [[ ${EVENT_NAME:-} == pull_request && ${BASE_REF:-} == testing ]]; then
    image=outpost-testing
fi
sed -i "s/^name: .*/name: $image/" recipes/recipe.yml
printf 'publish=%s\n' "$publish"
