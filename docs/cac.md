# When a CAC stops working

Run `cac-check` as your desktop user, without sudo. It checks reader detection,
card insertion, OpenSC token access, trust, and application configuration separately.
Each warning includes a next step. No helper asks for a PIN.

## Try recovery

Choose **Fix CAC connection** in `outpost` or `cac-help`, or run `cac-recover`.
Save your work and fully quit Firefox and Okular when prompted. Recovery restarts
the PC/SC service, checks the shared certificate database, and asks you to reinsert
the card. Restarting that service interrupts smart-card sessions for all users.

Open RPM Firefox again and retry the site. Choose the authentication certificate
for sign-in. If the PIN is rejected repeatedly, stop and contact card support.

## If recovery does not help

- **No reader:** reconnect it, try another USB port, and run `reader-list`.
- **Reader found, no card:** check insertion and try the card again. `scan` monitors
  insertion and removal events. Then press Ctrl+C to stop it.
- **Card found, no token:** save a report. The reader can detect a card even when
  OpenSC cannot use it.
- **Firefox cannot see the card:** use RPM Firefox, then open `about:policies`.
  Check for policy errors and an active `SecurityDevices` entry. In Settings,
  search for **Security Devices** and check that the card appears. The shared
  `~/.pki/nssdb` database alone does not confirm Firefox's configuration.
- **One website fails:** record its error and whether other CAC sites work. Check
  the clock, certificate expiry, and the certificate chosen for sign-in. A local
  reader check cannot diagnose a site's account or certificate requirements.

`cac-log` shows the reader-service journal. `cac-certs` shows card certificate
information. These commands can expose identifying details. Do not paste their
full output into a public issue without reviewing it.

## Save a report

Run `cac-report`. It saves a private file under `~/.local/state/outpost/` (or
`$XDG_STATE_HOME/outpost/`). The report includes check results, package versions,
and the booted deployment checksum. It excludes raw logs, certificate identities,
reader serials, and Firefox profile paths. Nothing is uploaded. Review it before
sharing, and include the steps that triggered the problem.

A failed diagnostic still produces a report and returns a nonzero exit status.
The checks do not attempt login, validate the card's certificates, or test a PIN.

## What the checks mean

A reader is the USB device and a token is how the smart-card software sees the card.
Detecting the reader does not prove that the card is inserted or usable.
The checks also inspect the reader service, clock synchronization, DoD trust
anchors, Firefox's policy file, and the shared certificate database used for
Okular setup.

A service that starts on demand can be idle while its socket is active. That alone
is not a failure. If a probe times out, the check reports it and continues with
other diagnostics rather than waiting indefinitely.

Checking Firefox's policy file does not confirm that the running browser loaded
the policy. Use `about:policies` after restarting Firefox to check its active policy
and errors. Never delete a Firefox profile or certificate database as a first
troubleshooting step. It can contain unrelated certificates and settings.

## Certificate setup

`cac-nss-setup` checks the shared database under `~/.pki/nssdb` and registers a
provider when missing. It preserves existing certificates. It does not reset a
card PIN or repair an expired certificate. For Okular, use `cac-pdf-setup` to also
select the database in the application. See [Sign a PDF](pdf-signing.md).

Firefox uses Mozilla's [SecurityDevices policy](https://firefox-admin-docs.mozilla.org/reference/policies/securitydevices/)
to request the system provider at startup. Adding a provider repeatedly by hand
can leave duplicate certificate choices. If that happens, record what is listed
in Firefox's Security Devices and ask for help before removing entries.
