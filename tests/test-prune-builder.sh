#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

builder_root="$test_root/builder"
staging_root="$builder_root/staging"
source_root="$builder_root/sources"
oldest="20260801T010101Z-111111111111"
older="20260802T010101Z-222222222222"
newest="20260803T010101Z-333333333333"
current="20260804T010101Z-444444444444"

mkdir -p -- "$staging_root" "$source_root"
for build_id in "$oldest" "$older" "$newest"; do
  mkdir -p -- "$staging_root/$build_id" "$source_root/$build_id"
  printf '{}\n' >"$staging_root/$build_id/build-manifest.json"
done
mkdir -p -- "$staging_root/$current" "$source_root/$current"

AERO7_BUILDER_ROOT="$builder_root" \
AERO7_KEEP_STAGING_BUILDS=2 \
AERO7_MIN_FREE_GIB=0 \
AERO7_TRIM_PACMAN_CACHE=0 \
  "$repo/scripts/prune-builder.sh" --current-build-id "$current"

[[ ! -e "$staging_root/$oldest" ]]
[[ -d "$staging_root/$older" ]]
[[ -d "$staging_root/$newest" ]]
[[ -d "$staging_root/$current" ]]
[[ ! -e "$source_root/$oldest" ]]
[[ ! -e "$source_root/$older" ]]
[[ ! -e "$source_root/$newest" ]]
[[ -d "$source_root/$current" ]]

printf '{}\n' >"$staging_root/$current/build-manifest.json"
AERO7_BUILDER_ROOT="$builder_root" \
AERO7_KEEP_STAGING_BUILDS=2 \
AERO7_MIN_FREE_GIB=0 \
AERO7_TRIM_PACMAN_CACHE=0 \
  "$repo/scripts/prune-builder.sh" \
    --current-build-id "$current" \
    --remove-current-sources

[[ ! -e "$staging_root/$older" ]]
[[ -d "$staging_root/$newest" ]]
[[ -d "$staging_root/$current" ]]
[[ ! -e "$source_root/$current" ]]

printf 'test-prune-builder: ok\n'
