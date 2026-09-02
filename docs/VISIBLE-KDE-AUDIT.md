# Aero7 visible KDE and Plasma audit

Last updated: 2026-08-23

This is the live audit required by the remaining Windows 7 parity pass. It supersedes the narrower 2026-08-17 `NO-VISIBLE-KDE-AUDIT.md`, whose route scan did not include logout, Activities, tray applet actions, desktop folder configuration, or the Devices and Printers launchers.

`Fixed in source` means the route has an Aero7-owned destination and compiles or passes static checks. It does not mean VM acceptance has passed. Only a clean-login VM test may change the VM column to `Passed`.

| Surface | Current UI or former leak | Backend retained | Aero7 replacement | Implementation status | VM test status |
|---|---|---|---|---|---|
| Desktop right click | Aero7 desktop menu; edit mode removed | Plasma containment | Aero7 context menu | Implemented before this pass | Retest required |
| Taskbar right click | Aero7 taskbar menu | Plasma containment and task manager | Aero7 taskbar context menu | Implemented before this pass | Retest required |
| Start menu | SevenStart with system-settings filtering | Plasma models | Aero7 Start menu and Control Panel routes | Implemented before this pass | Retest required |
| Logout: change password | `KCMLauncher` opened Users KCM | Accounts backend | `control --setting accounts` | Fixed in source | Pending |
| Logout: accessibility | `KCMLauncher` opened Accessibility KCM | Accessibility configuration | `control --setting accessibility` | Fixed in source | Pending |
| Activities configure/edit/create | Activities KCM from four QML surfaces | KActivities and Plasma activity service | `control --setting activities` | Fixed in source; activity creation remains limited | Pending |
| Battery context actions | Energy Information and PowerDevil KCM | UPower, power-profiles-daemon, PowerDevil config | Aero7 Power Options | Fixed in source | Pending |
| Network configure action | Network KCM | NetworkManager and Plasma-NM data models | Aero7 Network and Sharing settings | Fixed in source | Pending |
| Per-network Configure | Network KCM with UUID | NetworkManager | Aero7 Change Adapter Settings | Fixed in source; per-connection editor is still limited | Pending |
| Notification configure action | Notifications KCM | Plasma notification server/config | Aero7 Notification Area page | Fixed in source | Pending |
| Devices and Printers: Add device | Bluedevil/Blueman external wizard | BlueZ | Native Aero7 Bluetooth discovery, power, pair, connect, disconnect and remove dialog | Implemented and compiled | Pending; physical adapter needed |
| Devices and Printers: Add printer | KDE/GTK printer utility or CUPS browser | CUPS and `lpadmin` | Native Aero7 Add Printer dialog | Implemented and compiled | Pending; CUPS/permission failures required |
| Explorer startup-folder picker | `QFileDialog` | Local filesystem | In-process `Aero7CommonDialog` | Implemented and built in Explorer r30 | Clean-login VM self-test passed |
| Desktop folder picker | `QFileDialog` | Local filesystem | `aero7-file-dialog --mode folder` | Fixed in source | Pending |
| Control Panel routes | KCM names retained only as metadata | KDE/KWin/KIO config and Linux services | Aero7 pages and native property sheets | Source scan contains no KCM launcher | Previous 70-route pass; full retest pending |
| Screen Resolution | KScreen KCM | KScreen backend | Aero7 Display page | Implemented before this pass | Retest required |
| Mouse and keyboard | Generic native setting sheet, no KCM | input/KWin configuration | Aero7-owned sheet | No KDE leak; Windows tab parity incomplete | Pending |
| Power pages | Aero7 page plus generic advanced sheet | UPower, power profiles, PowerDevil config | Aero7 Power Options | No KDE leak; advanced behavior incomplete | Pending |
| File and folder properties | Aero7 tabbed property sheet | POSIX stat, ACL/MIME data | Aero7 Properties | Implemented before this pass | Retest required |
| Recycle Bin | Aero7 Explorer/desktop surfaces | Freedesktop Trash and KIO | Aero7 Recycle Bin | Implemented before this pass | Retest required |
| Local file operations | Aero7 conflict/progress/error UI | Native filesystem operations | Aero7 Explorer operation dialogs | Implemented before this pass | Retest required |
| Remote file operations | KIO delegate fallback can remain visible | KIO transports | Aero7 remote-operation delegate | Missing | Not tested |
| Printer properties/queue | Device property sheet only | CUPS | Aero7 printer property and queue UI | Partial | Not tested |
| Bluetooth authentication | Aero7 prompt parses `bluetoothctl` confirmation/PIN requests | BlueZ | Aero7 pairing prompt | Implemented; BlueZ Agent1 D-Bus coverage still needed | Not tested |
| Action Center tray | No Aero7 aggregator existed | UFW, polkit, systemd, NetworkManager and filesystem state | Aero7 status-notifier icon and Windows 7-style flyout | Implemented, packaged and autostarted | Passed on Wayland: installed r23 flyout at `912,560`, `360x160` on `1280x768` |
| Polkit authentication | Existing uac-polkit-agent | polkit | Aero7 authentication agent | Existing; complete privileged-route audit pending | Retest required |
| Removable hardware popups | Plasma device notifier may still be reachable | Solid/udisks | Aero7 AutoPlay | Partial; full notifier replacement pending | Not tested |
| Generic KDE error dialogs | KIO/third-party fallbacks possible | KIO/toolkit backends | Common Aero7 dialog framework | Partial | Not tested |

## Static leak search

The normal-user source audit searches active Control Panel, File Explorer and Aero7 Plasma UI sources for:

```text
kcmshell6
systemsettings
KCMLauncher
openSystemSettings
openInfoCenter
bluedevil
blueman-manager
QFileDialog
```

Documentation, translations, build-time configuration QML and upstream/retired sources are excluded. Remaining matches must be classified before acceptance; hiding a button does not qualify as a fix.

## Phase 1 acceptance

- [x] No normal Control Panel route opens a KCM in the static route scan and prior 70-route test; a full hardware torture pass is still required.
- [x] No System Settings or `kcmshell` process was present after the current clean login.
- [ ] No Plasma panel or widget configuration menu appears.
- [ ] No KDE hardware/settings dialog appears.
- [x] Backend KDE components remain available without being presented as Aero7 UI.
- [x] Clean-login/reboot smoke test completed with Explorer r30, Control Panel r23 and desktop r34.
- [ ] Complete hardware, remote-filesystem and failure-path torture test.

## 2026-08-23 clean-login evidence

- Installed package set: `aero7-file-explorer 25.12.3-30`, `linux-control-panel 0.1.0-23`, `aerothemeplasma-desktop-git 6.7.0_742.r9c2d850-34`.
- Explorer's installed `aero7-shell-selftest` passed all 16 local-library, common-dialog, copy/move, conflict and permanent-delete checks.
- The Action Center autostart process and StatusNotifierItem were present after reboot. Its Wayland flyout was measured by KWin at `912,560,360,160`, exactly eight pixels from the right and bottom edges of the `1280x768` guest display.
- The journal contained neither the former `Positioner.updateResolution is not a function` failure nor the former `Failed to create grabbing popup` failure.
- No `systemsettings` or `kcmshell` process was present. KIO workers remain as hidden Explorer/desktop backends and are not counted as visible KDE UI.
- This smoke pass does not substitute for physical Bluetooth, printer, removable-media, multi-monitor, remote-KIO or destructive failure testing.
