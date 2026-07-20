# First Build Report

Status: `MANUAL ACTION REQUIRED`

| Item | Result |
| --- | --- |
| Builder VM name | `aero7-builder` |
| VM CPU | PASS WITH WARNINGS: selected 8 vCPU, VM not created yet |
| VM RAM | PASS WITH WARNINGS: selected 8 GiB, VM not created yet |
| VM disk | PASS WITH WARNINGS: selected 100 GiB on large mounted storage, VM not created yet |
| VM IP or SSH alias | NOT TESTED |
| Arch image source | NOT TESTED |
| Image checksum result | NOT TESTED |
| GitHub repository created | PASS: `memegeko/aero7-repo` |
| Self-hosted runner status | MANUAL ACTION REQUIRED |
| Runner labels | MANUAL ACTION REQUIRED |
| Package signing fingerprint | PASS: `72C79ABBBBE96446DD3324042694BFE1090F4FD6` |
| Package build order | PASS WITH WARNINGS: generated locally from `.SRCINFO`; no packages built yet |
| Per-package versions | NOT TESTED |
| Per-package build time | NOT TESTED |
| Total build time | NOT TESTED |
| Chroot validation | NOT TESTED |
| Namcap results | NOT TESTED |
| Package signatures | NOT TESTED |
| Repository signature | NOT TESTED |
| Pages deployment URL | NOT TESTED |
| Published repository size | NOT TESTED |
| GitHub workflow run | PASS WITH WARNINGS: validate runs `29766666107` and `29767429051` passed; package build run `29766666840` was cancelled after switching build workflow to manual-only |
| qemu-mcp binary installation duration | NOT TESTED |
| Previous source-build duration | NOT TESTED |
| Speed improvement | NOT TESTED |
| Aero7 doctor result | NOT TESTED |
| Reboot result | NOT TESTED |
| Files changed in Aero7-shell | NOT TESTED |
| Tests added | PASS WITH WARNINGS: repository validation tests added |
| Tests run | PASS WITH WARNINGS: local source validation only |
| Remaining risks | MANUAL ACTION REQUIRED: self-hosted runner registration, first build, Pages deployment, qemu-mcp install test |

Do not call this production-ready. The target conclusion after successful
completion is: "The Aero7 signed package repository is ready for further alpha
testing."
