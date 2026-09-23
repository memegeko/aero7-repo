#!/usr/bin/env bash
set -Eeuo pipefail

build_id="${1:-}"
[[ "$build_id" =~ ^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{12}$ ]] || {
  printf 'activate-repository: invalid build ID\n' >&2
  exit 2
}

base="/home/admin/aero7-site/storage"
incoming="$base/pacman-incoming/$build_id.tar.zst"
releases="$base/pacman-releases"
public="$base/pacman-root/repo"
release="$releases/$build_id"
fingerprint="72C79ABBBBE96446DD3324042694BFE1090F4FD6"

[[ -f "$incoming" ]] || {
  printf 'activate-repository: incoming archive is missing\n' >&2
  exit 1
}
[[ ! -e "$release" ]] || {
  printf 'activate-repository: release already exists: %s\n' "$build_id" >&2
  exit 1
}

mkdir -p -- "$releases" "$public" "$base/pacman-locks"
exec 9>"$base/pacman-locks/publish.lock"
flock -n 9 || {
  printf 'activate-repository: another publication is active\n' >&2
  exit 1
}

stage="$(mktemp -d "$releases/.incoming-$build_id.XXXXXX")"
cleanup() {
  if [[ -d "$stage" ]]; then
    find "$stage" -depth -delete
  fi
}
trap cleanup EXIT
tar --zstd -xf "$incoming" -C "$stage" --no-same-owner --no-same-permissions

for required in x86_64/aero7.db x86_64/aero7.db.sig \
  x86_64/repository-manifest.json keys/aero7-repository.asc \
  expected-packages.txt build-manifest.json; do
  [[ -f "$stage/$required" ]] || {
    printf 'activate-repository: payload is missing %s\n' "$required" >&2
    exit 1
  }
done

keyring="$(mktemp -d "$releases/.keyring-$build_id.XXXXXX")"
trap 'find "$keyring" -depth -delete; cleanup' EXIT
chmod 700 "$keyring"
gpg --batch --homedir "$keyring" --import "$stage/keys/aero7-repository.asc" >/dev/null 2>&1
actual_fingerprint="$(gpg --batch --homedir "$keyring" --with-colons --list-keys | awk -F: '$1=="fpr"{print $10; exit}')"
[[ "$actual_fingerprint" == "$fingerprint" ]] || {
  printf 'activate-repository: signing-key fingerprint mismatch\n' >&2
  exit 1
}
gpg --batch --homedir "$keyring" --verify "$stage/x86_64/aero7.db.sig" "$stage/x86_64/aero7.db" >/dev/null 2>&1

actual_names="$stage/actual-packages.txt"
: > "$actual_names"
package_count=0
while IFS= read -r -d '' package_file; do
  [[ -f "$package_file.sig" ]] || {
    printf 'activate-repository: missing signature for %s\n' "${package_file##*/}" >&2
    exit 1
  }
  gpg --batch --homedir "$keyring" --verify "$package_file.sig" "$package_file" >/dev/null 2>&1
  bsdtar -xOf "$package_file" .PKGINFO | sed -n 's/^pkgname = //p' | head -1 >> "$actual_names"
  package_count=$((package_count + 1))
done < <(find "$stage/x86_64" -maxdepth 1 -type f -name '*.pkg.tar.zst' -print0 | sort -z)
sort -u -o "$actual_names" "$actual_names"
sort -u -o "$stage/expected-packages.txt" "$stage/expected-packages.txt"
diff -u "$stage/expected-packages.txt" "$actual_names"
[[ "$package_count" -eq "$(wc -l < "$stage/expected-packages.txt")" ]] || {
  printf 'activate-repository: package count mismatch\n' >&2
  exit 1
}

mv -- "$stage" "$release"
stage=""
ln -s -- "../../pacman-releases/$build_id/x86_64" "$public/.x86_64.next"
ln -s -- "../../pacman-releases/$build_id/keys" "$public/.keys.next"
mv -Tf -- "$public/.x86_64.next" "$public/x86_64"
mv -Tf -- "$public/.keys.next" "$public/keys"
printf '%s\n' "$build_id" > "$public/current-build-id"
chmod 644 "$public/current-build-id"
printf 'activate-repository: published %s with %s packages\n' "$build_id" "$package_count"
