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
COMPRESSED_BUILD_SUFFIXES = {".gz", ".zst"}
EXPECTED_PACKAGE_COUNT = 23


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
        'scripts/prune-builder.sh \\',
    ]:
        if resume_guard not in text:
            fail(f"build workflow missing guarded resume behavior: {resume_guard}")

    build_all = (REPO / "scripts" / "build-all.sh").read_text(encoding="utf-8")
    if '"$repo/scripts/finalize-build.sh" "$build_id"' not in build_all:
        fail("fresh builds do not use the shared finalization path")
    for retention_guard in [
        '"$repo/scripts/prune-builder.sh" --current-build-id "$build_id"',
        "--remove-current-sources",
    ]:
        if retention_guard not in build_all:
            fail(f"fresh builds are missing storage retention guard: {retention_guard}")

    sign_packages = (REPO / "scripts" / "sign-packages.sh").read_text(
        encoding="utf-8"
    )
    if ".last_successful_build = $build_id" not in sign_packages:
        fail("published repository manifest is not stamped with the current build ID")


def validate_desktop_polish() -> None:
    integration_dependencies = {
        "linux-control-panel": {
            "required": {"pacman-contrib", "fakeroot", "libnotify"},
            "forbidden": {"ufw", "firewalld"},
        },
        "aeroshell-smod-git": {
            "required": set(),
            "forbidden": {"pkgconf"},
        },
        "uac-polkit-agent-git": {
            "required": {"polkit-kde-agent"},
            "forbidden": set(),
        },
    }
    for package, policy in integration_dependencies.items():
        srcinfo = parse_srcinfo(REPO / "packages" / package / ".SRCINFO")
        dependencies = set(srcinfo.get("depends", []))
        missing = policy["required"] - dependencies
        forbidden = policy["forbidden"] & dependencies
        if missing:
            fail(f"{package} is missing runtime dependencies: {sorted(missing)}")
        if forbidden:
            fail(f"{package} has forbidden runtime dependencies: {sorted(forbidden)}")

    control_srcinfo = parse_srcinfo(
        REPO / "packages" / "linux-control-panel" / ".SRCINFO"
    )
    control_optional = set(control_srcinfo.get("optdepends", []))
    for prefix in ("firewalld:", "ufw:"):
        if not any(item.startswith(prefix) for item in control_optional):
            fail(f"linux-control-panel is missing optional firewall policy: {prefix}")

    smod_srcinfo = parse_srcinfo(
        REPO / "packages" / "aeroshell-smod-git" / ".SRCINFO"
    )
    if "pkgconf" not in set(smod_srcinfo.get("makedepends", [])):
        fail("aeroshell-smod-git must keep pkgconf as a build dependency")

    programs_pkgbuild = (
        REPO / "packages" / "aero7-programs-center-git" / "PKGBUILD"
    ).read_text(encoding="utf-8")
    if "aero7-offline-package-inventory.patch" not in programs_pkgbuild:
        fail("Programs Center does not preserve the offline package inventory")

    desktop_pkgbuild = (
        REPO / "packages" / "aerothemeplasma-desktop-git" / "PKGBUILD"
    ).read_text(encoding="utf-8")
    for required in [
        'url="https://gitgud.io/aero7-open-project/aerothemeplasma"',
        "#commit=8c7d82027dc82096eea769beab51cfd0e6390d91",
        '"${pkgname%}/LICENSE"',
        '"${pkgname%}/THIRD_PARTY.md"',
        "aero7-kwalletrc",
        '"$pkgdir/etc/xdg/kwalletrc"',
    ]:
        if required not in desktop_pkgbuild:
            fail(f"Aero7 desktop fork metadata is missing: {required}")
    for obsolete_patch in ["aero7-desktop-polish.patch", "aero7-search-sections.patch"]:
        if obsolete_patch in desktop_pkgbuild:
            fail(f"integrated desktop source still applies obsolete patch: {obsolete_patch}")

    for required_dependency in [
        "qterminal",
        "vlc",
        "spectacle",
        "kcalc",
        "featherpad",
    ]:
        if required_dependency not in desktop_pkgbuild:
            fail(f"Aero7 desktop application dependency is missing: {required_dependency}")

    for obsolete in [
        "aero7-start-orb.png",
        "aero7-start-orb-small.png",
    ]:
        if obsolete in desktop_pkgbuild:
            fail(f"desktop branding is still overlaid during packaging: {obsolete}")
    for required in [
        "'aero7-watermark.png'",
        'Assets/aero7-branding-r3.png',
        "'aero7-beta2-integration.patch'",
        "'Aero7OnScreenKeyboard.qml'",
        "'aero7-login-background.jpg'",
        "'aero7-sddm-runtime-test.py'",
        'patch -d "${pkgname%}" -Np1 < aero7-beta2-integration.patch',
        'SMOD/Aero7OnScreenKeyboard.qml',
        'for background_name in background default-background preview.png',
        'aero7-package-branding.png',
    ]:
        if required not in desktop_pkgbuild:
            fail(f"Aero7 SDDM branding package integration is missing: {required}")

    desktop_assets = REPO / "packages" / "aerothemeplasma-desktop-git"
    kwallet_defaults = (desktop_assets / "aero7-kwalletrc").read_text(encoding="utf-8")
    for required in ["[Wallet]", "Enabled=false", "First Use=false"]:
        if required not in kwallet_defaults:
            fail(f"KWallet system default is missing: {required}")
    expected_sizes = {"aero7-watermark.png": (350, 50)}
    for asset, expected_size in expected_sizes.items():
        actual_size = png_size(desktop_assets / asset)
        if actual_size != expected_size:
            fail(f"{asset} has size {actual_size}, expected {expected_size}")
    expected_desktop_asset_hashes = {
        "aero7-beta2-integration.patch": "9397da5031d7c29043b6c4344f06979342ea90b7af2d67f2f2811ef3af194d22",
        "Aero7OnScreenKeyboard.qml": "e56d78b54366bee688a4eece2a0a4bdf6f8a0f490d3319a4285f4734ade8a7bd",
        "aero7-login-background.jpg": "65e825c2dcc1b0c80d14896a6108199d825f8dc7b44724f22fe19d8b308fb7e7",
        "aero7-sddm-runtime-test.py": "bf7e44188d7a682d7aa0eddf865ced1569c0f518a8c04d47445d04e8571d0d9d",
    }
    for asset, expected_hash in expected_desktop_asset_hashes.items():
        actual_hash = sha256(desktop_assets / asset)
        if actual_hash != expected_hash:
            fail(f"{asset} hash {actual_hash} does not match accepted Beta 2 integration")

    retained_themes = {
        "aerothemeplasma-icons-git": "96950b8028a5d960cb683280fe5f1d9e33e6b8a2",
        "aerothemeplasma-sounds-git": "55d2f5fd15f53cccbbb13388941b930442db1159",
    }
    for package, commit in retained_themes.items():
        pkgbuild = (REPO / "packages" / package / "PKGBUILD").read_text(
            encoding="utf-8"
        )
        for required in [
            f"#commit={commit}",
            '"$pkgdir/usr/share/licenses/$pkgname/LICENSE"',
            '"$pkgdir/usr/share/licenses/$pkgname/README.md"',
        ]:
            if required not in pkgbuild:
                fail(f"{package} retention metadata is missing: {required}")

    sound_pkgbuild = (
        REPO / "packages" / "aerothemeplasma-sounds-git" / "PKGBUILD"
    ).read_text(encoding="utf-8")
    for required in [
        "${base//Windows 7/Aero7}",
        "${renamed//Windows/Aero7}",
        "Comment=$theme_name sound theme for Aero7",
    ]:
        if required not in sound_pkgbuild:
            fail(f"Aero7 sound-theme branding is missing: {required}")

    branded_packages = {
        "aero7-file-explorer": [
            "pkgdesc='Aero7 File Explorer",
            'ln -s aero7-file-explorer "$pkgdir/usr/bin/dolphin"',
        ],
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
    if "Icon=system-run" not in run_desktop:
        fail("Run desktop entry does not use the matching system Run icon")

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
        if path.is_dir() or path.is_symlink():
            continue
        relative = path.relative_to(REPO)
        if (len(relative.parts) >= 3
                and relative.parts[0] in {"packages", "retired-packages"}
                and relative.parts[2] in {"pkg", "src", "build"}):
            continue
        if path.suffix in PRIVATE_KEY_SUFFIXES:
            fail(f"private-key-like file is tracked: {relative}")
        # Local package and source archives can be several gigabytes and are
        # generated build products, not searchable repository source.  Their
        # package recipes and checksums are validated above.
        if path.suffix in COMPRESSED_BUILD_SUFFIXES:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                fail(f"secret-like content found in {relative}")
        for pattern in PROPRIETARY_ASSET_PATTERNS:
            if pattern.search(str(relative)):
                fail(f"proprietary-asset reference found in {relative}")
            # Legal and attribution documents must be able to identify the
            # third-party material they discuss. Continue scanning all other
            # source/configuration text for accidental asset references.
            if path.suffix.lower() not in {".md", ".txt"} and pattern.search(text):
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
