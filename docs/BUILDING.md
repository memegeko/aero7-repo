# Building

All packages must be built in clean Arch chroots on `aero7-builder`.

Basic flow on the builder:

```bash
cd ~/aero7-repo
scripts/verify-sources.sh
export AERO7_SIGNING_FINGERPRINT='<full fingerprint>'
scripts/build-all.sh
```

`scripts/build-all.sh` derives the build order from `.SRCINFO`, builds every
allowlisted package into one staging build ID, signs the complete set, creates
the pacman repository database, and runs repository checks.

The build must fail if any required package fails. Do not publish partial
staging directories.

## Required Tools

- `base-devel`
- `devtools`
- `git`
- `namcap`
- `pacman-contrib`
- `gnupg`
- `jq`
- `rsync`
- `shellcheck`
- `ccache`

The build scripts use `mkarchroot` and `makechrootpkg`; inspect the installed
devtools help on the builder before the first real build and update scripts if
Arch changes the supported interface.
