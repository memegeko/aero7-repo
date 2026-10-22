#!/usr/bin/env bash
set -Eeuo pipefail

mode="${1:-}"
bundle="${2:-}"
if [[ "$mode" != --check && "$mode" != --install ]] || [[ -z "$bundle" || "$#" -ne 2 ]]; then
  printf 'Usage: install.sh --check|--install BUNDLE_DIRECTORY\n' >&2
  exit 2
fi

wrapper_sha=15d6426a531895bf59fdea384f9bf2b29538d19e80025eb1b3504615915856bf
prior_wrapper_sha=7e2d7cbc59747d95ee52a9321033eaeace7de1ab9cc48beb8978ca2ace5e23fc
helper_sha=fcdf6671028473e16fbf59f2efe8bfa4037b7e2d33b955fe487096d7406e2b80
sudoers_sha=255c82dca13f7fc6b19b89f7d09a74f09f01b255862ab934e5c678a7fa6f71fd
wrapper_name=aero7-prune-builder-safe
helper_name=prune-builder.sh
sudoers_name=sudoers.aero7-prune-builder-safe

check_hash() {
  local path="$1" expected="$2" actual
  [[ -f "$path" && ! -L "$path" ]] || {
    printf 'install-builder-prune: missing or symlinked input: %s\n' "$path" >&2
    exit 1
  }
  actual="$(sha256sum "$path" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || {
    printf 'install-builder-prune: checksum mismatch: %s\n' "$path" >&2
    exit 1
  }
}

check_bundle() {
  local dir="$1"
  check_hash "$dir/$wrapper_name" "$wrapper_sha"
  check_hash "$dir/$helper_name" "$helper_sha"
  check_hash "$dir/$sudoers_name" "$sudoers_sha"
  visudo -cf "$dir/$sudoers_name"
  python -I - "$dir/$wrapper_name" <<'PY'
import ast
from pathlib import Path
import sys
ast.parse(Path(sys.argv[1]).read_text(encoding="utf-8"))
print("install-builder-prune: wrapper syntax verified")
PY
}

if [[ "$mode" == --check ]]; then
  check_bundle "$bundle"
  printf 'install-builder-prune: reviewed bundle checks passed\n'
  exit 0
fi

[[ "$(id -u)" -eq 0 ]] || {
  printf 'install-builder-prune: one-time installation requires root\n' >&2
  exit 1
}
[[ "$(realpath -- "$0")" == /root/install-aero7-prune-access.sh ]] || {
  printf 'install-builder-prune: run only the root-owned /root installer copy\n' >&2
  exit 1
}
if [[ "$(stat -c %u "$0")" -ne 0 ]] || [[ "$(stat -c %a "$0")" != 700 ]]; then
  printf 'install-builder-prune: installer ownership or mode is unsafe\n' >&2
  exit 1
fi

# Copy unprivileged uploads into root-owned tmpfs before verifying or installing;
# no file is executed as root from the writable upload directory.
private="$(mktemp -d /run/aero7-prune-install.XXXXXX)"
chmod 700 "$private"
cleanup() { find "$private" -depth -delete; }
trap cleanup EXIT
install -o root -g root -m 0700 "$bundle/$wrapper_name" "$private/$wrapper_name"
install -o root -g root -m 0700 "$bundle/$helper_name" "$private/$helper_name"
install -o root -g root -m 0600 "$bundle/$sudoers_name" "$private/$sudoers_name"
check_bundle "$private"

wrapper_target=/usr/local/sbin/aero7-prune-builder-safe
helper_target=/usr/local/libexec/aero7/prune-builder.sh
sudoers_target=/etc/sudoers.d/aero7-prune-builder-safe

for item in "$wrapper_target:$wrapper_sha" "$helper_target:$helper_sha" "$sudoers_target:$sudoers_sha"; do
  target="${item%%:*}"
  expected="${item#*:}"
  if [[ -e "$target" || -L "$target" ]]; then
    if [[ "$target" == "$wrapper_target" ]]; then
      [[ -f "$target" && ! -L "$target" ]] || {
        printf 'install-builder-prune: existing wrapper is not a regular file\n' >&2
        exit 1
      }
      actual="$(sha256sum "$target" | awk '{print $1}')"
      [[ "$actual" == "$wrapper_sha" || "$actual" == "$prior_wrapper_sha" ]] || {
        printf 'install-builder-prune: existing wrapper is not an approved version\n' >&2
        exit 1
      }
    else
      check_hash "$target" "$expected"
    fi
    [[ "$(stat -c %u:%g "$target")" == 0:0 ]] || {
      printf 'install-builder-prune: existing target is not root-owned: %s\n' "$target" >&2
      exit 1
    }
  fi
done

install -d -o root -g root -m 0755 /usr/local/libexec/aero7
install -o root -g root -m 0755 "$private/$helper_name" "$helper_target"
install -o root -g root -m 0755 "$private/$wrapper_name" "$wrapper_target"
install -o root -g root -m 0440 "$private/$sudoers_name" "$sudoers_target"
visudo -c

check_hash "$helper_target" "$helper_sha"
check_hash "$wrapper_target" "$wrapper_sha"
check_hash "$sudoers_target" "$sudoers_sha"
printf 'install-builder-prune: narrow no-argument sudo rule and root-owned helpers installed; cleanup was not run\n'
