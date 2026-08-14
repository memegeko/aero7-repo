#!/usr/bin/env python3
"""Prevent package validation jobs from silently becoming public releases."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FINAL_PHRASE = "PUBLISH-AERO7-FINAL"


def require(text: str, needle: str, source: str) -> None:
    if needle not in text:
        raise SystemExit(f"{source}: missing release gate: {needle}")


build_path = ROOT / ".github/workflows/build-packages.yml"
deploy_path = ROOT / ".github/workflows/deploy-pages.yml"
build = build_path.read_text(encoding="utf-8")
deploy = deploy_path.read_text(encoding="utf-8")

require(build, "final_release_confirmation:", str(build_path))
require(
    build,
    f"if: inputs.final_release_confirmation == '{FINAL_PHRASE}'",
    str(build_path),
)
if build.count(f"if: inputs.final_release_confirmation == '{FINAL_PHRASE}'") != 2:
    raise SystemExit(
        f"{build_path}: final promotion and artifact upload must both be gated"
    )
if "      promote:" in build:
    raise SystemExit(f"{build_path}: obsolete boolean promotion control is unsafe")

require(deploy, "workflow_dispatch:", str(deploy_path))
require(deploy, "final_release_confirmation:", str(deploy_path))
require(
    deploy,
    f"if: inputs.final_release_confirmation == '{FINAL_PHRASE}'",
    str(deploy_path),
)
if "workflow_run:" in deploy:
    raise SystemExit(f"{deploy_path}: automatic deployment trigger is forbidden")
if "github.event.workflow_run" in deploy:
    raise SystemExit(f"{deploy_path}: deployment must use an explicitly approved run ID")

print("test-release-gates: ok")
