# Everyday use

## Open the tools

Launch **Outpost** from the application menu or run `outpost` in a terminal. Use
the menu to check system status, update, troubleshoot a CAC, configure PDF signing,
set up Homebrew, switch image channels, or select a saved OS deployment.

The terminal menu uses Gum when available and a numbered menu otherwise. After a
command finishes, press Enter to return. Each screen replaces the previous menu.
Your terminal scrollback stays available. Choose **Back** in the CAC menu or
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
installed, followed by optional Distrobox updates. Download and installation progress remains visible. The final summary
lists each stage's result and how long it took.

A failed stage does not stop independent stages. Read the error above the summary,
fix the cause, and run `update` again. A skipped optional tool does not mean the OS
update failed. Ctrl+C stops remaining stages. Changes already completed remain
applied.

Run updates as your desktop user. If launched through sudo, the helper runs user
updates for the invoking account. A direct root login skips user Flatpaks,
Homebrew, and Distrobox.

### When to reboot

A pending OS deployment needs a reboot to become active. Save your work, then run:

```bash
systemctl reboot
```

The updater never reboots automatically. “No pending deployment” only describes
the local deployment state. It doesn't tell you whether the update check succeeded,
so look at the OS stage result too. `rpm-ostree status` shows the deployments directly.

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
your account password for setup. This is not your CAC PIN.

After installation, open a new terminal and check:

```bash
brew --version
```

The `update` command upgrades installed Homebrew packages when it finds Homebrew.
If setup reports that Homebrew is installed but `brew` is not found, try a new
login session and keep the setup output when asking for help.

## Distrobox containers

System status lists your Distrobox containers with their names, states, and images.
If containers are found during an update, Outpost asks whether to update all of
them. Choose **No** to skip them. Choosing **Yes** runs `distrobox upgrade --all`
with native package-manager output. Stopped containers may be started.

Only the invoking user's containers are included, not rootful containers.
Redirected or unattended updates skip this stage because there is no visible
confirmation prompt. To update containers separately:

```bash
distrobox list --no-color
distrobox upgrade --all
```

## Switch image channels

Choose **Rebase** in Outpost or run `rebase`. It offers to switch from production
to testing or from testing back to production. The helper shows the target and asks for
confirmation, with **No** selected by default. Testing may include unfinished
changes that affect CAC access.

Resolve any pending OS deployment first. After a successful rebase, save your work
and reboot. The helper uses signed images and will not switch an unrecognized
image origin. See [testing images](testing.md) for preparation, signature setup
on older installations, and manual commands.
