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
EXPECTED_PACKAGE_COUNT = 19


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


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    if data[:8] != b"\x89PNG\r\n\x1a\n" or len(data) < 24:
        fail(f"not a valid PNG: {path}")
    return int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big")


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
        source_type = entry.get("source_type", "aur")
        if source_type == "aur":
            if entry.get("aur_url") != f"https://aur.archlinux.org/{package}.git":
                fail(f"{package} AUR URL mismatch")
        elif source_type == "pinned-vcs":
            revisions = entry.get("source_revisions", {})
            if not revisions:
                fail(f"{package} has no pinned VCS revisions")
            for source_url, revision in revisions.items():
                if len(revision) != 40 or not re.fullmatch(r"[0-9a-f]{40}", revision):
                    fail(f"{package} has an invalid pinned revision for {source_url}")
                if revision not in text:
                    fail(f"{package} PKGBUILD does not contain pinned revision {revision}")
        elif source_type == "local":
            if entry.get("source_revisions", {}) != {}:
                fail(f"{package} local source must not declare remote revisions")
        else:
            fail(f"{package} has unknown source type {source_type}")
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
    for resume_guard in [
        "resume_build_id:",
        "inputs.resume_build_id == ''",
        "inputs.resume_build_id != ''",
        'scripts/finalize-build.sh "$RESUME_BUILD_ID"',
    ]:
        if resume_guard not in text:
            fail(f"build workflow missing guarded resume behavior: {resume_guard}")

    build_all = (REPO / "scripts" / "build-all.sh").read_text(encoding="utf-8")
    if '"$repo/scripts/finalize-build.sh" "$build_id"' not in build_all:
        fail("fresh builds do not use the shared finalization path")

    sign_packages = (REPO / "scripts" / "sign-packages.sh").read_text(
        encoding="utf-8"
    )
    if ".last_successful_build = $build_id" not in sign_packages:
        fail("published repository manifest is not stamped with the current build ID")


def validate_desktop_polish() -> None:
    launcher_patch = (
        REPO
        / "packages"
        / "aerothemeplasma-desktop-git"
        / "aero7-desktop-polish.patch"
    ).read_text(encoding="utf-8")
    for required in [
        "sorted: true",
        "showAllApps: true",
        "showAllAppsCategorized: false",
        'executableString: "control"',
        'itemIcon: "system-run"',
        "<default>execbin</default>",
        "existingPanels[existingIndex].remove()",
        "name=breeze-light",
        "BackgroundNormal=240,240,240",
        'color: "#f7f7f7"',
        'source: "../images/aero7-watermark.png"',
        "<default>46</default>",
    ]:
        if required not in launcher_patch:
            fail(f"Aero launcher polish is missing: {required}")
    if "model: rootModel.modelForRow(1)" in launcher_patch:
        fail("All Programs still points at a nonexistent child model")
    if launcher_patch.count('executable.exec("tux-manager")') < 3:
        fail("Task Manager launcher actions are not consistently wired")

    desktop_pkgbuild = (
        REPO / "packages" / "aerothemeplasma-desktop-git" / "PKGBUILD"
    ).read_text(encoding="utf-8")
    for required in [
        "aero7-start-orb.png",
        "aero7-start-orb-small.png",
        "aero7-watermark.png",
        "io.gitgud.wackyideas.SevenStart/contents/ui/orbs/orb.png",
        "io.gitgud.wackyideas.SevenStart/contents/ui/orbs/orb_small.png",
        "contents/images/aero7-watermark.png",
        "contents/images/watermark.png",
    ]:
        if required not in desktop_pkgbuild:
            fail(f"Aero7 Start branding is missing: {required}")

    desktop_assets = REPO / "packages" / "aerothemeplasma-desktop-git"
    expected_sizes = {
        "aero7-start-orb.png": (46, 138),
        "aero7-start-orb-small.png": (42, 126),
        "aero7-watermark.png": (350, 50),
    }
    for asset, expected_size in expected_sizes.items():
        actual_size = png_size(desktop_assets / asset)
        if actual_size != expected_size:
            fail(f"{asset} has size {actual_size}, expected {expected_size}")

    branded_packages = {
        "aero7-dolphin": ["Name=File Explorer"],
        "aero7-gwenview": ["Name=Photo Viewer", "Icon=multimedia-photo-viewer"],
        "tuxmanager": ["Name=Task Manager", "Icon=ksysguardd"],
    }
    for package, required_lines in branded_packages.items():
        pkgbuild = (REPO / "packages" / package / "PKGBUILD").read_text(
            encoding="utf-8"
        )
        for required in required_lines:
            if required not in pkgbuild:
                fail(f"{package} is missing desktop branding: {required}")

    run_desktop = (
        REPO / "packages" / "execbin" / "org.aero7.execbin.desktop"
    ).read_text(encoding="utf-8")
    if "Icon=org.aero7.execbin" not in run_desktop:
        fail("Run dialog does not use the current Aero7 application icon")

    glass_frame = (
        REPO / "companions" / "aero7-qt" / "include" / "Aero7Qt" / "glassframe.h"
    ).read_text(encoding="utf-8")
    for selector in [
        r'QWidget[aero7GlassRegion=\"true\"]',
        r'QWidget[aero7InsetContent=\"true\"]',
    ]:
        if selector not in glass_frame:
            fail(f"Aero7Qt frame styling is not scoped: {selector}")


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
    validate_desktop_polish()
    validate_no_secrets_or_assets()
    print("validate-repo: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
