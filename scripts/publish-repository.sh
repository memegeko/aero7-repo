#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
public="$repo/public"

[[ -d "$public/x86_64" ]] || {
  printf 'publish-repository: public/x86_64 is missing; run promote-build first\n' >&2
  exit 1
}

tarball="${1:-$repo/aero7-repository-public.tar.zst}"
tar --zstd -cf "$tarball" -C "$public" .
printf 'publish-repository: prepared Pages artifact source %s\n' "$tarball"
