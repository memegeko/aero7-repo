#!/usr/bin/env python3
"""Stage one Programs Center update over an exact, signed public release.

This script only creates a private staging directory. It never activates the
website repository. The existing website publisher must perform that step
after the signed staging directory has passed its normal release gate.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
TARGET = "aero7-programs-center-git"
BUILD_ID = re.compile(r"[0-9]{8}T[0-9]{6}Z-[0-9a-f]{12}\Z")
SHA256 = re.compile(r"[0-9a-f]{64}\Z")
DB_FILES = ("aero7.db.tar.zst", "aero7.files.tar.zst")
ALIASES = ("aero7.db", "aero7.files")


class DeltaError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise DeltaError(message)


def command(*args: str, cwd: Path | None = None) -> str:
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    if result.returncode:
        raise DeltaError(f"{' '.join(args[:2])}: {result.stderr.strip() or result.stdout.strip()}")
    return result.stdout


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def metadata(package: Path, member: str) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    for line in command("bsdtar", "-xOf", str(package), member).splitlines():
        if " = " in line and not line.startswith("#"):
            key, value = line.split(" = ", 1)
            result.setdefault(key, []).append(value)
    return result


def one(fields: dict[str, list[str]], key: str) -> str:
    values = fields.get(key, [])
    require(len(values) == 1, f"expected one {key} field")
    return values[0]


def db_fields(data: bytes) -> dict[str, str]:
    fields: dict[str, str] = {}
    for chunk in data.decode().strip().split("\n\n"):
        lines = chunk.splitlines()
        require(len(lines) >= 2 and lines[0].startswith("%") and lines[0].endswith("%"),
                "malformed repository desc entry")
        fields[lines[0].strip("%")] = "\n".join(lines[1:])
    return fields


def archive_entries(path: Path, suffix: str) -> dict[str, bytes]:
    entries: dict[str, bytes] = {}
    with tarfile.open(path, "r:*") as archive:
        for member in archive:
            if not member.name.endswith("/" + suffix):
                continue
            ident = member.name.split("/", 1)[0]
            require(ident not in entries, f"duplicate {ident} in {path.name}")
            stream = archive.extractfile(member)
            require(stream is not None, f"unreadable {member.name}")
            entries[ident] = stream.read()
    return entries


@dataclass
class Audit:
    build_id: str
    fingerprint: str
    packages: dict[str, Path]
    versions: dict[str, str]
    desc: dict[str, bytes]
    files: dict[str, bytes]


def verify_signatures(release: Path, packages: dict[str, Path]) -> None:
    with tempfile.TemporaryDirectory(prefix="aero7-release-gpg-") as home:
        os.chmod(home, 0o700)
        key = release / "keys/aero7-repository.asc"
        command("gpg", "--batch", "--homedir", home, "--import", str(key))
        for item in (*DB_FILES, *ALIASES):
            data = release / "x86_64" / item
            command("gpg", "--batch", "--homedir", home, "--verify", str(data) + ".sig", str(data))
        for package in packages.values():
            command("gpg", "--batch", "--homedir", home, "--verify", str(package) + ".sig", str(package))


def audit(release: Path, expected_id: str, expected_db_sha: str | None, signed: bool) -> Audit:
    require(BUILD_ID.fullmatch(expected_id) is not None, "invalid expected build ID")
    require(release.is_dir(), f"release directory missing: {release}")
    require(not any(path.is_symlink() for path in release.rglob("*")), "release contains a symlink")
    db = release / "x86_64/aero7.db.tar.zst"
    files_db = release / "x86_64/aero7.files.tar.zst"
    require(db.is_file() and files_db.is_file(), "repository database missing")
    if expected_db_sha is not None:
        require(SHA256.fullmatch(expected_db_sha) is not None, "invalid expected database SHA256")
        require(digest(db) == expected_db_sha, "repository database differs from pinned public base")
    for source, alias in zip(DB_FILES, ALIASES):
        require((release / "x86_64" / source).read_bytes() == (release / "x86_64" / alias).read_bytes(),
                f"{alias} differs from {source}")

    manifest = json.loads((release / "x86_64/repository-manifest.json").read_text())
    build = json.loads((release / "build-manifest.json").read_text())
    require(manifest["last_successful_build"] == expected_id, "repository manifest build ID mismatch")
    require(build["build_id"] == expected_id, "build manifest build ID mismatch")
    require(manifest["package_set_complete"] is (signed is True), "package completeness marker mismatch")
    fingerprint = manifest["signing_fingerprint"]
    expected_fingerprint = json.loads((REPO / "manifests/repository-manifest.json").read_text())["signing_fingerprint"]
    require(fingerprint == expected_fingerprint, "repository signing fingerprint changed")
    key = release / "keys/aero7-repository.asc"
    fprs = command("gpg", "--batch", "--show-keys", "--with-colons", str(key))
    actual_fprs = [row.split(":")[9] for row in fprs.splitlines() if row.startswith("fpr:")]
    require(actual_fprs and actual_fprs[0] == fingerprint, "public key fingerprint mismatch")

    expected_names = set(json.loads((REPO / "manifests/packages.json").read_text())["required_packages"])
    listed_names = set((release / "expected-packages.txt").read_text().splitlines())
    require(len(expected_names) == 23 and listed_names == expected_names, "expected package set mismatch")
    package_paths = sorted((release / "x86_64").glob("*.pkg.tar.zst"))
    require(len(package_paths) == 23, "expected exactly 23 package archives")
    packages: dict[str, Path] = {}
    versions: dict[str, str] = {}
    for package in package_paths:
        fields = metadata(package, ".PKGINFO")
        name, version = one(fields, "pkgname"), one(fields, "pkgver")
        require(name in expected_names and name not in packages, f"unexpected or duplicate package: {name}")
        require(package.name.startswith(name + "-"), f"package filename disagrees with {name}")
        if signed:
            require(Path(str(package) + ".sig").is_file(), f"missing package signature: {package.name}")
        packages[name], versions[name] = package, version
    require(set(packages) == expected_names, "release package names do not match allowlist")

    declared = {entry["filename"]: entry for entry in build["packages"]}
    require(len(declared) == 23, "build manifest package count mismatch")
    for package in packages.values():
        entry = declared.get(package.name)
        require(entry is not None and entry["sha256"] == digest(package) and entry["size"] == package.stat().st_size,
                f"build manifest mismatch: {package.name}")

    desc_by_id = archive_entries(db, "desc")
    files_by_id = archive_entries(files_db, "files")
    require(len(desc_by_id) == 23 and set(files_by_id) == set(desc_by_id), "database package set mismatch")
    desc: dict[str, bytes] = {}
    files: dict[str, bytes] = {}
    for ident, data in desc_by_id.items():
        fields = db_fields(data)
        name = fields["NAME"]
        require(name in packages and name not in desc, f"unexpected database entry: {name}")
        require(fields["VERSION"] == versions[name], f"database version mismatch: {name}")
        require(fields["FILENAME"] == packages[name].name, f"database filename mismatch: {name}")
        require(fields["SHA256SUM"] == digest(packages[name]), f"database package hash mismatch: {name}")
        desc[name], files[name] = data, files_by_id[ident]
    require(set(desc) == expected_names, "database entries do not match package files")

    if signed:
        verify_signatures(release, packages)
    return Audit(expected_id, fingerprint, packages, versions, desc, files)


def recipe_version() -> str:
    lines = (REPO / f"packages/{TARGET}/.SRCINFO").read_text().splitlines()
    fields = {key: value for line in lines if line.startswith("\t") and " = " in line
              for key, value in [line.strip().split(" = ", 1)]}
    version = fields["pkgver"]
    release = fields["pkgrel"]
    epoch = fields.get("epoch")
    return f"{epoch + ':' if epoch else ''}{version}-{release}"


def check_candidate(package: Path, base: Audit, signed: bool) -> str:
    require(package.is_file() and not package.is_symlink(), "candidate package missing or symlinked")
    info = metadata(package, ".PKGINFO")
    version = recipe_version()
    require(one(info, "pkgname") == TARGET, "candidate is not Programs Center")
    require(one(info, "pkgver") == version, "candidate version differs from reviewed recipe")
    require(one(info, "arch") == "x86_64", "candidate architecture mismatch")
    # makepkg keeps the epoch in the archive filename (for example, 1:0.2.0).
    require(package.name == f"{TARGET}-{version}-x86_64.pkg.tar.zst",
            "candidate filename differs from package metadata")
    require(int(command("vercmp", version, base.versions[TARGET]).strip()) > 0,
            "candidate would not upgrade the public Programs Center")
    if signed:
        build = metadata(package, ".BUILDINFO")
        lock = json.loads((REPO / "manifests/upstream-lock.json").read_text())["packages"][TARGET]
        require(one(build, "pkgbuild_sha256sum") == lock["pkgbuild_sha256"],
                "candidate was not built from the reviewed PKGBUILD")
        require(one(build, "buildtool") == "devtools", "candidate was not built with devtools")
        require(one(build, "pkgver") == version, "candidate build metadata version mismatch")
    return version


def signing_arguments(fingerprint: str) -> list[str]:
    require(os.environ.get("AERO7_SIGNING_FINGERPRINT") == fingerprint,
            "AERO7_SIGNING_FINGERPRINT does not match the public key")
    secret_rows = command("gpg", "--batch", "--with-colons", "--list-secret-keys", fingerprint)
    require(any(row.startswith("fpr:") and row.split(":")[9] == fingerprint
                for row in secret_rows.splitlines()), "repository signing key unavailable")
    args = ["gpg", "--batch", "--yes", "--local-user", fingerprint]
    passphrase_file = os.environ.get("AERO7_GPG_PASSPHRASE_FILE")
    if not passphrase_file:
        default = Path.home() / ".gnupg/aero7-repository.passphrase"
        if default.is_file():
            passphrase_file = str(default)
    if passphrase_file:
        require(Path(passphrase_file).is_file(), "signing passphrase file missing")
        args.extend(["--pinentry-mode", "loopback", "--passphrase-file", passphrase_file])
    return args


def stage_release(args: argparse.Namespace) -> None:
    require(BUILD_ID.fullmatch(args.build_id) is not None, "invalid new build ID")
    require(args.build_id != args.base_id, "new build ID must differ from public base")
    base = audit(args.base, args.base_id, args.base_db_sha, signed=True)
    version = check_candidate(args.package, base, signed=not args.dry_run)
    stage = args.stage.resolve()
    require(not stage.exists(), f"staging path already exists: {stage}")
    if not args.dry_run:
        expected_root = Path(os.environ.get("AERO7_BUILDER_ROOT", "/srv/aero7-builder")).resolve() / "staging"
        require(stage == expected_root / args.build_id, "signed stage must be under the dedicated builder staging root")
        require(os.geteuid() != 0, "do not stage packages as root")
        sign_args = signing_arguments(base.fingerprint)
    else:
        sign_args = []

    stage.mkdir(parents=True)
    (stage / "INCOMPLETE_DO_NOT_PUBLISH").write_text("Staging has not passed validation.\n")
    public = stage / "public"
    shutil.copytree(args.base, public, symlinks=False)
    x86 = public / "x86_64"
    old = base.packages[TARGET]
    (x86 / old.name).unlink()
    (x86 / (old.name + ".sig")).unlink()
    new = x86 / args.package.name
    shutil.copy2(args.package, new)
    if not args.dry_run:
        command(*sign_args, "--detach-sign", "--output", str(new) + ".sig", str(new))

    command("repo-add", "--nocolor", str(x86 / DB_FILES[0]), str(new))
    for name in (*DB_FILES, *ALIASES):
        for suffix in (".old", ".old.sig", ".sig"):
            path = x86 / (name + suffix)
            if path.exists() or path.is_symlink():
                path.unlink()
    for name in DB_FILES:
        if not args.dry_run:
            path = x86 / name
            command(*sign_args, "--detach-sign", "--output", str(path) + ".sig", str(path))
    for source, alias in zip(DB_FILES, ALIASES):
        alias_path = x86 / alias
        if alias_path.exists() or alias_path.is_symlink():
            alias_path.unlink()
        shutil.copy2(x86 / source, alias_path)
        if not args.dry_run:
            shutil.copy2(x86 / (source + ".sig"), x86 / (alias + ".sig"))

    manifest = json.loads((public / "x86_64/repository-manifest.json").read_text())
    manifest["last_successful_build"] = args.build_id
    manifest["base_build_id"] = args.base_id
    manifest["updated_package"] = TARGET
    if args.dry_run:
        manifest["status"] = "dry-run-do-not-publish"
        manifest["package_set_complete"] = False
    (public / "x86_64/repository-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    (public / "base-build-id").write_text(args.base_id + "\n")

    packages = sorted(x86.glob("*.pkg.tar.zst"))
    build_manifest = {
        "build_id": args.build_id,
        "build_date": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "builder_kernel": platform.release(),
        "builder_arch": platform.machine(),
        "git_commit": command("git", "-C", str(REPO), "rev-parse", "HEAD").strip(),
        "base_build_id": args.base_id,
        "updated_package": TARGET,
        "packages": [{"filename": p.name, "sha256": digest(p), "size": p.stat().st_size} for p in packages],
    }
    for path in (stage / "build-manifest.json", public / "build-manifest.json"):
        path.write_text(json.dumps(build_manifest, indent=2) + "\n")
    (public / "actual-packages.txt").write_text("\n".join(sorted(
        one(metadata(p, ".PKGINFO"), "pkgname") for p in packages)) + "\n")

    current = audit(public, args.build_id, None, signed=not args.dry_run) if not args.dry_run else audit_dry_run(public, args.build_id)
    verify_delta(base, current, args.package, signed=not args.dry_run)
    if not args.dry_run:
        (stage / "INCOMPLETE_DO_NOT_PUBLISH").unlink()
    print(f"programs-center-delta: {'DRY RUN' if args.dry_run else 'SIGNED STAGE'} {args.build_id}; "
          f"22 unchanged archives, signatures, versions and database entries verified; {TARGET}={version}")


def verify_delta(base: Audit, current: Audit, candidate: Path, signed: bool) -> None:
    """Require byte-identical non-target archives, sigs and DB entries."""
    require(base.build_id != current.build_id, "delta did not advance the build ID")
    for name in base.packages.keys() - {TARGET}:
        before, after = base.packages[name], current.packages[name]
        require(before.name == after.name and digest(before) == digest(after), f"unchanged package altered: {name}")
        require(digest(Path(str(before) + ".sig")) == digest(Path(str(after) + ".sig")),
                f"unchanged signature altered: {name}")
        require(base.versions[name] == current.versions[name], f"unchanged version altered: {name}")
        require(base.desc[name] == current.desc[name], f"unchanged database desc altered: {name}")
        require(base.files[name] == current.files[name], f"unchanged database files entry altered: {name}")
    expected_version = check_candidate(candidate, base, signed=signed)
    require(current.versions[TARGET] == expected_version, "Programs Center version mismatch after database update")
    require(digest(current.packages[TARGET]) == digest(candidate), "Programs Center archive differs from candidate")
    require(base.desc[TARGET] != current.desc[TARGET] and base.files[TARGET] != current.files[TARGET],
            "Programs Center database entries did not change")


def verify_signed_stage(args: argparse.Namespace) -> None:
    require(not (args.stage / "INCOMPLETE_DO_NOT_PUBLISH").exists(), "staging is incomplete")
    base = audit(args.base, args.base_id, args.base_db_sha, signed=True)
    current = audit(args.stage / "public", args.build_id, None, signed=True)
    manifest = json.loads((args.stage / "public/x86_64/repository-manifest.json").read_text())
    build = json.loads((args.stage / "build-manifest.json").read_text())
    require(manifest.get("base_build_id") == args.base_id and build.get("base_build_id") == args.base_id,
            "staging base build ID mismatch")
    require((args.stage / "public/base-build-id").read_text().strip() == args.base_id,
            "website base build marker mismatch")
    require(manifest.get("updated_package") == TARGET and build.get("updated_package") == TARGET,
            "staging target identity mismatch")
    require((args.stage / "public/build-manifest.json").read_bytes() ==
            (args.stage / "build-manifest.json").read_bytes(), "staging build manifests differ")
    verify_delta(base, current, current.packages[TARGET], signed=True)
    print(f"programs-center-delta: signed delta {args.build_id} verified; "
          f"only {TARGET} changes; 22 other archives, signatures and DB entries are identical")


def audit_dry_run(release: Path, expected_id: str) -> Audit:
    # An unsigned dry run cannot be activated: the public DB signatures and the
    # replacement package signature are deliberately absent.
    manifest_path = release / "x86_64/repository-manifest.json"
    manifest = json.loads(manifest_path.read_text())
    require(manifest["status"] == "dry-run-do-not-publish", "dry-run marker missing")
    require(manifest["package_set_complete"] is False, "dry-run set marked complete")
    return audit(release, expected_id, None, signed=False)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="operation", required=True)
    inspect = sub.add_parser("audit-base", help="verify the signed public snapshot")
    inspect.add_argument("--base", type=Path, required=True)
    inspect.add_argument("--base-id", required=True)
    inspect.add_argument("--base-db-sha", required=True)
    stage = sub.add_parser("stage", help="assemble one-package delta; never publish")
    stage.add_argument("--base", type=Path, required=True)
    stage.add_argument("--base-id", required=True)
    stage.add_argument("--base-db-sha", required=True)
    stage.add_argument("--package", type=Path, required=True)
    stage.add_argument("--stage", type=Path, required=True)
    stage.add_argument("--build-id", required=True)
    stage.add_argument("--dry-run", action="store_true")
    verify = sub.add_parser("verify-delta", help="verify a completed signed delta before publication")
    verify.add_argument("--base", type=Path, required=True)
    verify.add_argument("--base-id", required=True)
    verify.add_argument("--base-db-sha", required=True)
    verify.add_argument("--stage", type=Path, required=True)
    verify.add_argument("--build-id", required=True)
    args = parser.parse_args()
    try:
        if args.operation == "audit-base":
            result = audit(args.base, args.base_id, args.base_db_sha, signed=True)
            print(f"programs-center-delta: signed base {result.build_id} verified; "
                  f"{len(result.packages)} packages; Programs Center {result.versions[TARGET]}")
        elif args.operation == "stage":
            stage_release(args)
        else:
            verify_signed_stage(args)
    except (DeltaError, KeyError, OSError, tarfile.TarError, ValueError) as error:
        print(f"programs-center-delta: {error}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
