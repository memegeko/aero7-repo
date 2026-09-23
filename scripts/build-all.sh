#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
builder_root="${AERO7_BUILDER_ROOT:-/srv/aero7-builder}"
staging_root="${AERO7_STAGING_DIR:-$builder_root/staging}"
commit="${GITHUB_SHA:-$(git -C "$repo" rev-parse --short=12 HEAD 2>/dev/null || printf local)}"
build_id="${AERO7_BUILD_ID:-$(date -u +%Y%m%dT%H%M%SZ)-${commit:0:12}}"
staging="$staging_root/$build_id"
notification_script="${AERO7_NOTIFY_SCRIPT:-$repo/scripts/notify-release.sh}"
notification_config="${AERO7_NOTIFICATION_CONFIG:-${HOME:?}/.config/aero7-builder/notifications.conf}"
status_script="${AERO7_STATUS_SCRIPT:-$repo/scripts/update-build-status.sh}"

status_update() {
  if [[ -x "$status_script" ]]; then
    AERO7_BUILD_ID="$build_id" AERO7_SOURCE_COMMIT="$commit" \
      "$status_script" "$@" || \
      printf 'build-all: warning: public status could not be updated\n' >&2
  fi
}

notify_build_failure() {
  local status="$1"
  local line="$2"
  trap - ERR
  status_update failed Failed \
    "The package build failed near build-all.sh line $line. The previous repository remains active." \
    "" "${completed:-0}" "${total:-23}"
  if [[ -x "$notification_script" && -r "$notification_config" ]]; then
    AERO7_NOTIFICATION_CONFIG="$notification_config" \
      "$notification_script" build-failed "$build_id" \
      "The build stopped near build-all.sh line $line with exit status $status. Logs remain on the builder." || \
      printf 'build-all: warning: failure notification could not be delivered\n' >&2
  fi
  exit "$status"
}

trap 'notify_build_failure "$?" "$LINENO"' ERR

if [[ "$(id -u)" -eq 0 ]]; then
  printf 'build-all: do not run package builds as root\n' >&2
  exit 1
fi

mkdir -p -- "$staging"
printf '%s\n' "$build_id" > "$builder_root/current-build-id"
status_update queued Preparing "Preparing the clean builder and package order." "" 0 23
"$repo/scripts/prune-builder.sh" --current-build-id "$build_id"
python "$repo/scripts/dependency-order.py" --repo "$repo" --write
mapfile -t packages < <(python - "$repo/manifests/build-order.json" <<'PY'
import json
import sys
for package in json.load(open(sys.argv[1], encoding="utf-8"))["packages"]:
    print(package)
PY
)
total="${#packages[@]}"
[[ "$total" -eq 23 ]] || {
  printf 'build-all: expected 23 packages, found %s\n' "$total" >&2
  exit 1
}

completed=0
for package in "${packages[@]}"; do
  status_update running Building \
    "Building package $((completed + 1)) of $total in the clean Arch chroot." \
    "$package" "$completed" "$total"
  "$repo/scripts/build-package.sh" "$package" "$build_id"
  completed=$((completed + 1))
  status_update running Building \
    "Completed $completed of $total packages." "" "$completed" "$total"
done

status_update running Signing "Signing packages and generating the repository database." "" "$completed" "$total"
"$repo/scripts/finalize-build.sh" "$build_id"
"$repo/scripts/prune-builder.sh" \
  --current-build-id "$build_id" \
  --remove-current-sources

status_update ready Validated "All packages are signed and validated. Publication is awaiting the explicit release step." "" "$completed" "$total"
trap - ERR
printf 'build-all: staged complete build %s at %s\n' "$build_id" "$staging"
