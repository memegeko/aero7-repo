#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

cd "$repo"

python scripts/dependency-order.py --write
python tests/validate-repo.py

if command -v makepkg >/dev/null 2>&1; then
  while IFS= read -r -d '' pkgbuild; do
    pkgdir="$(dirname -- "$pkgbuild")"
    tmp="$(mktemp)"
    (
      cd "$pkgdir"
      makepkg --printsrcinfo >"$tmp"
    )
    if ! diff -u "$pkgdir/.SRCINFO" "$tmp"; then
      printf 'verify-sources: .SRCINFO is stale for %s\n' "$pkgdir" >&2
      exit 1
    fi
    rm -- "$tmp"
  done < <(find packages -mindepth 2 -maxdepth 2 -name PKGBUILD -print0 | sort -z)
else
  printf 'verify-sources: makepkg not installed; skipping .SRCINFO regeneration check\n' >&2
fi

for script in scripts/*.sh; do
  bash -n "$script"
done

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck scripts/*.sh
else
  printf 'verify-sources: shellcheck not installed; skipping ShellCheck\n' >&2
fi

python -m py_compile scripts/dependency-order.py tests/validate-repo.py
printf 'verify-sources: ok\n'
