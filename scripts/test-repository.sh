#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
build_id="${1:-}"
[[ -n "$build_id" ]] || {
  printf 'Usage: scripts/test-repository.sh <build-id>\n' >&2
  exit 2
}

builder_root="${AERO7_BUILDER_ROOT:-/srv/aero7-builder}"
staging_root="${AERO7_STAGING_DIR:-$builder_root/staging}"
public_root="$staging_root/$build_id/public"
public="$public_root/x86_64"

[[ -d "$public" ]] || {
  printf 'test-repository: public repository directory missing: %s\n' "$public" >&2
  exit 1
}

mapfile -t expected < <(jq -r '.required_packages[]' "$repo/manifests/packages.json")
for package in "${expected[@]}"; do
  count="$(find "$public" -maxdepth 1 -type f -name "${package}-*.pkg.tar.zst" | wc -l)"
  [[ "$count" -eq 1 ]] || {
    printf 'test-repository: expected one package for %s, found %s\n' "$package" "$count" >&2
    exit 1
  }
  pkg="$(find "$public" -maxdepth 1 -type f -name "${package}-*.pkg.tar.zst" | head -1)"
  [[ -f "$pkg.sig" ]] || {
    printf 'test-repository: missing signature for %s\n' "$pkg" >&2
    exit 1
  }
done

for required in aero7.db aero7.db.sig aero7.db.tar.zst aero7.db.tar.zst.sig aero7.files aero7.files.sig aero7.files.tar.zst aero7.files.tar.zst.sig repository-manifest.json; do
  [[ -e "$public/$required" ]] || {
    printf 'test-repository: missing repository file %s\n' "$required" >&2
    exit 1
  }
done

public_key="$public_root/keys/aero7-repository.asc"
[[ -f "$public_key" ]] || {
  printf 'test-repository: missing repository public key %s\n' "$public_key" >&2
  exit 1
}

expected_fingerprint="$(jq -r '.signing_fingerprint' "$public/repository-manifest.json")"
actual_fingerprint="$(gpg --batch --show-keys --with-colons "$public_key" | awk -F: '$1 == "fpr" { print $10; exit }')"
[[ "$actual_fingerprint" == "$expected_fingerprint" ]] || {
  printf 'test-repository: public key fingerprint mismatch: expected %s, got %s\n' "$expected_fingerprint" "$actual_fingerprint" >&2
  exit 1
}

if find "$public" -maxdepth 1 -type f -name '*.old*' | grep -q .; then
  printf 'test-repository: stale repository database backup files were published\n' >&2
  exit 1
fi

if command -v pacman >/dev/null 2>&1; then
  pacman -Sl aero7 --config <(
    printf '[options]\n'
    printf 'Architecture = auto\n'
    printf 'SigLevel = Required DatabaseRequired\n'
    printf '[aero7]\n'
    printf 'SigLevel = Required DatabaseRequired\n'
    printf 'Server = file://%s\n' "$public"
  ) >/dev/null
else
  printf 'test-repository: pacman not available; skipped file:// repository query\n' >&2
fi

printf 'test-repository: ok for %s\n' "$build_id"
