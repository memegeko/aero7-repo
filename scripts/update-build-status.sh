#!/usr/bin/env bash
set -Eeuo pipefail

state="${1:-}"
phase="${2:-}"
message="${3:-}"
package="${4:-}"
completed="${5:-0}"
total="${6:-0}"

[[ "$state" =~ ^(queued|running|ready|publishing|completed|failed)$ ]] || {
  printf 'update-build-status: invalid state: %s\n' "$state" >&2
  exit 2
}
[[ "$completed" =~ ^[0-9]+$ && "$total" =~ ^[0-9]+$ ]] || {
  printf 'update-build-status: package counts must be integers\n' >&2
  exit 2
}

builder_root="${AERO7_BUILDER_ROOT:-/srv/aero7-builder}"
status_dir="$builder_root/status"
status_file="$status_dir/build.json"
build_id="${AERO7_BUILD_ID:-unknown}"
commit="${AERO7_SOURCE_COMMIT:-${GITHUB_SHA:-unknown}}"
started_file="$status_dir/started-at"

mkdir -p -- "$status_dir"
if [[ "$state" == queued || ! -s "$started_file" ]]; then
  date -u '+%Y-%m-%dT%H:%M:%SZ' > "$started_file"
fi
started_at="$(<"$started_file")"
updated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
if (( total > 0 )); then
  percent=$(( completed * 100 / total ))
else
  percent=0
fi
case "$state" in
  ready) (( percent < 90 )) && percent=90 ;;
  publishing) (( percent < 95 )) && percent=95 ;;
  completed) percent=100 ;;
esac

next="$(mktemp "$status_dir/build.json.next.XXXXXX")"
STATE="$state" PHASE="$phase" MESSAGE="$message" PACKAGE="$package" \
COMPLETED="$completed" TOTAL="$total" PERCENT="$percent" BUILD_ID="$build_id" \
COMMIT="$commit" STARTED_AT="$started_at" UPDATED_AT="$updated_at" \
python - "$next" <<'PY'
import json
import os
import sys

payload = {
    "schema": 1,
    "state": os.environ["STATE"],
    "phase": os.environ["PHASE"],
    "message": os.environ["MESSAGE"],
    "package": os.environ["PACKAGE"],
    "completed": int(os.environ["COMPLETED"]),
    "total": int(os.environ["TOTAL"]),
    "percent": int(os.environ["PERCENT"]),
    "build_id": os.environ["BUILD_ID"],
    "commit": os.environ["COMMIT"],
    "started_at": os.environ["STARTED_AT"],
    "updated_at": os.environ["UPDATED_AT"],
}
with open(sys.argv[1], "w", encoding="utf-8") as stream:
    json.dump(payload, stream, indent=2)
    stream.write("\n")
PY
mv -- "$next" "$status_file"

remote="${AERO7_STATUS_HOST:-}"
remote_path="${AERO7_STATUS_PATH:-/home/admin/aero7-site/storage/pacman-root/repo/status/build.json}"
if [[ -n "$remote" ]]; then
  remote_tmp="${remote_path}.next-${build_id//[^A-Za-z0-9_.-]/_}"
  scp -q -o BatchMode=yes "$status_file" "$remote:$remote_tmp"
  ssh -o BatchMode=yes "$remote" "chmod 644 '$remote_tmp' && mv '$remote_tmp' '$remote_path'"
fi

printf 'update-build-status: %s / %s (%s%%)\n' "$state" "$phase" "$percent"
