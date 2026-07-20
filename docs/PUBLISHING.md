# Publishing

Publishing is alpha-only and must be manual until the first complete build,
install, reboot, and rollback test succeeds.

Expected flow:

```bash
scripts/build-all.sh
scripts/promote-build.sh <build-id>
```

The `public/` directory is the Pages payload. It is ignored by Git and should
be deployed through GitHub Pages artifacts, not committed to the main branch.

If GitHub Pages rejects the artifact due to size, keep the staged build intact,
publish an alpha GitHub Release artifact for testing, and document the storage
problem. Do not delete packages or weaken validation to make Pages pass.
