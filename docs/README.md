# Outpost user guide

Outpost includes the software needed to connect a CAC reader, use CAC websites in
Firefox, and configure Okular for PDF signing. Open **Outpost** from the application
menu, or run `outpost` in a terminal, to find the system and CAC tools.

- [Get started](getting-started.md): install Outpost, switch to signed updates,
  and connect a CAC for the first time.
- [Everyday use](everyday-use.md): update the system, manage applications, use
  Homebrew, and understand the terminal menus.
- [CAC troubleshooting](cac.md): recover a lost connection, interpret checks,
  and save a diagnostic report.
- [Sign a PDF](pdf-signing.md): configure Okular, choose a certificate, and check
  the saved signature.
- [Try the testing image](testing.md): switch channels with signature verification
  and return to production.
- [Recover from an update](recovery.md): use the previous OS deployment and keep
  a working deployment available.

Run Outpost helpers as your normal desktop user. They'll ask for administrator access
when needed. CAC setup and diagnostics need your own user configuration, so do
not launch them with `sudo`.

## Getting help

If you're still having CAC trouble, follow the [report instructions](cac.md#save-a-report)
and [open an issue](https://github.com/large-farva/outpost/issues). Include what you
were trying to do, the error shown, and whether the problem started after an
update. Review diagnostic files before attaching them.

Features described here match this branch. A system running an older image may
not have every helper yet. Run `update` and reboot into the new deployment after
an image containing those features is released.
