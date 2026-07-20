# Publishing

Publishing is alpha-only. The first complete signed package set is live on
GitHub Pages, and future builds should continue to use the artifact-driven
Pages workflow.

Expected flow:

```bash
scripts/build-all.sh
scripts/promote-build.sh <build-id>
```

The `public/` directory is the Pages payload. It is ignored by Git and should
be deployed through GitHub Pages artifacts, not committed to the main branch.
The `build-packages` workflow prepares and uploads the `aero7-pacman-repository`
artifact. A successful workflow run can trigger `deploy-pages` automatically;
or run `deploy-pages` manually with the completed build workflow run ID.

If GitHub Pages rejects the artifact due to size, keep the staged build intact,
publish an alpha GitHub Release artifact for testing, and document the storage
problem. Do not delete packages or weaken validation to make Pages pass.
