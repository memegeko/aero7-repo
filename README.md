<p align="center">
  <img src="assets/branding/aero7-companion.png" width="150" alt="Aero7 logo">
</p>

# Aero7 Package Repository

Signed binary Arch Linux package repository infrastructure for Aero7-shell.

This repository is beta infrastructure. It is intended to make Aero7-shell
installation faster by publishing a signed set of precompiled Aero packages
and selected companion applications for current Arch Linux x86_64 systems.

## Package Set

The repository builds the Aero7 core and reviewed companion recipes under
these package names:

- `aeroshell-libplasma-git`
- `aeroshell-workspace-git`
- `aeroshell-kwin-components-git`
- `aerothemeplasma-icons-git`
- `aerothemeplasma-sounds-git`
- `aeroshell-smod-git`
- `uac-polkit-agent-git`
- `aerothemeplasma-desktop-git`
- `aero7-computer-management-git`
- `linux-devmgmt`
- `tuxmanager`
- `aero7-qt`
- `aero7-file-explorer` (provides `dolphin` and the `aero7-dolphin` compatibility launcher)
- `aero7-gwenview` (provides `gwenview`)
- `linux-control-panel`
- `aero7-kolourpaint` (provides `kolourpaint`)
- `aero7-gadgets` (provides `win-gadgets`)
- `aero7-desktop` (session, migration, recovery, compatibility metadata, and shell integration)
- `winxplorer`
- `execbin`
- `linver`

It does not build or publish X11 Plasma packages.

## Current Status

The 21-package beta source manifest includes the updateable Aero7 Desktop,
native Gadgets 3 runtime, separate Aero7 Computer Management console, and its
searchable administration-module shortcuts. Packages are built
in a clean Arch chroot, signed, and validated as one complete repository set.
The existing 20-package Beta 1 endpoint remains online, while publication of
the new 21-package set is frozen until the explicitly approved final release.

The reviewed companion application recipes are included in the signed beta set. Their
exact upstream revisions are pinned, all source patches apply cleanly, and all
compiled GUI applications pass isolated startup tests. All companion packages
pass local `makepkg` builds without sudo, a packaged-binary
path scan, and the repository's clean-chroot build and signing checks.

Sevulet is intentionally not packaged because its source and redistributable
license could not be obtained.

Signing fingerprint: `72C79ABBBBE96446DD3324042694BFE1090F4FD6`

## Pacman Configuration

The published pacman endpoint is:

```ini
[aero7]
SigLevel = Required DatabaseRequired
Server = https://memegeko.github.io/aero7-repo/$arch
```

Do not use `SigLevel = Never` or `TrustAll`.

## Documentation

- [Builder VM](docs/BUILDER-VM.md)
- [Building](docs/BUILDING.md)
- [Signing](docs/SIGNING.md)
- [Publishing](docs/PUBLISHING.md)
- [Recovery](docs/RECOVERY.md)
- [Update policy](docs/UPDATE-POLICY.md)
- [KDE stable downstream strategy](docs/KDE-DOWNSTREAM-STRATEGY.md)
- [First build report](docs/FIRST-BUILD-REPORT.md)
- [Companion application packaging audit](docs/COMPANION-APP-AUDIT.md)

## License

Repository scripts and documentation are licensed under the MIT License.
Imported package recipes remain under their upstream packaging and project
licenses; see [THIRD_PARTY.md](THIRD_PARTY.md).

Aero7 is an independent project and is not affiliated with, authorized,
sponsored, endorsed, or approved by Microsoft Corporation. Windows and other
Microsoft product names are trademarks of the Microsoft group of companies.
