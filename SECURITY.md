# Security

This repository is public, but package builds and signing are trusted
operations. The self-hosted builder must never run arbitrary pull-request code.

## Self-Hosted Runner Rules

- Scope the runner to `memegeko/aero7-repo`, not the user account.
- Run the service as `aero7build`, never as root.
- Do not mount host directories into the builder VM.
- Do not expose libvirt control to the runner.
- Do not give the runner SSH access back to the development host.
- Do not make signing material available to pull-request validation jobs.
- Clear build workspaces only after verifying paths are inside the expected
  runner workspace.
- Use workflow concurrency so only one package build runs at a time.

## Signing Material

The package signing private key must remain on `aero7-builder`. Only the public
key may be committed under `keys/`.

Current signing key status: `MANUAL ACTION REQUIRED`.

## Reporting Issues

Report packaging, signature, repository, or workflow security issues through
GitHub issues. Do not include private keys, tokens, passwords, or runner
registration tokens in reports.
