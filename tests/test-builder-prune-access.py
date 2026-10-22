#!/usr/bin/env python3
"""Exercise the no-argument builder cleanup boundary without VM privileges."""

from __future__ import annotations

import importlib.machinery
import importlib.util
import os
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WRAPPER = ROOT / "ops/builder-prune/aero7-prune-builder-safe"
INSTALLER = ROOT / "ops/builder-prune/install.sh"
SUDOERS = ROOT / "ops/builder-prune/sudoers.aero7-prune-builder-safe"
HELPER = ROOT / "scripts/prune-builder.sh"

loader = importlib.machinery.SourceFileLoader("aero7_prune_safe", str(WRAPPER))
spec = importlib.util.spec_from_loader(loader.name, loader)
assert spec is not None
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


def rejects(callback, label: str) -> None:
    try:
        callback()
    except (module.CleanupError, OSError):
        return
    raise AssertionError(f"unsafe case was accepted: {label}")


with tempfile.TemporaryDirectory(prefix="aero7-prune-boundary-") as temporary:
    root = Path(temporary)
    current = root / "current-build-id"
    current.write_text("20261022T190800Z-78381489cee1\n")
    current.chmod(0o600)
    module.CURRENT_ID = current
    assert module.read_current_id(os.getuid()) == "20261022T190800Z-78381489cee1"

    current.chmod(0o620)
    rejects(lambda: module.read_current_id(os.getuid()), "group-writable build ID")
    current.chmod(0o600)
    current.write_text("../../home/admin\n")
    rejects(lambda: module.read_current_id(os.getuid()), "path-shaped build ID")
    current.write_text("20261022T190800Z-78381489cee1\n")
    link = root / "link"
    link.symlink_to(current)
    module.CURRENT_ID = link
    rejects(lambda: module.read_current_id(os.getuid()), "symlinked build ID")

    module.verify_directory(root, os.getuid())
    rejects(lambda: module.verify_directory(link, os.getuid()), "symlinked builder directory")
    root.chmod(0o720)
    rejects(lambda: module.verify_directory(root, os.getuid()), "group-writable builder directory")

    assert module.idle_runner_process("/bin/bash /home/aero7build/actions-runner/runsvc.sh")
    assert module.idle_runner_process("./externals/node20/bin/node ./bin/RunnerService.js")
    assert not module.idle_runner_process("./bin/Runner.Worker spawnclient")
    assert not module.idle_runner_process("bash scripts/build-package.sh aero7-programs-center-git")

    bundle = root / "bundle"
    bundle.mkdir()
    shutil.copy2(WRAPPER, bundle / "aero7-prune-builder-safe")
    shutil.copy2(HELPER, bundle / "prune-builder.sh")
    shutil.copy2(SUDOERS, bundle / "sudoers.aero7-prune-builder-safe")
    assert shutil.which("visudo"), "visudo is required to validate the installation boundary"
    checked = subprocess.run(["bash", str(INSTALLER), "--check", str(bundle)], capture_output=True, text=True)
    assert checked.returncode == 0, checked.stdout + checked.stderr
    (bundle / "prune-builder.sh").write_bytes(b"tampered helper\n")
    rejected = subprocess.run(["bash", str(INSTALLER), "--check", str(bundle)], capture_output=True, text=True)
    assert rejected.returncode != 0 and "checksum mismatch" in rejected.stderr

if os.geteuid() != 0:
    rejected = subprocess.run([str(WRAPPER)], capture_output=True, text=True)
    assert rejected.returncode != 0 and "narrow sudoers allowance" in rejected.stderr
    rejected_args = subprocess.run([str(WRAPPER), "--current-build-id", "anything"], capture_output=True, text=True)
    assert rejected_args.returncode != 0 and "accepts no arguments" in rejected_args.stderr

print("test-builder-prune-access: ok")
