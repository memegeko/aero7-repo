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
