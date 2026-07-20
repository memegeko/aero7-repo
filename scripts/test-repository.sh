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
public="$staging_root/$build_id/public/x86_64"

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

for required in aero7.db aero7.db.tar.zst aero7.db.tar.zst.sig aero7.files aero7.files.tar.zst aero7.files.tar.zst.sig repository-manifest.json; do
  [[ -e "$public/$required" ]] || {
    printf 'test-repository: missing repository file %s\n' "$required" >&2
    exit 1
  }
done

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
