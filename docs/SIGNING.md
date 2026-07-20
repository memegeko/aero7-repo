# Signing

Status: `MANUAL ACTION REQUIRED`

Create a dedicated signing key on `aero7-builder` only:

```text
Aero7 Package Repository <packages@aero7-shell.invalid>
```

Do not reuse a personal key. Do not reuse any unrelated project key. Do not
commit the private key or a revocation certificate.

After creating the key:

1. Record the full fingerprint here.
2. Export the public key to `keys/aero7-repository.asc`.
3. Update `README.md`.
4. Update `manifests/repository-manifest.json`.
5. Configure the builder signing environment.

Current fingerprint:

```text
MANUAL ACTION REQUIRED
```

Package files and repository databases must be signed. Published pacman config
must use:

```ini
SigLevel = Required DatabaseRequired
```
