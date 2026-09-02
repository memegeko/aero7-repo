# Windows 7 Comparison Report

Last updated: 2026-08-17

This report records the completed high-priority comparison batch. It does not claim that the full system-wide audit is finished; remaining areas are listed at the end.

## Desktop

**Windows 7:** Clean wallpaper, Windows-style desktop menu, no shell watermark.

**Aero7 before:** A yellow Aero7 watermark remained visible in the lower-right corner. The no-edit-mode shell work already suppressed Plasma edit actions.

**Aero7 after:** The containment no longer creates the watermark component. The taskbar glass is lighter and less saturated. Existing Windows-style desktop/taskbar context handling is preserved.

**Status:** Pass for watermark and color batch.

**Screenshot:** `comparison/aero7/desktop-after.png`

**Remaining limitation:** A full reference capture of desktop selection, drag/drop, icon grid and every submenu is still pending.

## Taskbar

**Windows 7:** Pale blue glass, compact running buttons, Windows-owned taskbar menus.

**Aero7 before:** Panel blue was overly strong. Earlier project work had already removed Edit Mode and Plasma panel-management actions.

**Aero7 after:** Panel background gradients are softened. No edit-mode code was restored. File Explorer and shell links still use Aero7 surfaces.

**Status:** Pass for requested color and no-edit regression; full Jump List/thumbnail state matrix pending.

## Start

**Windows 7:** Pinned applications appear once; recent/frequent rows do not repeat them. The user tile floats above the glass frame.

**Aero7 before:** File Explorer appeared up to three times, the fallback avatar could be blank/generic in the wrong style, and clicking it could expose a KDE settings route.

**Aero7 after:** File Explorer launcher IDs are canonicalized and recent rows are deduplicated. The user tile uses AccountsService or an Aero7 silhouette and opens Aero7 User Accounts. The glass gradient and spacing are tuned.

**Status:** Pass in the Aero7 VM.

**Screenshot:** `comparison/aero7/start-menu-after.png`

**Remaining limitation:** The activity ranking backend is still KDE Activity data, intentionally hidden behind the Aero7 UI.

## Explorer

**Windows 7:** Computer is a native Explorer location with drive groups, capacity bars and only user-facing devices.

**Aero7 before:** Computer opened a separate dialog, exposed raw Linux mounts such as `/run`, `/tmp`, `/boot` and systemd credential mounts, and direct `computer:` navigation could show a KIO error.

**Aero7 after:** Computer is a stacked central File Explorer surface. Direct command-line/Start launches are intercepted before KIO, Places activates the same surface, and returning to a drive restores the normal file view. Only `/` and user-mounted removable media are shown, with Windows-style labels, capacity bars and truthful Linux capacity data.

**Status:** Pass in the Aero7 VM, including direct `dolphin aero7computer:/` launch.

**Screenshot:** `comparison/aero7/computer-after.png`

**Remaining limitation:** The internal breadcrumb scheme is Aero7-owned rather than a real KIO protocol.

## Libraries

No behavior was removed. The existing Documents/Music/Pictures/Videos navigation remains available. Multi-location properties and default-save-location comparison are open for the next batch.

## Recycle Bin

Not changed in this batch. Empty/full state, restore-all, permanent-delete and Windows column comparisons remain open.

## Dialogs

Not changed in this batch. The common item dialog, conflicts, authentication and file-operation progress need a dedicated paired run.

## Control Panel

**Windows 7:** Large Icons shows 45 applets in alphabetical rows across five columns with colored icons. Screen Resolution uses a compact monitor page with Detect, Identify and apply controls.

**Aero7 before:** Large Icons showed 71 internal Linux settings in three text-heavy columns, several icons were absent, and the View-by popup could be black. Display exposed a large backend-centric form with refresh-rate duplicates and extra controls.

**Aero7 after:** The public all-items view is an exact 45-entry routed inventory in five columns. The internal settings catalog remains available for search without leaking into the visible applet count. Aero7 explicitly uses its installed icon theme and the View-by popup is white. Display now presents the Windows layout first, deduplicates resolution dimensions, and keeps orientation/scale/multi-display controls behind Advanced settings while retaining the KScreen backend and rollback logic.

**Status:** Pass for requested structure and live backend.

**Screenshots:** `comparison/aero7/control-panel-large-icons-after.png`, `comparison/aero7/display-after.png`, `comparison/aero7/display-resolutions-after.png`

**Remaining limitation:** The resolution popup is a standard combo list rather than Windows 7's custom High/Low slider.

## Windows, gadgets, shortcuts and applications

This batch retained the existing Aero7 titlebars, gadgets, shell shortcuts and Snipping Tool implementation. They were smoke-observed during VM use but not exhaustively re-compared against every state in the specification.

## Verification

- `linux-control-panel 0.1.0-19`: package build succeeded; six package tests pass, including the exact 45-item invariant and Display deduplication.
- `aero7-dolphin 25.12.3-9`: source and package builds succeeded; direct Computer launch and Places activation verified in the VM.
- `aerothemeplasma-desktop-git 6.7.0_742.r9c2d850-29`: package build succeeded; changed QML passes `qmllint`; watermark removal and Start deduplication verified in the VM.
- Repository source lock and validation pass.
- Temporary ISO builder adapter tests pass.
- The final temporary ISO embeds the tested r29/r19/r9 packages, passes its SquashFS and SHA-256 checks, preserves BIOS/UEFI boot metadata, and cold-boots to the normal Aero7 installer in a clean QEMU VM.

## Open whole-system comparison work

The full specification remains open for paired reference captures and exhaustive testing of: Jump Lists, grouped thumbnails and Peek; tray/network/volume/clock flyouts; notifications; Libraries properties; Recycle Bin; file/folder properties; Open/Save/Choose Folder dialogs; copy/move/delete/conflict failures; every Control Panel page; active/inactive/maximized decorations; Snap/Shake/Alt+Tab/Flip 3D; gadget gallery interactions; all context menus; the keyboard shortcut matrix; and both Snipping Tool workflows.
