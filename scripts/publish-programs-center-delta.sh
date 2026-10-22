#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
build_id="${1:-}"
base="${2:-}"
base_id="${3:-}"
base_db_sha="${4:-}"
confirmation="${5:-}"

[[ "$build_id" =~ ^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{12}$ &&
   "$base_id" =~ ^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{12}$ &&
   "$base_db_sha" =~ ^[0-9a-f]{64}$ &&
   "$confirmation" == PUBLISH-AERO7-FINAL ]] || {
  printf 'Usage: scripts/publish-programs-center-delta.sh BUILD_ID BASE_DIR BASE_BUILD_ID BASE_DB_SHA256 PUBLISH-AERO7-FINAL\n' >&2
  exit 2
}

builder_root="${AERO7_BUILDER_ROOT:-/srv/aero7-builder}"
stage="$builder_root/staging/$build_id"
public="$stage/public"
website="${AERO7_WEBSITE_HOST:-admin@192.168.2.8}"
remote_root="/home/admin/aero7-site"
remote_script="$remote_root/bin/activate-aero7-programs-center-delta"
public_url="https://aero7.org/repo/x86_64"

[[ -d "$stage" && -d "$base" && ! -e "$stage/INCOMPLETE_DO_NOT_PUBLISH" ]] || {
  printf 'publish-programs-center-delta: missing or incomplete signed staging/base directory\n' >&2
  exit 1
}

python "$repo/scripts/programs-center-delta.py" verify-delta \
  --base "$base" --base-id "$base_id" --base-db-sha "$base_db_sha" \
  --stage "$stage" --build-id "$build_id"
"$repo/scripts/test-repository.sh" "$build_id"

local_script_sha="$(sha256sum "$repo/site/activate-aero7-programs-center-delta" | awk '{print $1}')"
remote_script_sha="$(ssh -o BatchMode=yes "$website" "sha256sum '$remote_script'" | awk '{print $1}')"
[[ "$remote_script_sha" == "$local_script_sha" ]] || {
  printf 'publish-programs-center-delta: guarded website activator is missing or differs from reviewed script\n' >&2
  exit 1
}

remote_current="$(ssh -o BatchMode=yes "$website" "cat '$remote_root/storage/pacman-root/repo/current-build-id'")"
[[ "$remote_current" == "$base_id" ]] || {
  printf 'publish-programs-center-delta: website base changed from %s to %s\n' "$base_id" "$remote_current" >&2
  exit 1
}

tmp_db="$(mktemp)"
tmp_package="$(mktemp)"
trap 'unlink "$tmp_db" 2>/dev/null || true; unlink "$tmp_package" 2>/dev/null || true' EXIT
curl -fsSL --retry 4 --retry-delay 2 -o "$tmp_db" "$public_url/aero7.db"
[[ "$(sha256sum "$tmp_db" | awk '{print $1}')" == "$base_db_sha" ]] || {
  printf 'publish-programs-center-delta: public repository database changed since staging\n' >&2
  exit 1
}
[[ "$(curl -fsSL --retry 4 --retry-delay 2 "$public_url/repository-manifest.json" | jq -r .last_successful_build)" == "$base_id" ]] || {
  printf 'publish-programs-center-delta: public repository manifest changed since staging\n' >&2
  exit 1
}

archive="$stage/aero7-programs-center-delta-$build_id.tar.zst"
[[ ! -e "$archive" ]] || {
  printf 'publish-programs-center-delta: archive already exists: %s\n' "$archive" >&2
  exit 1
}
tar --zstd -cf "$archive" -C "$public" .

ssh -o BatchMode=yes "$website" "install -d -m 700 '$remote_root/storage/pacman-incoming'"
scp -q -o BatchMode=yes "$archive" "$website:$remote_root/storage/pacman-incoming/$build_id.tar.zst"
# The website activator holds publish.lock while checking the active base ID and
# comparing all 22 untouched package archives and signatures before switching.
ssh -o BatchMode=yes "$website" "$remote_script '$build_id' PUBLISH-AERO7-FINAL"

curl -fsSL --retry 5 --retry-delay 2 -H 'Cache-Control: no-cache' -o "$tmp_db" "$public_url/aero7.db"
cmp -s "$tmp_db" "$public/x86_64/aero7.db" || {
  printf 'publish-programs-center-delta: public database differs from signed staging\n' >&2
  exit 1
}
[[ "$(curl -fsSL --retry 5 --retry-delay 2 -H 'Cache-Control: no-cache' \
  "$public_url/repository-manifest.json" | jq -r .last_successful_build)" == "$build_id" ]] || {
  printf 'publish-programs-center-delta: public manifest does not identify new build\n' >&2
  exit 1
}
new_package="$(find "$public/x86_64" -maxdepth 1 -type f -name 'aero7-programs-center-git-*.pkg.tar.zst' -printf '%f\n')"
[[ -n "$new_package" ]] || {
  printf 'publish-programs-center-delta: staged Programs Center archive missing\n' >&2
  exit 1
}
curl -fsSL --retry 5 --retry-delay 2 -o "$tmp_package" "$public_url/$new_package"
cmp -s "$tmp_package" "$public/x86_64/$new_package" || {
  printf 'publish-programs-center-delta: public Programs Center archive differs from signed staging\n' >&2
  exit 1
}
printf 'publish-programs-center-delta: published and publicly verified %s; other 22 packages preserved\n' "$build_id"
