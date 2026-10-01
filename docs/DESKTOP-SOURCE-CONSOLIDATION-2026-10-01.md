# Desktop/theme source consolidation

The following package recipes now share the canonical Aero7 Desktop source at
`56977099a3a3d810801936d0091c322b8b112c30`:

| Package | Source directory | Candidate version |
| --- | --- | --- |
| aero7-desktop | root, `AERO7_BUILD_THEME=OFF` | 0.2.0-44 |
| aerothemeplasma-desktop-git | theme/ | 6.7.0_760-1 |
| aero7-gadgets | companions/aero7-gadgets/ | 3.0.0-29 |
| aero7-internet-explorer | companions/aero7-internet-explorer/ | 0.1.0-8 |

Canonical repository: [Aero7 Desktop](https://github.com/aero7-open-project/aero7-desktop/tree/testing).
The old theme repository is kept public and archived after the verified
migration. Builds no longer need it. Existing package names remain intact, so
installed systems do not need a package rename/removal transaction.

The theme's accepted package overlays, bundled icons, notices and defaults now
live in its source. The old recipe-side assets remain provenance only, as
documented in `packages/aerothemeplasma-desktop-git/INTEGRATED-SOURCE.md`.
Source policy rejects their reapplication and requires all four packages to
share the reviewed GitHub commit. Theme checks run the integrated runtime-layout
and QML/helper tests. Session builds disable the theme to avoid ownership
overlap. Both independently built packages were installed without conflicts in
a disposable 1920×1080 VM; reboot, SDDM, lock/unlock, taskbar, Start/search and
Media Player launch checks passed. Source QA includes 43 combined, 28 theme,
8 gadget and 4 browser-identity tests.

## Existing manifest drift reconciled

Before this pass, full source verification failed on stale fingerprint metadata.
The committed workspace, sound, File Explorer and Control Panel recipes were
not modified by consolidation. Their `.SRCINFO` matches `makepkg` output; the
lock fingerprints are reconciled to those existing committed bytes. Workspace's
lock now also records the GitHub revision already used by its recipe rather
than implying its old AUR recipe is still the complete source description.
No source revision in those four recipes was upgraded by this reconciliation.
The generated dependency order incorporates the dependencies already present
in Programs Center's committed recipe and the consolidated Desktop recipes.

This is a `testing` source/recipe update. It does not dispatch the production
builder, sign/publish binaries, update an ISO or merge a release branch.
Use the normal guarded build-and-release workflow when the candidate is approved.
