# Everyday use

## Open the tools

Launch **Outpost** from the application menu or run `outpost` in a terminal. Use
the menu to check system status, update, troubleshoot a CAC, configure PDF signing,
set up Homebrew, or read rollback instructions.

The terminal menu uses Gum when available and a numbered menu otherwise. After a
command finishes, press Enter to return. Choose **Back** in the CAC menu or
**Quit** in the main menu to leave.

Each helper also works as a separate command. `outpost --status` prints status
without opening the menu. Redirecting `outpost` to a file does the same:

```bash
outpost --status > outpost-status.txt
```

Status output may include your image origin. Review it before sharing. For CAC
support, `cac-report` produces a report with less identifying information.

## Update

Choose **Update** in Outpost, use the update desktop launcher, or run:

```bash
update
```

Updates run in this order: OS, system Flatpaks, user Flatpaks, then Homebrew if
installed. Download and installation progress remains visible. The final summary
lists each stage's result and how long it took.

A failed stage does not stop independent stages. Read the error above the summary,
fix the cause, and run `update` again. A skipped optional tool does not mean the OS
update failed. Ctrl+C stops remaining stages; changes already completed remain
applied.

Run updates as your desktop user. If launched through sudo, the helper runs user
updates for the invoking account. A direct root login skips user Flatpaks and
Homebrew.

### When to reboot

A pending OS deployment needs a reboot to become active. Save your work, then run:

```bash
systemctl reboot
```

The updater never reboots automatically. “No pending deployment” describes the
local deployment state; it is not proof that an update check succeeded. Look at
the OS stage result as well. `rpm-ostree status` shows the deployments directly.

If an update causes trouble after rebooting, see [recovery](recovery.md).

## Applications

Use Bazaar to browse Flatpak applications. The image also includes tools such as
Warehouse and Flatseal for managing Flatpaks and their permissions. Keep the
included RPM Firefox and Okular for the documented CAC workflows.

`update` handles both system-wide and per-user Flatpaks. To see which applications
are installed in each location:

```bash
flatpak list --system --app
flatpak list --user --app
```

## Homebrew

Homebrew is optional. Choose **Homebrew setup** in Outpost or run `brew-setup`
without sudo. Review the confirmation before installing. The installer may request
your account password for setup; this is not your CAC PIN.

After installation, open a new terminal and check:

```bash
brew --version
```

The `update` command upgrades installed Homebrew packages when it finds Homebrew.
If setup reports that Homebrew is installed but `brew` is not found, try a new
login session and keep the setup output when asking for help.

## Change image tags

Rebasing selects another published image tag. It is different from rolling back
to a deployment already on the machine. Use this only with a tag supplied by an
Outpost release:

```bash
rebase TAG
```

The helper shows the target and asks for confirmation. Reboot after a successful
rebase. With no tag, it selects `latest`. If it cannot determine the image
reference, stop and report that error instead of guessing a registry address.
