# Roll back an OS update

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
Flatpaks, or Homebrew packages. Keep backups of personal files. Local `/etc`
changes may survive image updates; compare a troublesome configuration with its
image default under `/usr/etc` before changing it.

These instructions are also available from **Rollback help** in `outpost`.
See the [rpm-ostree administrator handbook](https://github.com/coreos/rpm-ostree/blob/main/docs/administrator-handbook.md).
