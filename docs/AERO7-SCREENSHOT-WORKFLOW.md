# Aero7 rectangular screenshot workflow

`aero7-snipping-tool` provides the desktop-default `Meta+Shift+S` workflow.
It is started once per KDE session by
`org.aero7.snippingtool-autostart.desktop` and owns the shortcut through
KGlobalAccel.

The autostart file is installed under the same desktop identity as the visible
Snipping Tool application (`org.aero7.snippingtool.desktop`). That identity
declares KWin's restricted screenshot interface, so Spectacle remains
authorized when it is launched by the background helper on Wayland.

## Behavior

1. `Meta+Shift+S` starts Spectacle with `--region`, `--release-capture`,
   `--background`, `--nonotify` and an explicit PNG output path.
2. Spectacle displays only its rectangular selector. Releasing the mouse
   accepts the selection; its editor and main window do not open.
3. The PNG is saved below the XDG Pictures location in `Screenshots/`, normally
   `~/Pictures/Screenshots/`.
4. The service reads the saved PNG and publishes both Qt image data and an
   explicit `image/png` payload through KDE's system clipboard API. This works
   from the unfocused background service on Wayland, so applications that
   accept pasted images can use it immediately with `Ctrl+V`.
5. Plasma receives an Aero7 `Screenshot saved` notification with a thumbnail.
   Its default **Open** action passes the file URL to the desktop's default PNG
   handler.

Escaping the selector is treated as cancellation and produces neither a file
nor an error notification. Concurrent requests are serialized so one selector
is active at a time. Output names include milliseconds and a random suffix to
avoid collisions.

## Verification

The installed backend can be checked without capturing a screen:

```sh
aero7-snipping-tool --check-backend
```

This confirms that the installed Spectacle supports every command-line option
required by the workflow.

The Aero7 updater also removes the two legacy per-user Spectacle launchers that
previously owned `Meta+Shift+S` and `Print`. Besides conflicting with the native
helper, those overrides hid Spectacle's official Wayland permission metadata.
