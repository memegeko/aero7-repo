# Companion Application Packaging Audit

Audit date: 2026-08-10

This audit tracks applications requested for the Aero7 ISO. Source revisions,
licenses, replacement assets, patches, and package metadata are kept in this
repository. Binary promotion still requires a clean Arch chroot, signed
repository assembly, and a fresh-VM install/rollback transaction.

| Application | Pinned source | Aero7 package | Current result |
| --- | --- | --- | --- |
| Aero Dolphin | `f0500fae7c4aadf75df23300557c0288404c6575` | `aero7-dolphin` | Full Qt 6/KF6 build, staged install, and isolated startup pass with licensed `aero7-qt`; provides and conflicts with `dolphin` |
| Aero Gwenview | `33e15a58e3017ab9a4e01070cc1e3b0138b3892d` | `aero7-gwenview` | Full build, staged install, and startup pass; the custom bitmap control strip was replaced with original code-drawn glass and theme icons |
| Linux Control Panel | `c5c2ce72c656dde172fe2196f3d55f2633643edc` | `linux-control-panel` | Aero7 fork with native NetworkManager, account, appearance, PipeWire/PulseAudio and UPower workflows, UFW logging controls, stale-kernel firewall diagnostics, Network Management and spelling integration; Wallet support is intentionally excluded |
| Aero KolourPaint | `0a0debee63d9902b1dd6dafdddad41f21549c5b7` | `aero7-kolourpaint` | Full build, staged install, and startup pass with MIT SARibbon revision `540624e98a53cff47fc1b0531d9129ae3a7fe6b2` bundled |
| Gadgets | Aero7-owned source | `aero7-gadgets` | Original Plasma 6 Clock, CPU Meter, and Notes widgets pass `qmllint` and a local Arch package build; the asset-heavy upstream bundle is not redistributed |
| WinXplorer | `9d2fae647e1bd9fc7f1dd53f36f8d5e160f4fddc` | `winxplorer` | Full build, staged install, and startup pass after replacing bitmap controls with QML-drawn glass and removing the bundled navigation sound |
| execbin | `6127849ad534b07d44b278b14f2246cf43ada3b9` | `execbin` | Full build, staged install, and startup pass with the refreshed circular Aero7 7 emblem replacing both bundled icons |
| LinVer | `087f2746703d9c885de2e1a4f6360314283703f4` | `linver` | Full qmake build and startup pass with every bundled version-branding resource replaced by the refreshed circular Aero7 7 emblem |
| Sevulet | unavailable | none | Disabled: anonymous source access requests credentials and no redistributable license is available |

## Licensed compatibility layer

The audited applications originally depended on `libAeroQt` revision
`a420c05136733f1709c3db10d14826c8855063d2`. That repository builds, but it
does not contain a repository-wide license and therefore is not packaged.

`aero7-qt` is a clean-room MIT implementation of the small public API surface
used by these applications: application styling, glass/inset windows,
navigation buttons, event listeners, and property binding. It is header-only,
has a CMake package, and includes a compiled CTest smoke test. No source,
bitmap, sound, font, or other resource from `libAeroQt` is present. Readelf
checks confirm the rebuilt applications have no `libAeroQt` runtime linkage.

## Original asset work

The project emblem is documented in
`assets/branding/ASSET-PROVENANCE.md`. Gwenview and WinXplorer now draw their
custom controls in code. The Gadgets collection draws all faces and frames in
QML. execbin and LinVer receive transparent 256-pixel downscales of the
project emblem during packaging. Upstream proprietary resource directories
are deleted in each package's `prepare()` step before compilation.

## Verification completed without sudo

- Exact source revisions cloned and inventoried.
- Every maintained patch applies to an unmodified archive of its pinned
  revision.
- `aero7-qt` CMake build and CTest pass.
- Dolphin, Gwenview, Linux Control Panel, KolourPaint, WinXplorer, execbin,
  and LinVer compile successfully.
- All seven GUI binaries remain alive for a four-second isolated offscreen
  startup observation.
- All six CMake applications stage-install successfully; LinVer's qmake
  executable is produced successfully.
- The three original Gadgets pass `qmllint`.
- Local `makepkg` builds pass for all nine companion packages. The
  Aero KolourPaint package is built without a temporary SARibbon RUNPATH, and
  the final package archives contain no build-root path references.
- Repository validation, lock checks, dependency ordering, `.SRCINFO`
  freshness checks, and shell syntax checks pass for all 19 packages.

`namcap` and the privileged clean-chroot builder were not run on this host
because `namcap` is not installed and this pass intentionally used no sudo.

## Remaining release gate

Run the normal builder workflow, sign the 19-package repository, and install
it in a fresh Aero7 VM. In that VM, verify replacement transactions and
rollback for Dolphin, Gwenview, and KolourPaint; launch all companion desktop
entries under Plasma 6 Wayland; add and remove each Gadget; and confirm that
the repository contains no Sevulet package.
