# Aero7 zero-visible-KDE settings audit

Date: 2026-08-17

The supported user path is `control`, its category links, Start-menu links, Explorer's **Folder and search options**, and Explorer's settings shortcuts. None of these paths launches `systemsettings`, `kcmshell6`, or a visible `KCModule`. A source audit of the Control Panel for those launchers returns no matches. The Explorer build also no longer builds or installs Dolphin KCM plug-ins.

## Route inventory

| Former KDE surface(s) | Aero7-owned destination | Real backend retained |
|---|---|---|
| Look and Feel, Colors, Style, Plasma Style, Icons, Cursors, Wallpaper, Splash | Personalization | Plasma theme, icon, cursor, wallpaper and color configuration |
| Fonts, Font Installer | Fonts | Fontconfig and user font directories |
| KScreen | Screen Resolution | KScreen output configuration |
| Night Light, Day/Night | Native Aero7 property sheets | KWin `NightColor` settings |
| Workspace, Plasma Search, Shortcuts, Notifications | Taskbar and Start Menu | Plasma taskbar/search/shortcut settings |
| Window Decoration, Window Behavior, Rules, Task Switcher, Effects, Animations, Screen Edges, Virtual Desktops, Activities, Scripts, Xwayland | Native Aero7 property sheets | KWin and activity-manager configuration; KWin is reconfigured over D-Bus |
| Mouse, Keyboard, Touchpad, Touchscreen, Touch Gestures, Tablet, Game Controller, Virtual Keyboard | Native Aero7 property sheets | Input and KWin configuration |
| PulseAudio, Sound Theme | Aero7 Sound applet and native System Sounds sheet | PipeWire/PulseAudio and sound-theme configuration |
| Network Management | Network and Sharing Center and Change Adapter Settings | NetworkManager via `nmcli` |
| Proxy and network preferences | Native Aero7 property sheets | KIO proxy and timeout configuration |
| PowerDevil profiles and Mobile Power | Power Options and native Advanced Power sheet | power-profile and PowerDevil configuration |
| Users and Online Accounts | User Accounts and native Online Accounts sheet | AccountsService/local account tools and account configuration |
| Clock, Region and Language, Spell Check | Aero7 Date and Time applet plus native sheets | system clock/time zone, locale and Sonnet configuration |
| Component Chooser, File Types, Desktop Paths, Solid Actions | Native Aero7 property sheets | XDG MIME associations, standards-compliant `user-dirs.dirs`, and removable-device configuration |
| Baloo, Recent Files, Web Shortcuts | Folder Options and native sheets | Baloo, activity history and KIO keyword configuration |
| Accessibility | Ease of Access Center and native Advanced Accessibility sheet | accessibility and KWin configuration |
| Autostart, Session, Screen Locker, KDED services | Native Aero7 property sheets | XDG autostart and existing session/locker/service configuration |
| Firewall, Updates, Feedback | Aero7 Firewall/Update pages and native Diagnostic Data sheet | UFW/iptables, package manager and feedback configuration |
| Automounter, Landing Page, Qt Quick Renderer | Native Aero7 sheets and System Information | device automounter, live system data and renderer configuration |
| Dolphin General/View Modes/Trash KCMs | Folder Options, Explorer Views menu and Recycle Bin Properties | Dolphin view settings, Aero7 trash settings and KIO trash backend |

The original module IDs remain only as audit metadata in the settings catalog. They are never treated as executable commands.

## Error behavior

Native sheets show an in-window failure message when a backend command or atomic configuration write fails. Administrator actions continue through the existing Aero7/Polkit paths. Missing optional programs produce Aero7 warnings and do not fall through to KDE settings.

## Verification

- Control Panel Release build: passed.
- Control Panel package tests: 6/6 passed.
- Source audit tokens: no `kcmshell6`, `systemsettings`, `KCMLauncher`, `openSystemSettings`, or `QFileDialog` in Control Panel `src` or `tests`.
- Explorer KCM plug-in targets and installation rules: removed.
- VM route exercise: 70 non-external Control Panel catalog routes opened without starting an exact `kcmshell6` or `systemsettings` process.
- Installed VM packages: `linux-control-panel 0.1.0-19`, `aero7-dolphin 25.12.3-9`, and `aerothemeplasma-desktop-git 6.7.0_742.r9c2d850-29`.
