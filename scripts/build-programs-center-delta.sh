#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
base_id="${1:-}"
base_db_sha="${2:-}"
[[ "$base_id" =~ ^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{12}$ &&
   "$base_db_sha" =~ ^[0-9a-f]{64}$ ]] || {
  printf 'Usage: scripts/build-programs-center-delta.sh BASE_BUILD_ID BASE_DB_SHA256\n' >&2
  exit 2
}
[[ "$(id -u)" -ne 0 ]] || {
  printf 'build-programs-center-delta: do not build as root\n' >&2
  exit 1
}

builder_root="${AERO7_BUILDER_ROOT:-/srv/aero7-builder}"
website="${AERO7_WEBSITE_HOST:-admin@192.168.2.8}"
source_commit="$(git -C "$repo" rev-parse HEAD)"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
package_id="$stamp-${source_commit:0:12}"
delta_suffix="$(printf '%s' "$source_commit:programs-center-delta" | sha256sum | cut -c1-12)"
delta_id="$stamp-$delta_suffix"
package_stage="$builder_root/staging/$package_id"
delta_stage="$builder_root/staging/$delta_id"
base="$builder_root/sources/$package_id/live-base"

[[ ! -e "$package_stage" && ! -e "$delta_stage" && ! -e "$base" ]] || {
  printf 'build-programs-center-delta: staging path already exists; use a new build run\n' >&2
  exit 1
}

"$repo/scripts/prune-builder.sh" --current-build-id "$package_id"
"$repo/scripts/build-package.sh" aero7-programs-center-git "$package_id"
mapfile -t archives < <(find "$package_stage/packages" -maxdepth 1 -type f \
  -name 'aero7-programs-center-git-*.pkg.tar.zst' -print | sort)
[[ "${#archives[@]}" -eq 1 ]] || {
  printf 'build-programs-center-delta: expected one Programs Center package, found %s\n' "${#archives[@]}" >&2
  exit 1
}

mkdir -p -- "$base"
scp -q -r -o BatchMode=yes \
  "$website:/home/admin/aero7-site/storage/pacman-releases/$base_id/." "$base/"
python "$repo/scripts/programs-center-delta.py" audit-base \
  --base "$base" --base-id "$base_id" --base-db-sha "$base_db_sha"
python "$repo/scripts/programs-center-delta.py" stage \
  --base "$base" --base-id "$base_id" --base-db-sha "$base_db_sha" \
  --package "${archives[0]}" --stage "$delta_stage" --build-id "$delta_id"
"$repo/scripts/test-repository.sh" "$delta_id"
cp -a -- "$base" "$delta_stage/base"
python "$repo/scripts/programs-center-delta.py" verify-delta \
  --base "$delta_stage/base" --base-id "$base_id" --base-db-sha "$base_db_sha" \
  --stage "$delta_stage" --build-id "$delta_id"

printf '%s\n' "$delta_id" > "$builder_root/current-build-id"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  printf 'delta_build_id=%s\n' "$delta_id" >> "$GITHUB_OUTPUT"
fi
printf 'build-programs-center-delta: privately staged %s from package %s; no public repository changed\n' \
  "$delta_id" "$package_id"
