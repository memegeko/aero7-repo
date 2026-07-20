# Contributing

Package recipe changes must be reviewable and pinned.

- Update package recipes from `https://aur.archlinux.org/<package>.git`.
- Record the exact AUR commit and checksums in `manifests/upstream-lock.json`.
- Regenerate `.SRCINFO` after approved PKGBUILD changes.
- Run `scripts/verify-sources.sh`.
- Do not add X11 Plasma packages.
- Do not add proprietary Microsoft assets.
- Do not commit package build outputs, chroots, logs, private keys, tokens, or
  generated repository artifacts.

Publishing requires a complete signed package set. Partial builds must stay in
staging.
