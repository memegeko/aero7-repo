#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
build_id="${1:-}"
[[ -n "$build_id" ]] || {
  printf 'Usage: scripts/finalize-build.sh <build-id>\n' >&2
  exit 2
}

if [[ "$(id -u)" -eq 0 ]]; then
  printf 'finalize-build: do not finalize package builds as root\n' >&2
  exit 1
fi

builder_root="${AERO7_BUILDER_ROOT:-/srv/aero7-builder}"
staging_root="${AERO7_STAGING_DIR:-$builder_root/staging}"
staging="$staging_root/$build_id"

case "$staging" in
  "$builder_root"/staging/*) ;;
  *)
    printf 'finalize-build: refusing unsafe staging path: %s\n' "$staging" >&2
    exit 1
    ;;
esac

[[ -d "$staging/packages" ]] || {
  printf 'finalize-build: package staging directory missing: %s/packages\n' "$staging" >&2
  exit 1
}

source_commit="${AERO7_SOURCE_COMMIT:-}"
if [[ -z "$source_commit" ]]; then
  build_suffix="${build_id##*-}"
  if [[ "$build_suffix" =~ ^[0-9a-f]{12}$ ]] && git -C "$repo" cat-file -e "${build_suffix}^{commit}" 2>/dev/null; then
    source_commit="$(git -C "$repo" rev-parse "${build_suffix}^{commit}")"
  else
    source_commit="$(git -C "$repo" rev-parse HEAD)"
  fi
fi

[[ "$source_commit" =~ ^[0-9a-f]{40}$ ]] || {
  printf 'finalize-build: invalid source commit: %s\n' "$source_commit" >&2
  exit 1
}

"$repo/scripts/sign-packages.sh" "$build_id"
"$repo/scripts/test-repository.sh" "$build_id"

python - "$build_id" "$staging" "$source_commit" <<'PY'
import hashlib
import json
import platform
import subprocess
import sys
from pathlib import Path

build_id = sys.argv[1]
staging = Path(sys.argv[2])
source_commit = sys.argv[3]
packages = []
for path in sorted((staging / "packages").glob("*.pkg.tar.zst")):
    packages.append({
        "filename": path.name,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "size": path.stat().st_size,
    })
manifest = {
    "build_id": build_id,
    "build_date": subprocess.check_output(
        ["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"], text=True
    ).strip(),
    "builder_kernel": platform.release(),
    "builder_arch": platform.machine(),
    "git_commit": source_commit,
    "packages": packages,
}
(staging / "build-manifest.json").write_text(
    json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
)
PY

printf 'finalize-build: signed and validated %s at %s\n' "$build_id" "$staging"
