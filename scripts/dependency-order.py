#!/usr/bin/env python3
"""Derive the Aero7 package build order from pinned .SRCINFO files."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict, deque
from pathlib import Path
from typing import Any


REPO = Path(__file__).resolve().parents[1]
PACKAGE_RE = re.compile(r"^([A-Za-z0-9@._+:-]+)")
DEP_SPLIT_RE = re.compile(r"[<>=]")


def fail(message: str) -> None:
    raise SystemExit(f"dependency-order: {message}")


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def normalize_dep(value: str) -> str:
    value = value.strip()
    value = DEP_SPLIT_RE.split(value, 1)[0].strip()
    match = PACKAGE_RE.match(value)
    return match.group(1) if match else value


def parse_srcinfo(path: Path) -> dict[str, list[str]]:
    data: dict[str, list[str]] = defaultdict(list)
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or "=" not in line:
            continue
        key, value = [part.strip() for part in line.split("=", 1)]
        data[key].append(value)
    return dict(data)


def build_graph(repo: Path) -> tuple[list[str], dict[str, list[str]], dict[str, dict[str, list[str]]]]:
    package_manifest = load_json(repo / "manifests" / "packages.json")
    packages = package_manifest["required_packages"]
    denylist = set(package_manifest["denylist"])
    provider_owner: dict[str, str] = {}
    package_info: dict[str, dict[str, list[str]]] = {}

    for package in packages:
        srcinfo = parse_srcinfo(repo / "packages" / package / ".SRCINFO")
        pkgname = srcinfo.get("pkgname", [])
        if package not in pkgname:
            fail(f"{package} .SRCINFO does not declare pkgname {package}")
        names = [package, *srcinfo.get("provides", []), *package_manifest["internal_providers"].get(package, [])]
        for name in names:
            normalized = normalize_dep(name)
            owner = provider_owner.get(normalized)
            if owner and owner != package:
                fail(f"provider {normalized} is ambiguous: {owner}, {package}")
            provider_owner[normalized] = package
        package_info[package] = srcinfo

    edges: dict[str, set[str]] = {package: set() for package in packages}
    reverse: dict[str, set[str]] = {package: set() for package in packages}
    for package in packages:
        srcinfo = package_info[package]
        fields = [*srcinfo.get("depends", []), *srcinfo.get("makedepends", []), *srcinfo.get("checkdepends", [])]
        for dep in fields:
            normalized = normalize_dep(dep)
            if normalized in denylist:
                fail(f"{package} depends on denied package {normalized}")
            owner = provider_owner.get(normalized)
            if owner and owner != package:
                edges[owner].add(package)
                reverse[package].add(owner)

    indegree = {package: len(reverse[package]) for package in packages}
    ready = deque([package for package in packages if indegree[package] == 0])
    order: list[str] = []
    while ready:
        package = ready.popleft()
        order.append(package)
        for consumer in sorted(edges[package]):
            indegree[consumer] -= 1
            if indegree[consumer] == 0:
                ready.append(consumer)

    if len(order) != len(packages):
        cycle = sorted(package for package in packages if indegree[package] > 0)
        fail("dependency cycle detected: " + ", ".join(cycle))

    return order, {key: sorted(value) for key, value in edges.items()}, package_info


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=REPO)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    repo = args.repo.resolve()
    order, edges, package_info = build_graph(repo)
    output = {
        "generated_by": "scripts/dependency-order.py",
        "packages": order,
        "edges": edges,
        "package_metadata": {
            package: {
                "arch": package_info[package].get("arch", []),
                "depends": package_info[package].get("depends", []),
                "makedepends": package_info[package].get("makedepends", []),
                "provides": package_info[package].get("provides", []),
                "conflicts": package_info[package].get("conflicts", []),
                "replaces": package_info[package].get("replaces", []),
            }
            for package in order
        },
    }
    text = json.dumps(output, indent=2, sort_keys=False) + "\n"
    if args.write:
        (repo / "manifests" / "build-order.json").write_text(text, encoding="utf-8")
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
