# Aero7 Explorer and shell features

## Explorer

- Windows 7-inspired navigation header and command bar with Organize, Include in library, Share with, Burn, Preview pane and Views.
- Favorites, Libraries, Computer and Network navigation groups.
- Extra Large, Large, Medium, Small, List, Details, Tiles and Content view commands backed by real Dolphin view modes and roles.
- Toggleable preview/information pane and live selection details.
- Computer window populated from mounted volumes, with capacity bars and real free/total-space data.
- Search scoped to the current folder or to every included folder in the active Library.

## Libraries

- One shared, versioned per-user database at `~/.config/aero7/libraries.json`.
- Documents, Music, Pictures and Videos defaults.
- Multiple included folders, offline locations, safe duplicate-name handling, default save location, optimize-for type and navigation-pane visibility.
- Atomic persistence and a merged Explorer/common-dialog view.
- Native Library Properties with Add, Remove, Set save location, Restore Defaults, Apply, OK and Cancel semantics.

## Recycle Bin and Properties

- Desktop Recycle Bin shortcut initialized at sign-in with dynamic trash icon support from the Aero7 desktop theme.
- Real KIO trash, restore selected, restore all and empty operations.
- Aero7 confirmation, immediate-delete and maximum-size settings that affect actual delete behavior.
- Aero7 Recycle Bin Properties and permanent-delete confirmation.
- Aero7 file/folder Properties with General, Security and Details pages; recursive folder size/count, allocated size, timestamps, hidden/read-only attributes, owner/group/mode, MIME type, image dimensions and XDG default-program integration.
- Previous Versions is omitted because no snapshot backend is installed; no fake tab is shown.

## File operations

- Aero7 copy/move progress showing source, destination, current item, progress, remaining files/bytes and speed.
- Small files, large files and recursive directory trees.
- Collision choices: Copy and Replace, Don't Copy, Copy but keep both, and apply to subsequent conflicts.
- Safe `name (2).ext` generation.
- Retry/Skip/Cancel paths for recoverable read, write, create, replace and delete failures.
- Destination free-space preflight, cancellation and permanent deletion.
- Aero7 rename dialog for multi-item or non-inline rename.

## Verification helper

`/usr/bin/aero7-shell-selftest` runs 16 isolated headless integration checks for atomic Library persistence, offline/multiple roots, Library search, all four common-dialog modes, copy, keep-both, replace, skip, conflict cancellation, insufficient-space move rejection, directory-tree move and permanent deletion.

The 2026-08-17 VM pass installed `aero7-dolphin 25.12.3-9` and `linux-control-panel 0.1.0-19`, retained the earlier 16 shell checks, confirmed the package contains no Dolphin KCM plug-ins, and visually verified the Explorer header, Favorites/Libraries/Computer/Network navigation and integrated Computer drive surface. Direct `dolphin aero7computer:/` launches are intercepted before KIO, so the Start-menu Computer link no longer produces an unknown-protocol error.

## Integration boundaries

- The Aero7 common dialog is integrated in Aero7-owned applications and is available to other applications through its CLI protocol; arbitrary third-party toolkit dialogs are not intercepted.
- Local copy, move, rename, delete, conflict, error and progress flows use Aero7 UI. Remote-URL operations still use the KIO transport fallback, so a future pass should replace its remaining delegate paths before claiming complete system-wide dialog elimination.
- File-operation permission failures currently offer Retry, Skip and Cancel. A dedicated administrator-elevation continuation path is still future work.
