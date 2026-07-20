#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
build_id="${1:-}"
[[ -n "$build_id" ]] || {
  printf 'Usage: scripts/promote-build.sh <build-id>\n' >&2
  exit 2
}

builder_root="${AERO7_BUILDER_ROOT:-/srv/aero7-builder}"
staging_root="${AERO7_STAGING_DIR:-$builder_root/staging}"
source_public="$staging_root/$build_id/public"
target_public="${AERO7_PUBLIC_DIR:-$repo/public}"

case "$target_public" in
  "$repo"/public) ;;
  *)
    printf 'promote-build: refusing unsafe public path: %s\n' "$target_public" >&2
    exit 1
    ;;
esac

"$repo/scripts/test-repository.sh" "$build_id"
[[ -d "$source_public/x86_64" ]] || {
  printf 'promote-build: staged public directory missing: %s\n' "$source_public" >&2
  exit 1
}

tmp="$repo/public.next"
previous="$repo/public.previous"
rm -rf -- "$tmp"
cp -a "$source_public" "$tmp"
if [[ -d "$target_public" ]]; then
  rm -rf -- "$previous"
  mv -- "$target_public" "$previous"
fi
mv -- "$tmp" "$target_public"
printf 'promote-build: promoted %s\n' "$build_id"
