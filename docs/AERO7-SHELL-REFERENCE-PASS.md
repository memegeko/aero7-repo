# Aero7 Windows 7 shell reference pass

Date: 2026-08-16

This pass uses the supplied Windows 7 screenshots as visual references only.
No Microsoft artwork was copied into the new gadget collection. The original
Desktop script and the retired shell prototype were not used or modified.

## Reference research

- Appearance and Personalization references were compared against the supplied
  Personalization and Window Color screenshots.
- `catpswin56/win-gadgets` was reviewed at commit
  `379da78d5045adbf470229cb432732d0b0610ab0` (2026-03-25). It is a useful
  behavioral reference for Clock, CPU, Notes, RSS, Slide Show and Weather.
- The upstream repository is AGPL-3.0 and its README says its visual resources
  belong to Microsoft. Aero7 therefore did not import those bitmap resources.
  The new Aero7 gadget UI, previews and gallery are original MIT-licensed code.
- The upstream reference has no Calendar gadget. Aero7's Calendar is an
  original implementation.

## Acceptance matrix

| Area | Implementation/evidence |
|---|---|
| Desktop context menu | AeroShell containment owns the menu; Personalize opens the native Aero7 page, Screen resolution opens native Display, and Gadgets opens `aero7-gadget-gallery`. |
| Gadget architecture | Plasma containment provides per-instance persistence, movement, resizing, screen ownership and removal; gallery code selects a connected containment and supplies collision-free geometry. |
| Gadget gallery | Standalone Qt window titled Desktop Gadgets, fixed four-by-two Windows 7-style grid, drawn previews, search, selection and double-click activation. It does not enumerate arbitrary Plasma widgets. |
| Gadget controls | Aero7 gadget containers use `AfterMouseOver`, exposing the side overlay with move/remove and configuration where supplied. |
| Clock | Live analog clock with seconds and three configurable face styles. |
| Calendar | Live month grid, selected current day and full date footer. |
| CPU Meter | Live KSysGuard CPU and physical-memory percentages. |
| Currency | Gold Windows 7-style converter using Frankfurter's HTTPS API and ECB reference data, with configurable currencies, amount, swap and refresh. |
| Picture Puzzle | Original orange-flower artwork in a real, solvable 4-by-4 sliding puzzle with legal-move shuffling and a move counter. |
| Weather | Open-Meteo HTTPS backend, configurable city/coordinates/unit, refresh and explicit provider attribution. Live VM result: Amsterdam, 20 C, partly cloudy. |
| Slide Show | Folder-backed local image model, timed advance, previous/next controls and folder chooser; clean empty-folder state. |
| Feed Headlines | HTTP/HTTPS allow-list, RSS/Atom headline extraction, refresh and clean network/error states. Live VM result returned six headlines. |
| Jump Lists | AeroShell SevenTasks contextual TasksMenu supplies application tasks/recent items and close/unpin actions. |
| Thumbnail previews | SevenTasks WindowThumbnail/GroupThumbnails provide hover previews and group handling. |
| Aero Peek | SevenTasks preview setting and Show Desktop integration are enabled; native Taskbar Properties controls preview behavior. |
| Tray overflow | AeroShell system tray owns the hidden-items view and overflow surface. |
| Network flyout | AeroShell networkmanagement flyout is the active normal-user surface. |
| Volume and mixer | AeroShell volume flyout is active and routes mixer behavior through the native Sound applet. |
| Clock/calendar flyout | AeroShell digitalclocklite owns the calendar/time surface. |
| Notifications | AeroShell notification applet and global notification QML own the popup stack. |
| Progress and overlays | SevenTasks includes TaskProgressOverlay and Badge components and reads real task state. |
| Personalization | Native Aero7 page filters to Aero schemes, has an original thumbnail, Desktop Background chooser/positioning, native AeroGlass Window Color, Sound and screen-lock controls. |
| Taskbar/Start properties | Native two-tab page reads/writes live AeroShell panel, SevenTasks and SevenStart settings. |
| Folder Options | Native General/View/Search page writes real KDE, Dolphin, KIO and Baloo settings. |
| Visual accuracy | VM screenshots verified Personalization, Taskbar Properties, Folder Options, the four-by-two gallery, all eight Windows 7 default gadgets and the live taskbar. |
| Backends | NetworkManager, PipeWire/WirePlumber, KSysGuard sensors, Open-Meteo, Frankfurter/ECB rates, local folder model, RSS/Atom and Plasma scripting are used rather than mock data. |
| Gadget security | Gallery has a fixed reviewed allow-list and never downloads gadget code; feed URLs are limited to HTTP(S); Weather uses HTTPS; no credentials are stored. |
| Interaction tests | Packages built successfully; Control Panel has 5/5 passing tests; QML lint passed; VM accepted all gadget packages without QML errors; connected-screen and collision behavior were explicitly tested. |
| Zero-stock normal path | Desktop, taskbar, Start menu, tray, flyouts, notifications, Personalization, Taskbar Properties, Folder Options and gadget gallery are Aero7-owned surfaces. Compatibility KCMs remain only for advanced Control Panel categories not replaced in this pass. |

## VM evidence

Installed versions at the end of the pass:

- `linux-control-panel 0.1.0-16`
- `aero7-gadgets 1.1.0-5`
- `aerothemeplasma-desktop-git 6.7.0_742.r9c2d850-22`

The connected containment (`screen=0`) held Clock, Calendar, Weather, Slide
Show and Feed Headlines at distinct non-overlapping coordinates. The shell
journal contained no new Aero7 gadget `TypeError`, `ReferenceError`, missing
module or QML load errors after the final add pass.

## 2026-08-21 stock gadget completion

`aero7-gadgets 2.0.0-1` completes the eight gadgets included in the Windows 7
Desktop Gadgets gallery: Calendar, Clock, CPU Meter, Currency, Feed Headlines,
Picture Puzzle, Slide Show and Weather. Notes remains available only as legacy
source and is no longer installed or advertised as part of the stock set.

The updated four-by-two gallery and all eight live gadgets were installed in
the Aero7 VM together. QML lint, the native CMake build and a clean runtime
journal confirmed the final code after correcting Canvas compatibility and
repaint bindings found during the live test.
