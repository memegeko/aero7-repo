#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
builder_root="${AERO7_BUILDER_ROOT:-/srv/aero7-builder}"
staging_root="${AERO7_STAGING_DIR:-$builder_root/staging}"
commit="${GITHUB_SHA:-$(git -C "$repo" rev-parse --short=12 HEAD 2>/dev/null || printf local)}"
build_id="${AERO7_BUILD_ID:-$(date -u +%Y%m%dT%H%M%SZ)-${commit:0:12}}"
staging="$staging_root/$build_id"

if [[ "$(id -u)" -eq 0 ]]; then
  printf 'build-all: do not run package builds as root\n' >&2
  exit 1
fi

mkdir -p -- "$staging"
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

"$repo/scripts/sign-packages.sh" "$build_id"
"$repo/scripts/test-repository.sh" "$build_id"

python - "$repo" "$build_id" "$staging" <<'PY'
import hashlib
import json
import platform
import subprocess
import sys
from pathlib import Path

repo = Path(sys.argv[1])
build_id = sys.argv[2]
staging = Path(sys.argv[3])
packages = []
for path in sorted((staging / "packages").glob("*.pkg.tar.zst")):
    packages.append({
        "filename": path.name,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "size": path.stat().st_size,
    })
manifest = {
    "build_id": build_id,
    "build_date": subprocess.check_output(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"], text=True).strip(),
    "builder_kernel": platform.release(),
    "builder_arch": platform.machine(),
    "git_commit": subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD"], text=True).strip(),
    "packages": packages,
}
(staging / "build-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

printf 'build-all: staged complete build %s at %s\n' "$build_id" "$staging"
