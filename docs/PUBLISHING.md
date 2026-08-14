# Publishing

The currently published Beta 1 repository remains available, but publication
of newer packages is frozen until Aero7's explicitly approved final release.
Normal `build-packages` runs compile, sign, test, and retain a private staging
build. They upload only its validation manifest and cannot change GitHub Pages.

The final release has two deliberate manual gates:

1. Dispatch `build-packages` for the reviewed commit with
   `final_release_confirmation` set exactly to `PUBLISH-AERO7-FINAL`. This is
   the only mode that promotes staging into `public/` and uploads the private
   `aero7-pacman-repository` Actions artifact.
2. Inspect that build and record its Actions run ID. Dispatch `deploy-pages`
   with that run ID and the same exact confirmation phrase.

There is no `workflow_run` deployment trigger. A successful test build alone
must never publish packages. `tests/test-release-gates.py` enforces these
conditions in CI.

The `public/` directory is the Pages payload. It is ignored by Git and is
deployed through GitHub Pages artifacts, never committed to `beta`.

When all packages are staged but finalization failed, dispatch
`build-packages` again with the staging ID in `resume_build_id`. This guarded
recovery path runs the normal signing and repository tests before manifest
upload. Leave the final-release confirmation blank during recovery; the
workflow cannot publish a missing or incomplete package set. Finalization also
stamps `repository-manifest.json` with that staging build ID, and validation
refuses to use a build when the manifest and staging ID differ.

If GitHub Pages rejects the final artifact due to size, keep the staged build
intact and document the storage problem. Do not create a substitute public
release, delete packages, or weaken validation to make Pages pass.
