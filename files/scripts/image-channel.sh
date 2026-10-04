#!/usr/bin/env bash
set -euo pipefail

[[ -d ${CONFIG_DIRECTORY:-/nonexistent}/system ]] || { printf 'Run inside an image build.\n' >&2; exit 1; }
case "${IMAGE_NAME:-}" in
    outpost) channel=production ;;
    outpost-testing) channel=testing ;;
    outpost-personal) channel=personal ;;
    *) printf 'Unknown Outpost image name.\n' >&2; exit 1 ;;
esac

source_key="/etc/pki/containers/$IMAGE_NAME.pub"
[[ -s "$source_key" ]] || { printf 'Signing module public key is missing.\n' >&2; exit 1; }
# Keep this path stable when switching back to older production deployments.
key=/etc/pki/containers/outpost.pub
[[ "$source_key" == "$key" ]] || install -m 0644 "$source_key" "$key"
metadata=/usr/share/outpost/image-info.json
updated=$(mktemp)
trap 'rm -f -- "$updated"' EXIT
jq --arg name "$IMAGE_NAME" --arg channel "$channel" \
    '."image-name" = $name | ."image-ref" = ("ghcr.io/large-farva/" + $name) | ."image-channel" = $channel' \
    "$metadata" > "$updated"
install -m 0644 "$updated" "$metadata"

# All channels use the same public key; each signature must match its repository.
policy=/etc/containers/policy.json
jq --arg key "$key" '
    {type: "sigstoreSigned", keyPath: $key, signedIdentity: {type: "matchRepository"}} as $rule |
    .transports.docker["ghcr.io/large-farva/outpost"] = [$rule] |
    .transports.docker["ghcr.io/large-farva/outpost-testing"] = [$rule] |
    .transports.docker["ghcr.io/large-farva/outpost-personal"] = [$rule]
' "$policy" > "$updated"
install -m 0644 "$updated" "$policy"
for image in outpost outpost-testing outpost-personal; do
    # Match the signing module's filenames so each scope is defined once.
    cat > "/etc/containers/registries.d/large-farva-$image.yaml" <<REGISTRIES
docker:
  ghcr.io/large-farva/$image:
    use-sigstore-attachments: true
REGISTRIES
done
