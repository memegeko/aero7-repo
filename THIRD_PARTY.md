# Third-Party Package Recipes

The package recipes in `packages/` are imported from the Arch User Repository
and pinned in `manifests/upstream-lock.json`.

Imported recipes:

- `aeroshell-libplasma-git`
- `aeroshell-workspace-git`
- `aeroshell-kwin-components-git`
- `aerothemeplasma-icons-git`
- `aerothemeplasma-sounds-git`
- `aeroshell-smod-git`
- `uac-polkit-agent-git`
- `aerothemeplasma-desktop-git`

The package recipes carry narrowly scoped Aero7 compatibility and integration
patches documented beside each PKGBUILD. The AeroThemePlasma desktop recipe
also replaces the SevenStart orb sprites and Welcome/logout watermark with
project-owner-supplied Aero7 artwork while retaining the upstream QML
implementation and AGPL license.

Do not add proprietary Microsoft artwork, logos, sounds, fonts, icons, or other
copyrighted assets.
