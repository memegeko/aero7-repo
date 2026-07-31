# Aero7 Package Repository

Signed binary Arch Linux package repository infrastructure for Aero7-shell.

This repository is alpha infrastructure. It is intended to make Aero7-shell
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
- `linux-devmgmt`
- `tuxmanager`
- `aero7-qt`
- `aero7-dolphin` (provides `dolphin`)
- `aero7-gwenview` (provides `gwenview`)
- `linux-control-panel`
- `aero7-kolourpaint` (provides `kolourpaint`)
- `aero7-gadgets` (provides `win-gadgets`)
- `winxplorer`
- `execbin`
- `linver`

It does not build or publish X11 Plasma packages.

## Current Status

The first complete alpha core package set has been built, signed, deployed to
GitHub Pages, and install-tested from the qemu-mcp VM through Aero7-shell.

Nine companion application recipes are now included as beta candidates. Their
exact upstream revisions are pinned, all source patches apply cleanly, and all
seven compiled GUI applications pass isolated startup tests. All nine
companion packages also pass local `makepkg` builds without sudo, including a
packaged-binary path scan. Promotion still requires the normal privileged
clean-chroot build, signing pass, and fresh-VM transaction test on the
repository builder.

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
- [First build report](docs/FIRST-BUILD-REPORT.md)
- [Companion application packaging audit](docs/COMPANION-APP-AUDIT.md)

## License

Repository scripts and documentation are licensed under the MIT License.
Imported package recipes remain under their upstream packaging and project
licenses; see [THIRD_PARTY.md](THIRD_PARTY.md).
