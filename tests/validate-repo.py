#!/usr/bin/env python3
"""Repository source validation for Aero7 binary package infrastructure."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
SECRET_PATTERNS = [
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    re.compile(r"\bghp_[A-Za-z0-9_]{20,}\b"),
    re.compile(r"\bgithub_pat_[A-Za-z0-9_]{20,}\b"),
    re.compile(r"\b[A-Za-z0-9_]*TOKEN[A-Za-z0-9_]*\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{20,}", re.IGNORECASE),
]
PROPRIETARY_ASSET_PATTERNS = [
    re.compile(r"windows[ _-]?7[ _-]?wallpaper", re.IGNORECASE),
    re.compile(r"microsoft[ _-]?(logo|wallpaper|font|sound|icon)", re.IGNORECASE),
]
PRIVATE_KEY_SUFFIXES = {".key", ".p12", ".pfx", ".pem"}
EXPECTED_PACKAGE_COUNT = 10


def fail(message: str) -> None:
    raise SystemExit(f"validate-repo: {message}")


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_srcinfo(path: Path) -> dict[str, list[str]]:
    data: dict[str, list[str]] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or "=" not in line:
            continue
        key, value = [part.strip() for part in line.split("=", 1)]
        data.setdefault(key, []).append(value)
    return data


def validate_packages() -> None:
    package_manifest = load_json(REPO / "manifests" / "packages.json")
    lock = load_json(REPO / "manifests" / "upstream-lock.json")["packages"]
    required = package_manifest["required_packages"]
    denylist = set(package_manifest["denylist"])
    if len(required) != EXPECTED_PACKAGE_COUNT:
        fail(f"expected exactly {EXPECTED_PACKAGE_COUNT} required packages")
    if set(required) != set(lock):
        fail("upstream lock package set does not match required package set")

    package_dirs = {path.name for path in (REPO / "packages").iterdir() if path.is_dir()}
    if package_dirs != set(required):
        fail(f"package directories mismatch: {sorted(package_dirs)}")
    if denylist & package_dirs:
        fail("denied X11 package directory is present")

    for package in required:
        pkgdir = REPO / "packages" / package
        pkgbuild = pkgdir / "PKGBUILD"
        srcinfo_path = pkgdir / ".SRCINFO"
        if not pkgbuild.is_file():
            fail(f"{package} is missing PKGBUILD")
        if not srcinfo_path.is_file():
            fail(f"{package} is missing .SRCINFO")
        srcinfo = parse_srcinfo(srcinfo_path)
        if package not in srcinfo.get("pkgname", []):
            fail(f"{package} .SRCINFO pkgname mismatch")
        arch = set(srcinfo.get("arch", []))
        if not ({"x86_64", "any"} & arch):
            fail(f"{package} does not support x86_64 or any")
        text = pkgbuild.read_text(encoding="utf-8", errors="replace") + "\n" + srcinfo_path.read_text(encoding="utf-8", errors="replace")
        for denied in denylist:
            if denied in text:
                fail(f"{package} references denied package {denied}")
        entry = lock[package]
        if entry["aur_url"] != f"https://aur.archlinux.org/{package}.git":
            fail(f"{package} AUR URL mismatch")
        if sha256(pkgbuild) != entry["pkgbuild_sha256"]:
            fail(f"{package} PKGBUILD checksum mismatch")
        if sha256(srcinfo_path) != entry["srcinfo_sha256"]:
            fail(f"{package} .SRCINFO checksum mismatch")


def validate_workflows() -> None:
    build = REPO / ".github" / "workflows" / "build-packages.yml"
    if not build.is_file():
        fail("build-packages.yml is missing")
    text = build.read_text(encoding="utf-8")
    if "pull_request" in text or "pull_request_target" in text:
        fail("build workflow must not run on pull requests")
    for label in ["self-hosted", "linux", "x64", "arch", "aero7-builder"]:
        if label not in text:
            fail(f"build workflow missing runner label {label}")
    if "concurrency:" not in text or "aero7-package-builder" not in text:
        fail("build workflow missing protected concurrency group")


def validate_no_secrets_or_assets() -> None:
    for path in REPO.rglob("*"):
        if ".git" in path.parts:
            continue
        if path.is_dir():
            continue
        relative = path.relative_to(REPO)
        if path.suffix in PRIVATE_KEY_SUFFIXES:
            fail(f"private-key-like file is tracked: {relative}")
        text = path.read_text(encoding="utf-8", errors="ignore")
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                fail(f"secret-like content found in {relative}")
        for pattern in PROPRIETARY_ASSET_PATTERNS:
            if pattern.search(str(relative)) or pattern.search(text):
                fail(f"proprietary-asset reference found in {relative}")


def main() -> int:
    validate_packages()
    validate_workflows()
    validate_no_secrets_or_assets()
    print("validate-repo: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
