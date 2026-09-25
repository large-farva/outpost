# Development recommendations

Outpost's next priority should be a release process that catches CAC regressions
before they reach everyday users. The proposals below are separate from the
features currently included in the image.

## Test releases before promoting them

Keep development on a testing branch and require checks before merging to `main`.
The workflow in this branch builds without publishing unless it runs on `main`.
Repository branch protection and required reviews still need to be configured in
GitHub; workflow changes alone do not enforce them.

For installable test images, use a separate package such as `outpost-testing` with
its own documented signing and rebase path. After a VM and hardware test passes,
promote the exact tested image digest to the production channel instead of
rebuilding it against newer packages. Keep dated releases for recovery.

Bluefin separates stable releases from faster-moving test streams. That release
pattern is useful for Outpost, though the current `latest` tag should keep its
existing meaning until a migration is planned. See
[Bluefin's update streams](https://docs.projectbluefin.io/administration/#streams-and-throttle-settings).

## Add a repeatable CAC release check

Record Firefox authentication and Okular signing results for each candidate image.
Include at least one supported reader, card removal and reinsertion, a canceled PIN
prompt, and a reboot. Track the image digest and Firefox, OpenSC, NSS, and Poppler
versions so regressions can be narrowed down.

Add a booted VM check to CI for login services, desktop startup, and installed
commands. Keep real-card tests as a release requirement: command stubs and container
checks cannot exercise the card or reader. The current checklist is in
[validation notes](validation.md).

## Make rollback and diagnostics easy to find

Add recovery instructions to the Outpost menu: how to inspect the booted and
pending deployments, choose a previous deployment, and preserve a known-good
installation before testing an image. Test the instructions in an Outpost VM
before adding a one-click action.

A local diagnostic report would also help. It should collect image and package
versions, reader detection, service status, and relevant logs. Let the user review
and save the report. Redact personal certificate details and avoid automatic
uploads. Bluefin's administration tools offer examples of update, rebase, and
local-configuration helpers:
[system commands](https://docs.projectbluefin.io/administration/#system-commands).

## Track dependencies and trust updates

Pin each action to a full commit SHA and use reviewed dependency-update pull
requests. Give validation jobs read-only tokens and keep publishing credentials
in a release environment with required approval. These are covered in
[GitHub's workflow security guidance](https://docs.github.com/en/actions/reference/security/secure-use).
Consider pinning BlueBuild module versions and the base image digest for each
release candidate, with an update process that keeps security fixes moving.
An SBOM, build provenance, and vulnerability reports would make releases easier
to audit. A passing scanner should complement functional tests, not replace them.

Track the DoD bundle version, download source, and certificate expiry dates.
Checksums detect changed files; they do not prove that the bundled certificates
are current. Review official bundle updates, verify both copies, and test Firefox
and Okular before promotion.

## Keep the host focused

Use host RPMs where hardware or system integration requires them, especially the
CAC stack, Firefox, and Okular. Prefer Flatpaks for other desktop apps, Homebrew for
optional CLI tools, and Distrobox for development environments. This follows
[Bluefin's package guidance](https://docs.projectbluefin.io/administration/#local-layering).
Review the existing selection before moving or removing any application.

Keep the Outpost branding, but reduce divergence from upstream KDE code over time.
Small configuration overrides are easier to carry through Plasma updates than
copied login and logout components. Any replacement should preserve Outpost's
appearance and be tested visually first. Compare the custom `/etc/bashrc` with
Fedora updates periodically so upstream shell fixes are not missed.

## Consider larger changes after release testing is established

- Add firmware update status and a link to the desktop firmware tool. Keep firmware
  installation separate from routine OS updates so its prompts remain visible.
- Evaluate image chunking with measured download sizes, build times, and update
  behavior. BlueBuild documents the available
  [chunking options](https://blue-build.org/reference/github-action/#build_chunked_oci-optional).
- Evaluate `bootc` on a dedicated branch before changing update or rebase commands.
  Bluefin's current administration guide uses it, but Outpost's existing
  rpm-ostree workflow needs its own migration and rollback tests.
- Add an NVIDIA image only when there is hardware available to test its drivers,
  Secure Boot behavior, and upgrades. Separate recipes can share the CAC setup.
