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
passphrase_file="${AERO7_GPG_PASSPHRASE_FILE:-}"
default_passphrase_file="${HOME:-}/.gnupg/aero7-repository.passphrase"

[[ -n "$fingerprint" ]] || {
  printf 'sign-packages: AERO7_SIGNING_FINGERPRINT is required\n' >&2
  exit 1
}

if [[ -z "$passphrase_file" && -n "${HOME:-}" && -r "$default_passphrase_file" ]]; then
  passphrase_file="$default_passphrase_file"
fi

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

gpg_args=(--batch --yes --local-user "$fingerprint")
if [[ -n "$passphrase_file" ]]; then
  [[ -r "$passphrase_file" ]] || {
    printf 'sign-packages: passphrase file is not readable: %s\n' "$passphrase_file" >&2
    exit 1
  }
  gpg_args+=(--pinentry-mode loopback --passphrase-file "$passphrase_file")
fi

while IFS= read -r -d '' pkg; do
  gpg "${gpg_args[@]}" --detach-sign --output "$pkg.sig" "$pkg"
done < <(find "$staging/packages" -maxdepth 1 -type f -name '*.pkg.tar.zst' -print0 | sort -z)

public="$staging/public/x86_64"
mkdir -p -- "$public"
cp -a "$staging/packages/"*.pkg.tar.zst "$staging/packages/"*.pkg.tar.zst.sig "$public/"
cp -a "$repo/manifests/repository-manifest.json" "$public/repository-manifest.json"

(
  cd "$public"
  if [[ -n "$passphrase_file" ]]; then
    repo-add aero7.db.tar.zst ./*.pkg.tar.zst
    for db_file in aero7.db.tar.zst aero7.files.tar.zst; do
      gpg "${gpg_args[@]}" --detach-sign --output "$db_file.sig" "$db_file"
    done
  else
    repo-add --sign --key "$fingerprint" aero7.db.tar.zst ./*.pkg.tar.zst
  fi

  rm -f -- aero7.db.tar.zst.old aero7.db.tar.zst.old.sig aero7.files.tar.zst.old aero7.files.tar.zst.old.sig
  cp -f --remove-destination aero7.db.tar.zst aero7.db
  cp -f --remove-destination aero7.db.tar.zst.sig aero7.db.sig
  cp -f --remove-destination aero7.files.tar.zst aero7.files
  cp -f --remove-destination aero7.files.tar.zst.sig aero7.files.sig
)

for db_file in aero7.db.tar.zst aero7.files.tar.zst; do
  [[ -f "$public/$db_file.sig" ]] || {
    printf 'sign-packages: missing database signature %s.sig\n' "$db_file" >&2
    exit 1
  }
done

printf 'sign-packages: signed packages and repository database for %s\n' "$build_id"
