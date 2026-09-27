# Try the testing image

Testing is for checking changes before they reach normal installations. Use a VM
first, then test with a physical CAC if needed. Keep a working deployment available
on any machine used for testing.

| Channel | Image |
| --- | --- |
| Production | `ghcr.io/large-farva/outpost:latest` |
| Testing | `ghcr.io/large-farva/outpost-testing:latest` |

Wait for a successful [testing build](https://github.com/large-farva/outpost/actions?query=branch%3Atesting),
including **Publish signed testing latest tag**, before switching. A failed build
can leave `latest` pointing to an older image. The successful run's summary shows
the published digest.

## Preserve the working OS

Save your work, back up important files, and run:

```bash
rpm-ostree status
sudo ostree admin pin booted
```

If an update is pending, finish it or follow the [recovery guide](recovery.md) to
remove that pending deployment before switching channels. Pinning keeps the OS
deployment available; it does not back up your home directory or applications.

## Check signed access

On an existing Outpost installation, verify the testing image using the installed
Outpost public key:

```bash
cosign verify --key /etc/pki/containers/outpost.pub ghcr.io/large-farva/outpost-testing:latest
```

Continue only if verification succeeds. If the image is missing or access is
denied, check the publishing run and package visibility first. If the public key
or `cosign` is missing, stop and ask for help. Do not switch to an unverified image
to work around a signature error.

## Add trust on older Outpost installations

New images include trust entries for both channels. Check yours:

```bash
jq '.transports.docker["ghcr.io/large-farva/outpost-testing"]' /etc/containers/policy.json
```

If it prints `null`, run the block below once. It backs up the existing policy,
adds the testing address using the installed Outpost key, and enables signature
lookup for that address. Other image policies are preserved. These commands are
for an existing Outpost installation, not a fresh Fedora installation.

```bash
sudo bash <<'SETUP'
set -euo pipefail
key=/etc/pki/containers/outpost.pub
policy=/etc/containers/policy.json
test -s "$key"
test -s "$policy"
backup=$(mktemp /etc/containers/policy.json.outpost-backup.XXXXXX)
cp -p -- "$policy" "$backup"
updated=$(mktemp)
trap 'rm -f -- "$updated"' EXIT
jq --arg key "$key" '
  .transports.docker["ghcr.io/large-farva/outpost-testing"] = [{
    type: "sigstoreSigned",
    keyPath: $key,
    signedIdentity: {type: "matchRepository"}
  }]
' "$policy" > "$updated"
install -m 0644 "$updated" "$policy"
install -d -m 0755 /etc/containers/registries.d
cat > /etc/containers/registries.d/large-farva-outpost-testing.yaml <<'REGISTRY'
docker:
  ghcr.io/large-farva/outpost-testing:
    use-sigstore-attachments: true
REGISTRY
printf 'Previous policy saved to %s\n' "$backup"
SETUP
```

If a testing entry already exists but uses a different key or policy, inspect it
before changing it. Keep the backup path printed by setup. If a later signed
rebase fails, retain the error and ask for help rather than disabling verification.

## Switch to testing

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/large-farva/outpost-testing:latest
```

When the rebase finishes successfully, save your work and reboot:

```bash
systemctl reboot
```

After logging in, run `rpm-ostree status` and confirm the booted deployment points
to `outpost-testing`. Future `update` runs will follow that image. The `rebase`
helper changes tags within the current package; `rebase testing` does not switch
channels.

Run `cac-check`, try the CAC websites you use, and test PDF signing if you need it.
Check card removal/reinsertion and recovery as well. Keep the image digest and a
reviewed `cac-report` with any problem report. A successful build does not prove
that your reader, card, or website works.

## Return to production

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/large-farva/outpost:latest
```

Reboot after the command succeeds, then confirm the booted origin with
`rpm-ostree status`. Future updates will follow production again. To return to the
specific deployment you pinned instead, use the [rollback instructions](recovery.md).

Switching channels does not undo changes to personal files, Flatpaks, Homebrew, or
locally modified `/etc` configuration. Keep the pinned deployment until the system
is working as expected.
