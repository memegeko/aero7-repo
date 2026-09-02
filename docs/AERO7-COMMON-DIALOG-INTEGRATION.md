# Aero7 common item dialog integration

The reusable executable is `/usr/bin/aero7-file-dialog`. It uses the same `Aero7Libraries` service and JSON database as File Explorer, so Libraries, their included folders, and their default save locations cannot drift.

## Command line

```text
aero7-file-dialog --mode open --app-id my.application --filter "Images (*.png *.jpg)"
aero7-file-dialog --mode open-multiple --app-id my.application
aero7-file-dialog --mode save --app-id my.application --name report.txt --suffix txt
aero7-file-dialog --mode folder --app-id my.application
```

Accepted paths are written to standard output, one per line. Cancel exits without paths. The `--app-id` scopes the persisted last folder, window size and last file-type filter.

## Qt applications

In Aero7-owned Qt programs, launch `aero7-file-dialog` synchronously and consume its newline-separated output. The Control Panel wraps that protocol in `Aero7FileDialog.h`; Personalization and User Accounts already use it. This deliberately avoids `QFileDialog`, portal implementations that render a generic picker, and private Qt patching.

Third-party applications can opt in through a small toolkit adapter or by invoking the executable directly. System-wide interception of arbitrary toolkit calls is intentionally not claimed: applications that do not opt in retain their toolkit's own dialog.

## Behavior

- Open one file, open multiple files, Save As, and choose folder modes.
- Windows 7-style navigation row, command row, Favorites, Libraries, Computer, and truthful runtime network mounts.
- Real file filters, overwrite confirmation, new-folder creation, scoped search, back/forward/up navigation and per-application state.
- Opening a Library searches and browses all included locations through the shared merged view.
- Saving while a Library is selected resolves to that Library's configured default save location.
