#!/usr/bin/env bash
set -euo pipefail
image=outpost
publish=false
case "${REF:-}" in
    refs/heads/main)
        case "${EVENT_NAME:-}" in push|workflow_dispatch|schedule) publish=true ;; esac ;;
    refs/heads/testing|refs/heads/personal)
        image=outpost-${REF##*/}
        case "${EVENT_NAME:-}" in push|workflow_dispatch) publish=true ;; esac ;;
esac
if [[ ${EVENT_NAME:-} == pull_request ]]; then
    case "${BASE_REF:-}" in testing|personal) image=outpost-$BASE_REF ;; esac
fi
sed -i "s/^name: .*/name: $image/" recipes/recipe.yml
printf 'publish=%s\n' "$publish"
