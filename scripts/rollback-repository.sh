#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
public="$repo/public"
previous="$repo/public.previous"

[[ -d "$previous" ]] || {
  printf 'rollback-repository: no previous repository snapshot exists\n' >&2
  exit 1
}

tmp="$repo/public.broken.$(date -u +%Y%m%dT%H%M%SZ)"
if [[ -d "$public" ]]; then
  mv -- "$public" "$tmp"
fi
mv -- "$previous" "$public"
printf 'rollback-repository: restored previous repository; broken snapshot kept at %s\n' "$tmp"
