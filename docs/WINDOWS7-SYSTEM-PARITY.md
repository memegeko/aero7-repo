# Aero7 Windows 7 system-parity matrix

Last updated: 2026-08-23

Statuses are evidence-based: `Implemented` requires a real backend and working source; `Verified` additionally requires package installation plus clean-login/reboot VM testing; `Partial` identifies the exact remaining boundary. Reference captures already present in the repository remain useful, but a new interface is not marked verified until its matching Windows 7 and Aero7 comparison is recorded.

| Feature | Implementation | Backend | Package | Test/evidence | Windows 7 reference | Known limitation | Status |
|---|---|---|---|---|---|---|---|
| Zero visible KDE UI | Aero7 pages and redirected shell routes | KDE/Linux services hidden | `linux-control-panel`, `aerothemeplasma-desktop-git` | `VISIBLE-KDE-AUDIT.md`; static scan | Existing control-panel/Explorer VM captures | Hardware, remote KIO and failure torture tests remain | Partial |
| Recycle Bin | Dynamic desktop icon, Explorer trash view, restore/empty/properties | Freedesktop Trash/KIO | `aero7-file-explorer`, desktop package | Installed r30; 16 guest shell self-tests plus prior VM UI pass | Windows 7 Recycle Bin behavior/captures required for final polish | Full column parity and missing-original-path UI cases need retest | Verified |
| File Properties | General, Security and Details tabs with real metadata | stat, MIME, POSIX permissions/ACLs | `aero7-file-explorer` | Shell self-test and source audit | Reference VM property sheet | No Previous Versions without snapshot backend | Implemented |
| Folder Properties | General/Security/Details, recursive size/count | filesystem/stat | `aero7-file-explorer` | Shell self-test | Reference VM property sheet | Large-tree cancellation/performance VM test pending | Implemented |
| Drive Properties | Capacity/free data and device details | Solid/statvfs | `aero7-file-explorer` | Computer view tested previously | Reference VM drive properties needed | Tools/Sharing/Security tabs incomplete | Partial |
| File copy/move UI | Aero7 progress with counts, bytes and speed | Native filesystem; KIO for remote | `aero7-file-explorer` | Shell self-tests | Windows 7 conflict/copy capture | Remote delegate and reliable ETA coverage incomplete | Partial |
| Conflict handling | Replace, skip, keep both and apply-to-all | Native filesystem | `aero7-file-explorer` | Keep-both/replace/skip/cancel tests | Windows 7 conflict capture | Remote and mixed multi-conflict VM pass pending | Implemented |
| File-operation errors | Retry, Skip, Cancel; free-space preflight | Native filesystem/KIO | `aero7-file-explorer` | Negative self-tests | Windows 7 error dialogs needed | Elevation continuation and remote disconnect still incomplete | Partial |
| Delete behavior | Trash by default; confirmed permanent deletion | Freedesktop Trash/native delete | `aero7-file-explorer` | Permanent-delete self-test | Windows 7 delete confirmations | Failure/reboot retest pending | Implemented |
| Action Center | Security/Maintenance page with real firewall, scanner, polkit, failed-service, network, disk and cached-update state | UFW, ClamAV, polkit, systemd, NetworkManager, pacman cache and filesystem | `linux-control-panel` | r23 build/tests passed and page backend installed in VM | Existing Windows 7 Action Center capture | Backup and live updater integrations remain incomplete | Partial |
| Action Center tray icon | Status notifier aggregates real issues and opens a Windows 7-style flyout | Same Action Center service probes; LayerShellQt on Wayland | `linux-control-panel` | Clean-login autostart/bus registration; KWin geometry `912,560,360,160` on `1280x768` | Windows 7 tray flyout capture | Notification lifecycle and every failure source still need torture testing | Verified |
| Aero7 elevation/UAC | Existing Aero7 polkit agent and shield conventions | polkit | desktop package | Prior smoke tests; new audit pending | Windows 7 UAC reference | Every privileged route and secure-dimming behavior not audited | Partial |
| Devices and Printers | Real device/printer gallery plus properties | udev/sysfs/CUPS | `linux-control-panel` | Control Panel build; VM pending | Existing Windows 7 large-icons capture | Context actions and queue/default-printer functions incomplete | Partial |
| Bluetooth | Native power, discovery, pair, connect, disconnect and remove dialog | BlueZ via `bluetoothctl` | `linux-control-panel` | Compiled; backend-unavailable and hardware tests pending | Windows 7 Add Device wizard needed | Full BlueZ Agent1 D-Bus implementation and battery display pending | Partial |
| Printers | Native IPP Everywhere Add Printer dialog | CUPS, `lpinfo`, `lpadmin` | `linux-control-panel` | Compiled; CUPS VM tests pending | Windows 7 Add Printer/queue references needed | Queue management, default printer, test page and driver selection incomplete | Partial |
| AutoPlay | Native settings sheet exists | Solid/udisks configuration | `linux-control-panel` | Source route only | Windows 7 AutoPlay capture needed | Event dialog/content inspection and per-device persistence incomplete | Partial |
| Task Manager | Existing TuxManager/Aero7 task manager | `/proc`, systemd | desktop package | Prior project implementation; fresh audit needed | Windows 7 Task Manager tabs | Six-tab parity not verified in this pass | Partial |
| System Properties | Aero7 System page with truthful Linux/Aero7 details | uname, proc/sysfs | `linux-control-panel` | Existing build/tests | Existing Windows 7 System capture | Remote/System Protection/Advanced links incomplete | Partial |
| Battery and power | Battery flyout and Aero7 Power Options routes | UPower, power profiles, logind | desktop/control package | KCM routes fixed; VM pending | Windows 7 battery and plans | Advanced timeout/lid/button backend coverage incomplete | Partial |
| Date and Time | Aero7 tabbed dialog with timezone data | system time/timedate services | `linux-control-panel` | Existing source/build | Windows 7 Date and Time reference | NTP/elevation/additional-clock reboot testing pending | Partial |
| Mouse Properties | Aero7-owned native sheet | KWin/input configuration | `linux-control-panel` | No-KCM route test | Windows 7 five-tab dialog needed | Tabbed parity, per-device hardware and pointer preview incomplete | Partial |
| Keyboard Properties | Aero7-owned native sheet | input configuration | `linux-control-panel` | No-KCM route test | Windows 7 Keyboard Properties needed | Repeat/blink preview and hardware tab incomplete | Partial |
| Fonts | Installed family gallery and preview page | fontconfig | `linux-control-panel` | Existing build | Windows 7 Fonts capture | Search/install/remove interaction needs full VM verification | Partial |
| Region and Language | Aero7-owned settings sheet | locale and input configuration | `linux-control-panel` | No-KCM route test | Windows 7 four-tab dialog needed | Four-tab layout/system-locale elevation incomplete | Partial |
| Ease of Access | Native Aero7 center and real accessibility launch/actions | accessibility services/KWin | `linux-control-panel` | Existing build | Windows 7 Ease of Access capture | Unsupported tools and persistence need audit | Partial |
| Backup and Restore | Native hub route | Filesystem-dependent tools | `linux-control-panel` | Route only | Windows 7 Backup/Recovery references needed | No selected production backend or verified restore workflow | Missing |
| Recovery/System Protection | Links and existing recovery infrastructure | ISO/recovery tools | control/ISO packages | ISO tests separate | Windows 7 Recovery references needed | Snapshot/filesystem capability detection incomplete | Missing |
| Administrative Tools | Computer Management already exists | journal, systemd, proc/sysfs | `aero7-computer-management` | Existing project tests; fresh VM audit needed | Windows 7 tools references | Scheduler/monitors/cleanup/configuration coverage incomplete | Partial |
| Run dialog | Existing Aero7 Run surface | direct process launch | desktop package | Shortcut audit pending | Windows 7 Run dialog | History/Browse/safe-launch behavior needs retest | Partial |
| Shell shortcuts | Existing KWin/Plasma mappings | KGlobalAccel/KWin | desktop package | New matrix test not yet run | Windows 7 keyboard behavior | Meta+Tab and Wayland differences not documented | Partial |
| Common Aero7 dialogs | Explorer common file dialog and several Aero7 property/confirmation sheets | Qt/KIO/Linux backends | `aero7-file-explorer`, `aero7-qt` | 16 shell tests; two generic pickers replaced in source | Windows 7 common-dialog references | System-wide errors/auth/device/wizard API not consolidated | Partial |
| Application not responding | KWin behavior only | KWin/process signals | desktop package | None | Windows 7 not-responding reference needed | Aero7-owned wait/force-close/details dialog missing | Missing |
| Clean VM tests | Current disposable-overlay install and reboot | QEMU Aero7 VM | all | r30/r23/r34 installed; 16 Explorer tests passed; Action Center flyout verified; journal checked | Windows 7 VM available | Broader negative, hardware and multi-monitor cases remain | Partial |
| No-KDE torture test | Static route scan plus clean-login process/journal check | all retained backends | all | No System Settings/KCM process; former folder-position and popup-grab errors absent | Comparison VM available | Physical Bluetooth/printer/removable/display and remote-KIO paths needed | Partial |

