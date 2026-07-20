# Recovery

## Roll Back Repository

```bash
scripts/rollback-repository.sh
```

The script restores `public.previous` and keeps the broken repository snapshot
with a timestamp.

## Recreate Builder VM

1. Disable the old self-hosted runner service.
2. Revoke the old runner registration.
3. Create a fresh Arch VM from an official image.
4. Recreate `/srv/aero7-builder` paths.
5. Restore only approved signing material.
6. Register a repository-scoped runner.

## Key Revocation

If the signing key is compromised, publish the revocation notice, remove the
key from the builder, create a new dedicated signing key, publish the new
public key, and update Aero7-shell fingerprint checks. Do not reuse the old
fingerprint.

## Installer Source Fallback

If binary packages are broken or unavailable, Aero7-shell must require explicit
consent before falling back to AUR source builds.
