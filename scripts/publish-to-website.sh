#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
build_id="${1:-}"
confirmation="${2:-}"
[[ "$build_id" =~ ^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{12}$ ]] || {
  printf 'Usage: scripts/publish-to-website.sh <build-id> PUBLISH-AERO7-FINAL\n' >&2
  exit 2
}
[[ "$confirmation" == PUBLISH-AERO7-FINAL ]] || {
  printf 'publish-to-website: exact release confirmation is required\n' >&2
  exit 1
}

builder_root="${AERO7_BUILDER_ROOT:-/srv/aero7-builder}"
staging="$builder_root/staging/$build_id"
source_public="$staging/public"
website="${AERO7_WEBSITE_HOST:-admin@192.168.2.8}"
status_script="${AERO7_STATUS_SCRIPT:-$repo/scripts/update-build-status.sh}"
notify_script="${AERO7_NOTIFY_SCRIPT:-$repo/scripts/notify-release.sh}"
public_database="https://aero7.org/repo/x86_64/aero7.db"

export AERO7_BUILD_ID="$build_id"
AERO7_SOURCE_COMMIT="$(jq -r .git_commit "$staging/build-manifest.json")"
export AERO7_SOURCE_COMMIT

"$repo/scripts/test-repository.sh" "$build_id"
[[ -d "$source_public/x86_64" && -d "$source_public/keys" ]] || {
  printf 'publish-to-website: staged public repository is incomplete\n' >&2
  exit 1
}

jq -r '.required_packages[]' "$repo/manifests/packages.json" | sort -u > "$source_public/expected-packages.txt"
cp -a "$staging/build-manifest.json" "$source_public/build-manifest.json"
archive="$staging/aero7-repository-$build_id.tar.zst"
tar --zstd -cf "$archive" -C "$source_public" .

"$status_script" publishing Uploading "Uploading the signed repository to aero7.org." "" 23 23
ssh -o BatchMode=yes "$website" 'install -d -m 700 /home/admin/aero7-site/storage/pacman-incoming'
scp -q -o BatchMode=yes "$archive" "$website:/home/admin/aero7-site/storage/pacman-incoming/$build_id.tar.zst"
ssh -o BatchMode=yes "$website" "/home/admin/aero7-site/bin/activate-aero7-repository '$build_id'"

"$status_script" publishing Verifying "The repository is active; checking it through the public Cloudflare route." "" 23 23
downloaded="$(mktemp)"
trap 'unlink "$downloaded" 2>/dev/null || true' EXIT
curl -fsS --retry 4 --retry-delay 2 -o "$downloaded" "$public_database"
cmp -s "$downloaded" "$source_public/x86_64/aero7.db" || {
  printf 'publish-to-website: public database differs from the signed build\n' >&2
  exit 1
}
curl -fsSI --retry 4 --retry-delay 2 "https://aero7.org/repo/x86_64/repository-manifest.json" >/dev/null

"$status_script" completed Published "All 23 signed packages are published and passed the public repository check." "" 23 23
"$notify_script" repository-published "$build_id" "Repository: https://aero7.org/repo/x86_64"
printf 'publish-to-website: published and publicly verified %s\n' "$build_id"
