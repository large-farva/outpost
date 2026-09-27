#!/usr/bin/env bash
set -euo pipefail
[[ ${GITHUB_REPOSITORY:-} == large-farva/outpost && ${GITHUB_REF:-} == refs/heads/testing ]] || exit 1
case "${GITHUB_EVENT_NAME:-}" in push|workflow_dispatch) ;; *) exit 1 ;; esac
[[ ${GITHUB_SHA:-} =~ ^[0-9a-f]{40}$ ]] || exit 1
image=ghcr.io/large-farva/outpost-testing
# BlueBuild gives non-default branches commit tags instead of latest.
source="$image:${GITHUB_SHA:0:7}-43"
printf '%s' "$GH_TOKEN" | docker login ghcr.io --username "$GITHUB_ACTOR" --password-stdin
manifest=$(docker buildx imagetools inspect "$source" --format '{{json .Manifest}}')
digest=$(jq -er '.digest | select(test("^sha256:[0-9a-f]{64}$"))' <<< "$manifest")
cosign verify --key cosign.pub "$image@$digest" >/dev/null
docker run --rm --network none --user 1000:1000 --tmpfs /tmp:rw,mode=1777 \
    --volume "$PWD/tests/cac-image.sh:/tmp/test.sh:ro" "$image@$digest" bash /tmp/test.sh
# Copy the manifest within the same repository, preserving its signed digest.
docker buildx imagetools create --prefer-index=false --tag "$image:latest" "$image@$digest"
latest=$(docker buildx imagetools inspect "$image:latest" --format '{{json .Manifest}}')
[[ $(jq -er .digest <<< "$latest") == "$digest" ]]
cosign verify --key cosign.pub "$image:latest" >/dev/null
printf 'Testing image: %s:latest\n\nDigest: %s\n' "$image" "$digest" >> "$GITHUB_STEP_SUMMARY"
