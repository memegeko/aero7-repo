#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
package="${1:-}"
build_id="${2:-}"

usage() {
  printf 'Usage: scripts/build-package.sh <package> <build-id>\n' >&2
}

[[ -n "$package" && -n "$build_id" ]] || {
  usage
  exit 2
}

if [[ "$(id -u)" -eq 0 ]]; then
  printf 'build-package: do not run this script as root\n' >&2
  exit 1
fi

packages_json="$repo/manifests/packages.json"
python - "$packages_json" "$package" <<'PY'
import json
import sys
manifest = json.load(open(sys.argv[1], encoding="utf-8"))
package = sys.argv[2]
if package not in manifest["required_packages"]:
    raise SystemExit(f"build-package: package is not allowlisted: {package}")
PY

for command in mkarchroot makechrootpkg repo-add gpg namcap jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'build-package: required command missing on builder: %s\n' "$command" >&2
    exit 1
  fi
done

builder_root="${AERO7_BUILDER_ROOT:-/srv/aero7-builder}"
chroot_dir="${AERO7_CHROOT_DIR:-$builder_root/chroots/extra-x86_64}"
staging_root="${AERO7_STAGING_DIR:-$builder_root/staging}"
source_root="${AERO7_SOURCE_DIR:-$builder_root/sources}"
log_root="${AERO7_LOG_DIR:-$builder_root/logs}"
jobs="${AERO7_MAKEFLAGS_JOBS:-$(nproc)}"

case "$staging_root/$build_id" in
  "$builder_root"/staging/*) ;;
  *)
    printf 'build-package: refusing unsafe staging path: %s/%s\n' "$staging_root" "$build_id" >&2
    exit 1
    ;;
esac

mkdir -p -- "$staging_root/$build_id/packages" "$staging_root/$build_id/namcap" "$source_root/$build_id" "$log_root"

workdir="$source_root/$build_id/$package"
rm -rf -- "$workdir"
mkdir -p -- "$workdir"
cp -a "$repo/packages/$package/." "$workdir/"

if [[ ! -d "$chroot_dir/root" ]]; then
  mkdir -p -- "$chroot_dir"
  sudo mkarchroot "$chroot_dir/root" base-devel
else
  sudo arch-nspawn "$chroot_dir/root" pacman -Syu --noconfirm
fi

local_inputs=()
while IFS= read -r -d '' built_pkg; do
  local_inputs+=("-I" "$built_pkg")
done < <(find "$staging_root/$build_id/packages" -maxdepth 1 -type f -name '*.pkg.tar.zst' -print0 | sort -z)

export MAKEFLAGS="-j$jobs"
log_file="$log_root/${build_id}-${package}.log"
(
  cd "$workdir"
  makepkg --verifysource
  sudo makechrootpkg -c -r "$chroot_dir" "${local_inputs[@]}"
) 2>&1 | tee "$log_file"

outputs=()
while IFS= read -r -d '' candidate; do
  candidate_name="$(pacman -Qp "$candidate" 2>/dev/null | awk '{print $1}')"
  [[ "$candidate_name" == "$package" ]] || continue
  outputs+=("$candidate")
done < <(find "$workdir" -maxdepth 1 -type f -name '*.pkg.tar.zst' -print0 | sort -z)
if [[ "${#outputs[@]}" -eq 0 ]]; then
  printf 'build-package: no package output found for %s\n' "$package" >&2
  exit 1
fi
if [[ "${#outputs[@]}" -gt 1 ]]; then
  printf 'build-package: multiple package outputs found for %s\n' "$package" >&2
  printf '%s\n' "${outputs[@]}" >&2
  exit 1
fi

output="${outputs[0]}"
pkg_name="$(pacman -Qp "$output" 2>/dev/null | awk '{print $1}')"
if [[ "$pkg_name" != "$package" ]]; then
  printf 'build-package: package name mismatch: expected %s, got %s\n' "$package" "${pkg_name:-unknown}" >&2
  exit 1
fi

case "$pkg_name" in
  aerothemeplasma-desktop-x11-git|aeroshell-kwin-components-x11-git|aeroshell-smodglow-x11-git|kwin-x11|plasma-x11-session)
    printf 'build-package: denied X11 package produced: %s\n' "$pkg_name" >&2
    exit 1
    ;;
esac

namcap "$output" >"$staging_root/$build_id/namcap/$package.txt" || true
cp -a "$output" "$staging_root/$build_id/packages/"
printf 'build-package: built %s\n' "$output"
