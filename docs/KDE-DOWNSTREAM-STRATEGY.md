# KDE stable downstream strategy

## Decision

Do not put Aero7 artwork and sounds directly into a permanent fork of the whole
`KDE/plasma-desktop` repository. Keep artwork, sounds, defaults, and most QML in
small Aero7 packages. Create a narrow KDE source patch only when a requirement
cannot be implemented through supported Plasma packages, configuration, or
plugins.

`plasma-desktop` contains desktop-form-factor components, not the complete KDE
Plasma shell. Shared shell code lives in `plasma-workspace`, audio components
live in `plasma-pa`, and other applets have their own repositories. A broad fork
would therefore not create one stable place for every Aero7 customization and
would multiply monthly rebase work.

## Monthly stable baseline

1. On the first week of each month, read the version of `plasma-desktop` in the
   stable Arch Linux repositories.
2. Compare it with KDE's current bug-fix release for the same supported Plasma
   series.
3. Use the Arch stable package as the Aero7 build baseline; do not move to KDE
   beta, release-candidate, or Git `master` branches.
4. Pin the exact source revision or release tarball and its checksum.
5. Rebase only the small Aero7 patch series.
6. Build all affected packages in the clean builder VM.
7. Run package policy checks, unit tests, an installer VM test, login/logout,
   taskbar, audio, suspend/resume, and upgrade testing.
8. Publish signed packages only after the full matrix passes. Keep the previous
   signed package available for rollback.

## When a KDE fork is justified

A source fork is justified only for a tested change that requires altering KDE
C++ or QML internals and cannot live in AeroThemePlasma, an Aero7 plugin, or a
configuration package. If that happens:

- fork only the affected KDE repository;
- branch from the exact stable release tag used by Arch;
- keep each Aero7 change as a small, independently reviewable commit;
- add an `upstream` remote pointing to KDE;
- preserve every SPDX and REUSE licence record; and
- publish it as an explicitly named Aero7 downstream package rather than
  silently replacing an unmodified KDE binary.

For the current logo and sound work, separate Aero7 packages are the safer and
more maintainable design.
