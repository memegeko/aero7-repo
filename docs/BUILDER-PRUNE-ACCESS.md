# Guarded builder cleanup access

## Purpose

The production builder can fill its root filesystem before the GitHub runner
starts. This optional, one-time setup gives the existing `admin` SSH account
one unattended command to recover only disposable builder data. It does not
grant a shell as root or `aero7build`, access to signing keys, or publication
rights. The helper never accepts caller-selected paths, build IDs, environment
overrides, or arguments through sudo.

## Reviewed installation bundle

Place these four files together in a private directory on the builder:

- `ops/builder-prune/install.sh`
- `ops/builder-prune/aero7-prune-builder-safe`
- `ops/builder-prune/sudoers.aero7-prune-builder-safe`
- An unchanged copy of `scripts/prune-builder.sh`

Run `bash install.sh --check BUNDLE_DIRECTORY` without sudo. The installer
checks the three payload SHA-256 values embedded in `install.sh`, parses the
sudoers rule with `visudo`, and parses the Python wrapper. Review the bundle and
its hashes before the one-time privileged installation. The install step must
copy the installer to root-owned `/root/install-aero7-prune-access.sh` mode
`0700`, then run that copy with `--install BUNDLE_DIRECTORY`. It copies the
payloads into root-owned `/run` storage and checks them again before installing:

| Installed path | Owner/mode | Role |
| --- | --- | --- |
| `/usr/local/sbin/aero7-prune-builder-safe` | root:root `0755` | Fixed, no-argument gate |
| `/usr/local/libexec/aero7/prune-builder.sh` | root:root `0755` | Reviewed existing retention helper; executes as `aero7build` |
| `/etc/sudoers.d/aero7-prune-builder-safe` | root:root `0440` | `admin` may run only the gate without a password or environment override |

The installer accepts a new install or the reviewed first wrapper hash for one
fixed wrapper upgrade; it refuses other installed payloads. It validates
the entire sudoers configuration after installation. It **does not clean up
storage** during installation.

## Routine operation

The operational account runs exactly:

```bash
ssh admin@192.168.2.14 'sudo -n /usr/local/sbin/aero7-prune-builder-safe'
```

The wrapper acquires an exclusive lock on `/run`, checks real directory
ownership/modes, checks the installed retention helper's SHA-256, and reads a
strictly formatted `current-build-id` without following symlinks. It refuses
cleanup if `aero7build` has any build or other non-runner process. It stops the
runner, waits for all build-account processes to exit, and rechecks the build
ID. Root trims the package cache with fixed `paccache` commands. The retained
helper then runs **as `aero7build`**, keeps the current build and its sources,
keeps the two newest complete staging builds, and deletes only older valid-ID
staging/source directories. It never uses `--remove-current-sources`.

If cleanup exits successfully with at least 20 GiB free, the wrapper starts
the runner if it was active or its systemd unit is enabled. This also resumes
an enabled runner left stopped by an earlier failed cleanup. Check GitHub's runner **online** status; a running
systemd wrapper alone is insufficient. On process, checksum, retention, or
free-space failure the command exits nonzero and leaves the runner stopped if
it had already been stopped. Investigate the exact failure before retrying.
Do not weaken the 20 GiB gate or remove signing material, credentials, or
runner registration to make space.

## Scope boundary

This grant recovers builder storage. A successful cleanup does not establish a
successful package build, signed repository, website publication, app runtime
acceptance, or a refreshed public status page. Follow the package-specific
release runbook and review its signed staging evidence before publication.
