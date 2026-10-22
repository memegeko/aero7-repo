#!/usr/bin/env python3
"""Check the real epoch-bearing package filename accepted by makepkg."""

import importlib.util
import sys
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace


script = Path(__file__).resolve().parents[1] / "scripts/programs-center-delta.py"
spec = importlib.util.spec_from_file_location("programs_center_delta", script)
assert spec is not None and spec.loader is not None
delta = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = delta
spec.loader.exec_module(delta)

version = "1:0.2.0.r22.g051fea3-1"
delta.recipe_version = lambda: version
delta.metadata = lambda *_: {
    "pkgname": [delta.TARGET],
    "pkgver": [version],
    "arch": ["x86_64"],
}
delta.command = lambda *_: "1"
base = SimpleNamespace(versions={delta.TARGET: "0.1.0.r12.g0405a2e-4"})

with TemporaryDirectory(prefix="aero7-delta-name-") as directory:
    accepted = Path(directory) / f"{delta.TARGET}-{version}-x86_64.pkg.tar.zst"
    accepted.write_bytes(b"fixture")
    assert delta.check_candidate(accepted, base, signed=False) == version

    stripped = Path(directory) / f"{delta.TARGET}-{version.split(':', 1)[1]}-x86_64.pkg.tar.zst"
    stripped.write_bytes(b"fixture")
    try:
        delta.check_candidate(stripped, base, signed=False)
    except delta.DeltaError as error:
        assert "filename" in str(error)
    else:
        raise AssertionError("epoch-stripped package name was accepted")

print("test-programs-center-delta-filename: ok")