## Current acceptance checklist

- [ ] zero visible KDE UI
- [x] Recycle Bin implementation
- [x] File Properties implementation
- [x] Folder Properties implementation
- [ ] Drive Properties complete
- [ ] file copy/move UI complete for local and remote locations
- [x] local conflict handling
- [ ] all file-operation errors and elevation paths
- [ ] Action Center complete
- [ ] Aero7 elevation/UAC audit complete
- [ ] Devices and Printers complete
- [ ] Bluetooth complete and hardware-tested
- [ ] Printers complete and CUPS-tested
- [ ] AutoPlay complete
- [ ] Task Manager six-tab audit complete
- [ ] System Properties links complete
- [ ] battery/power complete
- [ ] Date and Time complete
- [ ] Mouse Properties complete
- [ ] Keyboard Properties complete
- [ ] Fonts complete
- [ ] Region and Language complete
- [ ] Ease of Access complete
- [ ] Backup and Restore complete
- [ ] Recovery complete
- [ ] Administrative Tools complete
- [ ] Run verified
- [ ] shell shortcuts verified and documented
- [ ] common Aero7 dialogs consolidated
- [ ] application-not-responding handling implemented
- [x] clean-login/reboot smoke test for the current r30/r23/r34 package set
- [ ] complete negative, hardware and multi-monitor VM test matrix
- [ ] no-KDE torture-test leaks
