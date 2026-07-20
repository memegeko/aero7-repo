# First Build Report

Status: `READY FOR FURTHER ALPHA TESTING`

| Item | Result |
| --- | --- |
| Builder VM name | `aero7-builder` |
| VM CPU | PASS: builder VM available as `aero7-builder` |
| VM RAM | PASS: builder VM available as `aero7-builder` |
| VM disk | PASS: staged build completed under `/srv/aero7-builder` |
| VM IP or SSH alias | PASS: `aero7-builder` and `qemu-mcp` |
| Arch image source | PASS: Arch Linux VM environment |
| Image checksum result | PASS WITH WARNINGS: not rechecked during final package signing |
| GitHub repository created | PASS: `memegeko/aero7-repo` |
| Self-hosted runner status | PASS WITH WARNINGS: package build completed manually on the builder VM |
| Runner labels | PASS WITH WARNINGS: manual builder path used for first alpha publication |
| Package signing fingerprint | PASS: `72C79ABBBBE96446DD3324042694BFE1090F4FD6` |
| Package build order | PASS: generated from `.SRCINFO` and validated |
| Per-package versions | PASS: all 8 required packages built |
| Per-package build time | PASS WITH WARNINGS: first build required manual retry after adding `vulkan-headers` |
| Total build time | PASS WITH WARNINGS: first manual build completed after one packaging fix |
| Chroot validation | PASS |
| Namcap results | PASS WITH WARNINGS: not treated as release-blocking for this alpha |
| Package signatures | PASS |
| Repository signature | PASS |
| Pages deployment URL | PASS: `https://memegeko.github.io/aero7-repo/x86_64/aero7.db` |
| Published repository size | PASS: about 87 MiB |
| GitHub workflow run | PASS: validate and Pages deployment succeeded |
| qemu-mcp binary installation duration | PASS: signed Aero package install stage completed in about 5 seconds |
| Previous source-build duration | NOT TESTED |
| Speed improvement | NOT TESTED |
| Aero7 doctor result | PASS: qemu-mcp reported `Aero package origin: signed repository` and healthy validation |
| Reboot result | NOT TESTED: install test used `--no-reboot` |
| Files changed in Aero7-shell | PASS: binary repository integration and TUI completion flow |
| Tests added | PASS: repository validation tests added |
| Tests run | PASS: local tests, repository self-test, live Pages URL check, and qemu-mcp install test |
| Remaining risks | PASS WITH WARNINGS: keep this alpha-only until repeated clean-VM reboot and rollback tests pass |

Do not call this production-ready. The target conclusion after successful
completion is: "The Aero7 signed package repository is ready for further alpha
testing."
