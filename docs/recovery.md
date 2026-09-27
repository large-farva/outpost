# Roll back an OS update

Choose **Rollback** in `outpost`, or run `outpost-rollback`. The menu lists saved
OS deployments, including pinned deployments. Select one, review its version and
image origin, and confirm to use it on the next boot. **No** is selected by default.
The current deployment stays available, and the helper does not reboot for you.
If no older deployment is saved, there is nothing to select.

A pending deployment blocks the selector. Finish that update by rebooting, or
explicitly cancel it using the commands below. Rollback never discards it for you.

## Manual rollback

Run `rpm-ostree status` to see the booted, pending, and previous deployments.
If an update is pending, remove it first with `sudo rpm-ostree cleanup --pending`,
then check the status again.

If a previous deployment is available:

```bash
sudo rpm-ostree rollback
systemctl reboot
```

Save your work before rebooting. If the desktop will not start, select the
previous deployment from the boot menu instead.

Before testing an image, preserve the working deployment:

```bash
sudo ostree admin pin booted
```

Rollback changes the OS deployment. It does not restore your home directory,
Flatpaks, Homebrew packages, or Distrobox containers. Keep backups of personal files. Local `/etc`
changes may survive image updates; compare a troublesome configuration with its
image default under `/usr/etc` before changing it.

Run `outpost-rollback --help` for these instructions without changing the system.
See the [rpm-ostree administrator handbook](https://github.com/coreos/rpm-ostree/blob/main/docs/administrator-handbook.md).
