#!/usr/bin/env python3
"""A binary-only update may retain paths, but its database must match the archive."""

import importlib.util
import io
import sys
import tarfile
from pathlib import Path
from tempfile import TemporaryDirectory


script = Path(__file__).resolve().parents[1] / "scripts/programs-center-delta.py"
spec = importlib.util.spec_from_file_location("programs_center_delta", script)
assert spec is not None and spec.loader is not None
delta = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = delta
spec.loader.exec_module(delta)


def rejected(action, phrase):
    try:
        action()
    except delta.DeltaError as error:
        assert phrase in str(error), str(error)
    else:
        raise AssertionError(f"expected rejection containing {phrase!r}")


with TemporaryDirectory(prefix="aero7-delta-metadata-") as directory:
    root = Path(directory)
    old = root / "old.pkg"
    new = root / "new.pkg"
    other = root / "other.pkg"
    old.write_bytes(b"old binary")
    new.write_bytes(b"new binary")
    other.write_bytes(b"unchanged binary")
    (root / "other.pkg.sig").write_bytes(b"same signature")
    unchanged = "aero7-desktop"
    base = delta.Audit("old-build", "fingerprint", {delta.TARGET: old, unchanged: other},
                       {delta.TARGET: "1:0.2.0.r22-1", unchanged: "1.0-1"},
                       {delta.TARGET: b"old description", unchanged: b"same description"},
                       {delta.TARGET: b"%FILES%\nusr/bin/aero7-programs-center\n", unchanged: b"same files"})
    current = delta.Audit("new-build", "fingerprint", {delta.TARGET: new, unchanged: other},
                          {delta.TARGET: "1:0.2.0.r26-2", unchanged: "1.0-1"},
                          {delta.TARGET: b"new description", unchanged: b"same description"},
                          {delta.TARGET: base.files[delta.TARGET], unchanged: b"same files"})
    delta.check_candidate = lambda *_args, **_kwargs: current.versions[delta.TARGET]
    delta.verify_delta(base, current, new, signed=False)
    current.desc[delta.TARGET] = base.desc[delta.TARGET]
    rejected(lambda: delta.verify_delta(base, current, new, signed=False), "description did not change")
    current.desc[delta.TARGET] = b"new description"
    current.files[unchanged] = b"altered files"
    rejected(lambda: delta.verify_delta(base, current, new, signed=False), "unchanged database files")

    archive = root / "payload.tar"
    with tarfile.open(archive, "w") as output:
        for name in (".PKGINFO", "usr/", "usr/bin/", "usr/bin/aero7-programs-center"):
            info = tarfile.TarInfo(name)
            info.type = tarfile.DIRTYPE if name.endswith("/") else tarfile.REGTYPE
            payload = b"binary" if name == "usr/bin/aero7-programs-center" else b""
            info.size = len(payload)
            output.addfile(info, io.BytesIO(payload))
    files = b"%FILES%\nusr/\nusr/bin/\nusr/bin/aero7-programs-center\n"
    delta.verify_package_files_entry(archive, files)
    rejected(lambda: delta.verify_package_files_entry(archive, files.replace(b"aero7-programs-center", b"wrong")),
             "differs from archive")

print("test-programs-center-delta-metadata: ok")
