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

notify_build_failure() {
  local status="$1"
  local line="$2"
  trap - ERR
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
"$repo/scripts/prune-builder.sh" --current-build-id "$build_id"
python "$repo/scripts/dependency-order.py" --repo "$repo" --write
mapfile -t packages < <(python - "$repo/manifests/build-order.json" <<'PY'
import json
import sys
for package in json.load(open(sys.argv[1], encoding="utf-8"))["packages"]:
    print(package)
PY
)

for package in "${packages[@]}"; do
  "$repo/scripts/build-package.sh" "$package" "$build_id"
done

"$repo/scripts/finalize-build.sh" "$build_id"
"$repo/scripts/prune-builder.sh" \
  --current-build-id "$build_id" \
  --remove-current-sources

trap - ERR
printf 'build-all: staged complete build %s at %s\n' "$build_id" "$staging"
