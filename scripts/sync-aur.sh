#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
workdir="$(mktemp -d)"

cleanup() {
  rm -rf -- "$workdir"
}
trap cleanup EXIT

cd "$repo"
mapfile -t packages < <(jq -r '.required_packages[]' manifests/packages.json)
for package in "${packages[@]}"; do
  git clone --quiet "https://aur.archlinux.org/${package}.git" "$workdir/$package"
  printf '%s %s\n' "$package" "$(git -C "$workdir/$package" rev-parse HEAD)"
done

printf 'sync-aur: review output and update manifests/upstream-lock.json intentionally\n'
