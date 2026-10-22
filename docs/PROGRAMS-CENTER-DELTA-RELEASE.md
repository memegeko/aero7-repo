# Programs Center 0.2.0 delta release candidate

## Scope and pinned inputs

The source branch `aero7-programs-center/beta` points to
`7adbbed186ca7e5eced036ec76c9e1aee4328bc9`. The package recipe pins that
commit and produces `aero7-programs-center-git` version
`1:0.2.0.r21.g7adbbed-1`. The package remains a candidate until the dedicated
builder VM compiles it in a clean chroot and signs it.

The public signed repository base is
`20260923T180513Z-ce604b74debf`; its `aero7.db` SHA256 is
`4c5b932d1998e2b2e649cb406e2e55d714abab51f8c6a02c2dd42f22739c9a9b`.
Its Programs Center is `0.1.0.r12.g0405a2e-4`. The public key fingerprint is
`72C79ABBBBE96446DD3324042694BFE1090F4FD6`.

The repository `beta` source recipes lag the live site for 15 other packages.
Running their complete-set publisher would stage downgrades. This candidate
instead starts from the **exact currently published 23 archives and
signatures**, changes Programs Center alone, updates its two database entries,
and signs the new archive and databases with the existing repository key.

## Private build and validation

The builder must have at least 20 GiB available on `/`; its runner must be
online. The one-time access setup and the exact guarded cleanup command are in
[`BUILDER-PRUNE-ACCESS.md`](BUILDER-PRUNE-ACCESS.md). After guarded storage
recovery, push this candidate branch and dispatch
the existing `build-packages` workflow in its private delta mode:

```bash
gh workflow run build-packages.yml \
  -R memegeko/aero7-repo \
  --ref programs-center-0.2.0-candidate \
  -f resume_build_id=PROGRAMS-CENTER-DELTA
```

Leave `final_release_confirmation` blank. The candidate branch refuses the
normal full-set build and any unconfirmed publication. Its private mode:

1. Checks pinned sources and builds Programs Center in the clean chroot.
2. Copies the immutable public base from the website server and verifies the
   full base manifest, database hash, public key fingerprint, package hashes,
   all 23 package signatures, and database signatures.
3. Requires the new archive's `.BUILDINFO` recipe hash to match the reviewed
   `PKGBUILD` and its build tool to be `devtools`.
4. Copies the other 22 signed archives unchanged, uses `repo-add` to replace
   only the Programs Center database entry, signs the new package and database,
   and retains the base snapshot inside private staging.
5. Checks all 22 other archives, signatures, versions, database `desc` entries,
   and database `files` entries byte-for-byte against the public base. The
   normal `test-repository.sh` gate also runs.

The completed private staging build ID is in its Actions build report. No
website package changes occur during this workflow.

## Website guard and final publication

After the private build passes, install the reviewed
`site/activate-aero7-programs-center-delta` as a **new** website command. Keep
the existing `activate-aero7-repository` script untouched. Compare the local
and remote SHA256 values after installation. The candidate publisher refuses
to run if the guarded website command is absent or differs from this checkout.

The new website command holds the existing `publish.lock`. Before switching
the public `x86_64` symlink, it requires the active build ID and path to match
the pinned base and compares all 22 non-Programs Center archives and signatures
byte-for-byte. It then verifies the pinned public key, database signature,
all package signatures, and the exact 23-package allowlist. The old release
directory remains available for rollback.

Only after reviewing the signed staging report, dispatch its separate manual
publication mode with the exact staging ID:

```bash
gh workflow run build-packages.yml \
  -R memegeko/aero7-repo \
  --ref programs-center-0.2.0-candidate \
  -f "resume_build_id=PROGRAMS-CENTER-DELTA-PUBLISH:BUILD_ID" \
  -f final_release_confirmation=PUBLISH-AERO7-FINAL
```

Replace `BUILD_ID` with the validated ID from the private build. The publisher
rechecks the live base ID and database hash before upload. The website command
rechecks the base under its publication lock. After activation, the publisher
compares the public database and Programs Center archive with the signed stage
and checks the public manifest's new build ID.

## Dry-run evidence, 2026-10-22

The public release was copied read-only from the website into an isolated local
workspace and its 23 package signatures, both database signatures, package
hashes, database entries, and key fingerprint passed `audit-base`. A synthetic
Programs Center archive was used **only for an unsigned dry run**. `repo-add`
replaced only its `desc` and `files` entries; the other 22 entries and package
files/signatures were byte-for-byte identical. The dry-run stage is marked
incomplete and has no valid new package or database signatures.

Negative checks rejected a wrong base database hash, rejected the unsigned
stage as a signed release, and rejected the synthetic archive as a production
build because its `.BUILDINFO` recipe hash did not match. In a local website
activation sandbox, the guarded command rejected a changed active base, a
tampered Aero7 Desktop archive, and an unsigned delta; the public symlink stayed
on the original release in all cases.

The genuine builder package, its production signatures, website installation,
and public endpoint update remain pending the builder's storage recovery.
