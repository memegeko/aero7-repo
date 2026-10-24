# Programs Center 0.2.0 delta release

## 24 October 2026 update candidate

The user approved the host-reviewed Programs Center source at
`e7691a9de9b9cce1dbc2738bb3a022547b9128fb`. Its first clean builder
attempt compiled but the Qt 6.12 offscreen layout gate found an 871-pixel
minimum at the requested 720-pixel width; nothing was staged or published.
Source `testing` and `beta` now point to the narrow-width correction
`5379ea11902f1eb8e5b695f7dcb84b4b1bb159c1`. This candidate pins
`aero7-programs-center-git 1:0.2.0.r26.g5379ea1-2`. The host passed all six
tests again. A second clean VM attempt still found an 871-pixel command bar
minimum because its chroot had no usable UI font. The same failure was
reproduced on the host with an empty font configuration; a Noto Sans-only
configuration passed at 720 pixels. The recipe now depends on `noto-fonts`,
which the app stylesheet already names. The clean builder must pass again
before signing or publication.

The exact currently published base is `20261022T202916Z-50dfda1fb6fb` with
`aero7.db` SHA-256
`9974edd62cfff70035d75791b60920992cf7cd060e096d2ee62a87ddefb44ba2`.
The workflow's private and publication steps both pin that base. The delta
gate must preserve all 22 other public packages, their signatures, and their
database entries. The October 22 evidence below describes the earlier release
and is retained as history.

Dispatch the private build first. Review its signed stage and verify-delta
result before dispatching `PROGRAMS-CENTER-DELTA-PUBLISH:BUILD_ID` with
`PUBLISH-AERO7-FINAL`. The guarded website activator must find this exact base
active under its publication lock. Verify the new archive, database, signatures,
public HTTPS readback, and status page after activation.

## Scope and pinned inputs

The source `testing` and `beta` branches point to
`051fea34016122461eab12bc02b56501e1d2a10b`. The `beta` ref was
fast-forwarded from `7adbbed` after publication; `main` remains unchanged.
The package recipe pins that commit and produces `aero7-programs-center-git` version
`1:0.2.0.r22.g051fea3-1`. The dedicated builder VM compiled this package in
a clean chroot, ran all six package tests, and signed it on 22 October 2026.

The signed repository base for this delta was
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

## Published release evidence, 2026-10-22

The 49 selected old `/var/tmp/Aero7*` QA fixture roots were archived locally,
fully compared to their VM originals, and removed. The guarded cleanup then
passed its 20 GiB free-space floor and restarted the GitHub runner. Source
`testing` commit `051fea3` fixed a real narrow-window command-bar width bug
while preserving bundled icons and tooltips. The clean VM package build passed
all six CTests. The first three private runs exposed and resolved an executable
bit, layout, and epoch filename validation problem; see Actions runs
`39847157508`, `39847363001`, and `39848752227`.

[Private staging run 39849199544](https://github.com/memegeko/aero7-repo/actions/runs/39849199544)
passed the signed delta and repository gates. Its build ID is
`20261022T202916Z-50dfda1fb6fb`, from package-repository commit
`8ddd9a9a700166179fcd4baaeda030c2f0ee38a0`. The new package is
`aero7-programs-center-git-1:0.2.0.r22.g051fea3-1-x86_64.pkg.tar.zst`
(SHA256 `d9276656717bc4bbb99dc214c4d2677bdaa3cc6a9948c03f17bb580dabae7f9b`).
The guarded website activator was installed separately and matched the
reviewed script hash. [Publication run 39849634625](https://github.com/memegeko/aero7-repo/actions/runs/39849634625)
passed and switched the public repository to that signed build.

An independent public HTTPS readback downloaded the repository database,
Programs Center archive, signatures, and public key. Both signatures verified
against fingerprint `72C79ABBBBE96446DD3324042694BFE1090F4FD6`; package
metadata, archive hash and size, database hash, manifest build ID, and the
23-package count matched the private stage. The other 22 package archives and
signatures match the previous public release byte-for-byte. Their `desc` and
`files` database entries also match byte-for-byte. Evidence is in
`/home/admin/Documents/aero7 folder/Programs-Center-Delta-2026-10-22/`.
The public build-status JSON was refreshed after publication and read back
over HTTPS with the same SHA256 as the reviewed local record.

The VM gate covers compilation and all six automated tests, including the
responsive layout checks. The exact published archive was also extracted and
its binary launched on the Aero7 host PC without installing a package. Home,
Internet category, Settings and Firefox detail were visually inspected at
ordinary and narrow widths; screenshots and a method receipt are in
`/home/admin/Documents/aero7 folder/Programs-Center-Delta-2026-10-22/host-inspection/`.
At 720 px, the category results table requires horizontal scrolling and
shortens program names. This inspection did not exercise installation,
removal, updates or permission changes. The host's installed package remained
at its earlier version. Source and package repository `main` branches were
not changed.
