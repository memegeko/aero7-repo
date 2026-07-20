# Aero7 Package Repository

Signed binary Arch Linux package repository infrastructure for Aero7-shell.

This repository is alpha infrastructure. It is intended to make Aero7-shell
installation faster by publishing a complete signed set of precompiled Aero
packages for current Arch Linux x86_64 systems.

## Package Set

The repository builds the existing Arch package recipes under their original
package names:

- `aeroshell-libplasma-git`
- `aeroshell-workspace-git`
- `aeroshell-kwin-components-git`
- `aerothemeplasma-icons-git`
- `aerothemeplasma-sounds-git`
- `aeroshell-smod-git`
- `uac-polkit-agent-git`
- `aerothemeplasma-desktop-git`

It does not build or publish X11 Plasma packages.

## Current Status

The repository source, package pins, validation tests, and builder scripts are
being prepared. A published pacman endpoint must not be enabled in Aero7-shell
until a complete package set has been built, signed, deployed, and tested.

Signing fingerprint: `72C79ABBBBE96446DD3324042694BFE1090F4FD6`

## Pacman Configuration

After the repository is published and the signing key fingerprint is finalized,
the intended pacman entry is:

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

## License

Repository scripts and documentation are licensed under the MIT License.
Imported package recipes remain under their upstream packaging and project
licenses; see [THIRD_PARTY.md](THIRD_PARTY.md).
