#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
build_id="${1:-}"
[[ -n "$build_id" ]] || {
  printf 'Usage: scripts/sign-packages.sh <build-id>\n' >&2
  exit 2
}

builder_root="${AERO7_BUILDER_ROOT:-/srv/aero7-builder}"
staging_root="${AERO7_STAGING_DIR:-$builder_root/staging}"
staging="$staging_root/$build_id"
fingerprint="${AERO7_SIGNING_FINGERPRINT:-}"

[[ -n "$fingerprint" ]] || {
  printf 'sign-packages: AERO7_SIGNING_FINGERPRINT is required\n' >&2
  exit 1
}

if [[ ! -d "$staging/packages" ]]; then
  printf 'sign-packages: package staging directory missing: %s/packages\n' "$staging" >&2
  exit 1
fi

mapfile -t expected < <(jq -r '.required_packages[]' "$repo/manifests/packages.json")
for package in "${expected[@]}"; do
  count="$(find "$staging/packages" -maxdepth 1 -type f -name "${package}-*.pkg.tar.zst" | wc -l)"
  [[ "$count" -eq 1 ]] || {
    printf 'sign-packages: expected one package for %s, found %s\n' "$package" "$count" >&2
    exit 1
  }
done

while IFS= read -r -d '' pkg; do
  gpg --batch --yes --local-user "$fingerprint" --detach-sign --output "$pkg.sig" "$pkg"
done < <(find "$staging/packages" -maxdepth 1 -type f -name '*.pkg.tar.zst' -print0 | sort -z)

public="$staging/public/x86_64"
mkdir -p -- "$public"
cp -a "$staging/packages/"*.pkg.tar.zst "$staging/packages/"*.pkg.tar.zst.sig "$public/"
cp -a "$repo/manifests/repository-manifest.json" "$public/repository-manifest.json"

(
  cd "$public"
  repo-add --sign --key "$fingerprint" aero7.db.tar.zst ./*.pkg.tar.zst
)

for db_file in aero7.db.tar.zst aero7.files.tar.zst; do
  [[ -f "$public/$db_file.sig" ]] || {
    printf 'sign-packages: missing database signature %s.sig\n' "$db_file" >&2
    exit 1
  }
done

printf 'sign-packages: signed packages and repository database for %s\n' "$build_id"
