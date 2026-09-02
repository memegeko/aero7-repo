# Aero7 Desktop Gadgets 3.0

## Purpose

`aero7-gadgets` is Aero7's native Windows 7-style Desktop Gadgets subsystem.
It replaces the retired Plasma-plasmoid prototype. The package contains one
shared Qt 6 runtime and does not install anything below
`/usr/share/plasma/plasmoids`.

## Desktop integration

- Desktop right-click **Gadgets** launches `aero7-gadget-gallery`.
- `/etc/xdg/autostart/org.aero7.GadgetHost-autostart.desktop` restores the
  host during login.
- Package install/upgrade removes the obsolete unowned
  `/etc/xdg/autostart/aero7-gadget-gallery.desktop` only when it contains the
  legacy `Exec=aero7-gadget-gallery` command. Owned or customized files are
  left untouched, preventing the old Gallery-on-login behavior safely.
- On Wayland, each gadget is a LayerShellQt surface. Normal instances use the
  bottom shell layer; **Always on top** instances use the top layer.
- During Show Desktop/Aero Peek, gadgets temporarily move to the top shell
  layer so application windows disappear while gadgets remain visible.
- The X11 fallback uses frameless tool windows with the corresponding stacking
  hints.

## Runtime and persistence

- One process (`aero7-gadget-host`) owns all built-in instances.
- D-Bus service: `org.aero7.Gadgets`, object `/GadgetManager`.
- Supported manager calls include `ShowGallery`, `AddGadget`, `RemoveGadget`
  and `ResetLayout`.
- Layout and per-instance settings live in
  `~/.config/aero7/gadgets/layout.json`.
- Feed presets live in `~/.config/aero7/gadgets/feeds.json`.
- Network caches live below `~/.cache/aero7/gadgets/`.
- Every instance stores its ID, unique instance ID, monitor, logical position,
  size, opacity, always-on-top state and independent settings.
- Missing monitors migrate to the primary display without deleting settings.
- Gadgets snap to all screen edges and to neighbouring gadget edges within a
  10-logical-pixel threshold.

## Gallery and common controls

- Windows 7-sized 478×350 Desktop Gadget Gallery.
- Four-by-two first page and Media Center on page two.
- Name search, keyboard activation, double-click Add, right-click Add and
  drag-out placement.
- Fading side controls for Close, Larger/Smaller, Options and dragging.
- Windows-style gadget menu with Move, Size, Always on top, five opacity
  levels, Options and Close gadget.
- Multiple instances are supported for every built-in gadget.

## Built-in gadgets

1. **Calendar** — tear-off day view, full month view, month navigation,
   Monday/Sunday first-day choice, current-day highlight and week numbers.
2. **Clock** — analogue face, seconds, three face styles, optional label and
   native system time-zone selection. Multiple clocks can use different zones.
3. **CPU Meter** — live CPU and RAM gauges from `/proc/stat` and
   `/proc/meminfo`; no helper commands are spawned.
4. **Currency** — editable upper/lower amounts, currency selection, cached
   Frankfurter/ECB reference rates and a non-blank offline state.
5. **Feed Headlines** — RSS and Atom, safe HTTP(S) links, cached headlines,
   refresh/count settings and a persistent Add/Remove feed manager.
6. **Picture Puzzle** — solvable sliding-tile shuffle, 3×3/4×4/5×5 modes,
   original Aero7 imagery and user-selected images.
7. **Slide Show** — XDG Pictures support, PNG/JPEG/WebP/BMP/GIF discovery,
   previous/play-pause/next hover controls, shuffle, interval and fade
   transition.
8. **Weather** — Open-Meteo current conditions and three-day forecast,
   geocoding, Celsius/Fahrenheit, glossy condition artwork and cached stale
   data.
9. **Media Center** — MPRIS2 active-player discovery, title/artist/album,
   album art and previous/play-pause/next controls.

## Safety and resource use

- The obsolete unrestricted Microsoft HTML/JavaScript gadget model is not
  implemented.
- Built-ins use narrow native backends: procfs, time-zone APIs, user-approved
  picture paths, HTTPS requests and MPRIS2.
- Feed links are restricted to HTTP(S); arbitrary feed-provided local schemes
  are not opened.
- Network requests have timeouts, bounded response reads, safe redirect policy
  and XDG caches.
- Static gadgets do not repaint once per second. CPU data is shared, clocks
  repaint according to seconds/minutes, and network gadgets update on data
  events.
- The host is outside the desktop shell, so a host failure cannot crash
  Plasma/AeroShell. Unknown or malformed saved gadget IDs are skipped and
  logged.
- Installed metadata in `/usr/share/aero7/gadgets/` declares each built-in's
  ID, sizes, settings support and narrow permission needs.

## Packaging and verification

The Arch package is `aero7-gadgets` 3.0.0 and provides `win-gadgets`. Runtime
dependencies are Qt 6 Base/SVG, KF6 WindowSystem and LayerShellQt. Plasma,
LibPlasma and libksysguard are not gadget runtime dependencies.

Build verification:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build
ctest --test-dir build --output-on-failure
```

`gadget-runtime-core` validates the exact nine definitions, unique IDs, sizes,
JSON state round-tripping, XDG write paths and installed/source metadata.

VM verification covers gallery page layout and search, all nine live gadgets,
single-instance double-click addition, Wayland drag-out placement, free drag,
edge/gadget snapping, hover controls, context menus, package installation,
live Atom headlines, live MPRIS play/pause and player-close fallback, process
restart restoration and Aero Peek layer behavior. A full reboot/login test
confirmed one autostarted native host, an unchanged persisted layout, and no
unrequested Gallery window after removal of the legacy autostart entry.

The runtime watches screen add/remove, geometry, available-geometry and logical
DPI changes and clamps or migrates saved windows as needed. A physical
multi-monitor/DPI matrix should still be repeated on release hardware or a
multi-head test image.
