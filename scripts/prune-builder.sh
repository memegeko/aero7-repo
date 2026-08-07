#!/usr/bin/env bash
set -Eeuo pipefail

builder_root="${AERO7_BUILDER_ROOT:-/srv/aero7-builder}"
staging_root="${AERO7_STAGING_DIR:-$builder_root/staging}"
source_root="${AERO7_SOURCE_DIR:-$builder_root/sources}"
keep_completed="${AERO7_KEEP_STAGING_BUILDS:-2}"
minimum_free_gib="${AERO7_MIN_FREE_GIB:-20}"
trim_pacman_cache="${AERO7_TRIM_PACMAN_CACHE:-1}"
current_build_id=""
remove_current_sources=false

usage() {
  cat >&2 <<'EOF'
Usage: scripts/prune-builder.sh --current-build-id <build-id> [--remove-current-sources]

Retains the active build and the newest completed staging builds, removes
disposable source trees, trims the host package cache, and checks free space.
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --current-build-id)
      [[ "$#" -ge 2 ]] || {
        usage
        exit 2
      }
      current_build_id="$2"
      shift 2
      ;;
    --remove-current-sources)
      remove_current_sources=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'prune-builder: unknown argument: %s\n' "$1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ ! "$current_build_id" =~ ^[0-9]{8}T[0-9]{6}Z-([0-9a-f]{12}|local)$ ]]; then
  printf 'prune-builder: invalid build ID: %s\n' "${current_build_id:-<empty>}" >&2
  exit 2
fi
if [[ ! "$keep_completed" =~ ^[0-9]+$ ]] || (( keep_completed < 1 )); then
  printf 'prune-builder: AERO7_KEEP_STAGING_BUILDS must be a positive integer\n' >&2
  exit 2
fi
if [[ ! "$minimum_free_gib" =~ ^[0-9]+$ ]]; then
  printf 'prune-builder: AERO7_MIN_FREE_GIB must be a non-negative integer\n' >&2
  exit 2
fi
if [[ "$trim_pacman_cache" != 0 && "$trim_pacman_cache" != 1 ]]; then
  printf 'prune-builder: AERO7_TRIM_PACMAN_CACHE must be 0 or 1\n' >&2
  exit 2
fi

builder_root="$(realpath -m -- "$builder_root")"
staging_root="$(realpath -m -- "$staging_root")"
source_root="$(realpath -m -- "$source_root")"

if [[ "$builder_root" == / || "$builder_root" == "${HOME:-}" || ${#builder_root} -lt 8 ]]; then
  printf 'prune-builder: refusing unsafe builder root: %s\n' "$builder_root" >&2
  exit 1
fi
case "$staging_root" in
  "$builder_root"/staging) ;;
  *)
    printf 'prune-builder: staging path is outside the expected builder location: %s\n' "$staging_root" >&2
    exit 1
    ;;
esac
case "$source_root" in
  "$builder_root"/sources) ;;
  *)
    printf 'prune-builder: source path is outside the expected builder location: %s\n' "$source_root" >&2
    exit 1
    ;;
esac

mkdir -p -- "$staging_root" "$source_root"

is_build_id() {
  [[ "$1" =~ ^[0-9]{8}T[0-9]{6}Z-([0-9a-f]{12}|local)$ ]]
}

safe_remove_build_dir() {
  local root="$1"
  local path="$2"
  local name

  name="${path##*/}"
  if ! is_build_id "$name"; then
    printf 'prune-builder: refusing to remove unexpected directory: %s\n' "$path" >&2
    exit 1
  fi
  case "$path" in
    "$root"/"$name") ;;
    *)
      printf 'prune-builder: refusing unsafe removal path: %s\n' "$path" >&2
      exit 1
      ;;
  esac
  rm -rf -- "$path"
}

declare -A retained_staging=()
retained_staging["$current_build_id"]=1
completed_retained=0

mapfile -t staging_builds < <(
  find "$staging_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' |
    LC_ALL=C sort -r
)

for build_id in "${staging_builds[@]}"; do
  is_build_id "$build_id" || continue
  [[ -f "$staging_root/$build_id/build-manifest.json" ]] || continue
  if (( completed_retained < keep_completed )); then
    retained_staging["$build_id"]=1
    ((completed_retained += 1))
  fi
done

removed_staging=0
for build_id in "${staging_builds[@]}"; do
  is_build_id "$build_id" || continue
  if [[ -z "${retained_staging[$build_id]+present}" ]]; then
    safe_remove_build_dir "$staging_root" "$staging_root/$build_id"
    ((removed_staging += 1))
  fi
done

removed_sources=0
mapfile -t source_builds < <(
  find "$source_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' |
    LC_ALL=C sort
)
for build_id in "${source_builds[@]}"; do
  is_build_id "$build_id" || continue
  if [[ "$build_id" != "$current_build_id" || "$remove_current_sources" == true ]]; then
    safe_remove_build_dir "$source_root" "$source_root/$build_id"
    ((removed_sources += 1))
  fi
done

if [[ "$trim_pacman_cache" == 1 ]] &&
  command -v paccache >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
  sudo -n paccache -rk2 >/dev/null 2>&1 ||
    printf 'prune-builder: warning: could not trim retained package cache\n' >&2
  sudo -n paccache -ruk0 >/dev/null 2>&1 ||
    printf 'prune-builder: warning: could not trim uninstalled package cache\n' >&2
fi

available_kib="$(df -Pk -- "$builder_root" | awk 'NR == 2 {print $4}')"
required_kib=$((minimum_free_gib * 1024 * 1024))
if [[ ! "$available_kib" =~ ^[0-9]+$ ]]; then
  printf 'prune-builder: could not determine free space for %s\n' "$builder_root" >&2
  exit 1
fi
if (( available_kib < required_kib )); then
  available_gib=$((available_kib / 1024 / 1024))
  printf 'prune-builder: only %s GiB free; at least %s GiB is required before building\n' \
    "$available_gib" "$minimum_free_gib" >&2
  exit 1
fi

available_gib=$((available_kib / 1024 / 1024))
printf 'prune-builder: removed %s staging build(s) and %s source tree(s); %s GiB free\n' \
  "$removed_staging" "$removed_sources" "$available_gib"
