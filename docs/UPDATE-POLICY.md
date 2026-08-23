# Update Policy

Initial policy:

- no recurring rebuild schedule
- manual `workflow_dispatch` only
- no automatic package publishing from unreviewed recipe changes
- no automatic source fallback in Aero7-shell

After one complete successful build, publish, install, reboot, and rollback
test, add a separate update-check workflow that opens reviewable pull requests
for AUR recipe changes.

Update PRs should show:

- old AUR commit
- new AUR commit
- PKGBUILD diff
- `.SRCINFO` diff
- dependency changes
- checksum changes

Do not auto-merge packaging updates during alpha.

## Aero7 Desktop and Gadgets

`aero7-desktop` and `aero7-gadgets` intentionally pin the same reviewed commit
from `aero7-open-project/aero7-desktop`. A desktop-stack update must change the
`_commit` in both recipes together, regenerate both `.SRCINFO` files, refresh
their lock hashes and source revisions, regenerate `build-order.json`, and run
the repository validator plus both package test suites. Tracking an unpinned
branch is forbidden because it would make signed rebuilds non-reproducible.
