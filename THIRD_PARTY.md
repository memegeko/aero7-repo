# Third-party packages, licences, and trademarks

This document is the central licence and provenance index for packages built by
the Aero7 package repository. It supplements the licence files installed by the
individual packages and does not replace their upstream terms.

## Independent-project and trademark notice

Aero7 is an independent project and is not affiliated with, authorized,
sponsored, endorsed, or approved by Microsoft Corporation. Windows and other
Microsoft product names are trademarks of the Microsoft group of companies.
Microsoft trademarks are used only for truthful, descriptive references to an
upstream project's design target. No Microsoft sponsorship or compatibility
certification is claimed.

## Core desktop packages

| Package | Upstream or source | Declared software licence | Aero7 policy |
| --- | --- | --- | --- |
| `aeroshell-libplasma-git` | `https://gitgud.io/aeroshell/libplasma` | LGPL-2.0-or-later | Pinned/reviewed package recipe |
| `aeroshell-workspace-git` | `https://github.com/aeroshell-desktop/aeroshell-workspace` | AGPL-3.0-or-later | Pinned/reviewed package recipe |
| `aeroshell-kwin-components-git` | `https://github.com/aeroshell-desktop/aeroshell-kwin-components` | AGPL-3.0-or-later | Pinned/reviewed package recipe |
| `aerothemeplasma-desktop-git` | `https://github.com/memegeko/aerothemeplasma` | AGPL-3.0-or-later, plus per-directory notices | Aero7 fork replaces runtime Microsoft logos only; screenshots and non-logo resources are retained |
| `aero7-computer-management-git` | `https://github.com/memegeko/aero7-computer-management` | MIT | Aero7-native administration console and Start-menu module entries |
| `aerothemeplasma-icons-git` | `https://gitgud.io/aeroshell/atp/aerothemeplasma-icons` | AGPL-3.0-or-later software notice; upstream also attributes relevant visual assets to Microsoft | Retained by project-owner decision; exact revision and upstream notices are installed with the package |
| `aerothemeplasma-sounds-git` | `https://gitgud.io/aeroshell/atp/aerothemeplasma-sounds` | AGPL-3.0-or-later software notice; upstream also attributes relevant sound assets to Microsoft | Retained by project-owner decision; exact revision and upstream notices are installed with the package |
| `aeroshell-smod-git` | `https://gitgud.io/aeroshell/smod` | AGPL-3.0-or-later | Pinned/reviewed package recipe |
| `uac-polkit-agent-git` | `https://github.com/aeroshell-desktop/uac-polkit-agent` | GPL-3.0-or-later | Pinned/reviewed package recipe |

The AGPL notices in the icon, sound, and desktop repositories do not by
themselves grant rights to material those upstream projects attribute to
Microsoft. Retaining a package and its notices is not a statement that the
package is free of third-party rights. A public distributor remains responsible
for obtaining any permissions required for its intended use.

## Aero applications

| Package | Source | Declared licence |
| --- | --- | --- |
| `aero7-qt` | Aero7-owned compatibility layer | MIT |
| `aero7-dolphin` | `https://gitgud.io/atmk/dolphin-aero` plus Aero7 patches | LGPL-2.0-or-later |
| `aero7-gwenview` | `https://gitgud.io/atmk/gwenview-aero` plus Aero7 patches | GPL-2.0-or-later and LGPL-2.0-or-later |
| `aero7-kolourpaint` | KDE KolourPaint/SARibbon fork plus Aero7 patches | GPL-2.0-or-later, LGPL-2.0-or-later, and MIT |
| `linux-control-panel` | `https://github.com/actuallyaridan/linux-control` plus Aero7 patches | GPL-3.0-or-later |
| `linux-devmgmt` | `https://github.com/actuallyaridan/linux-devmgmt` | MIT |
| `tuxmanager` | `https://github.com/benapetr/TuxManager` | GPL-3.0-or-later |
| `aero7-gadgets` | Aero7-owned source | MIT |
| `execbin` | `https://gitgud.io/catpswin56/execbin` plus Aero7 artwork replacements | AGPL-3.0-or-later |
| `linver` | `https://gitgud.io/wackyideas/linver` plus Aero7 branding replacements | AGPL-3.0-or-later |
| `winxplorer` | `https://gitgud.io/catpswin56/winxplorer` | GPL-3.0-or-later; optional and not installed by the ISO |

## Package requirements

- Source revisions and recipe hashes are recorded in
  `manifests/upstream-lock.json`.
- Required upstream licence and attribution files must be installed under
  `/usr/share/licenses/<package>/`.
- Patches must preserve per-file SPDX identifiers and upstream copyright
  notices.
- Proprietary fonts, executable files, or additional Microsoft artwork must not
  be added without a separate, documented project-owner decision and rights
  review.

Upstream and Aero7 screenshots remain unchanged until the public-release
screenshot pass. They are documentation, not reusable artwork.
