#!/usr/bin/env python3
"""Prefetch pinned Typst imports through the inherited trusted HTTPS proxy."""

import io
import os
import re
import sys
import tarfile
import tempfile
import urllib.request
from pathlib import Path

import tomllib

IMPORT = re.compile(r"@preview/([a-z][a-z0-9-]*):(\d+\.\d+\.\d+)")


def imports(paths: list[Path]) -> set[tuple[str, str]]:
    result = set()
    for path in paths:
        if not path.exists():
            continue
        for source in path.rglob("*.typ"):
            result.update(IMPORT.findall(source.read_text()))
    return result


def main(paths: list[Path], root: Path | None = None) -> None:
    if root is None:
        root = (
            Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
            / "typst/packages/preview"
        )
    pending = imports(paths)
    visited = set()
    while pending:
        name, version = pending.pop()
        if (name, version) in visited:
            continue
        visited.add((name, version))
        if len(visited) > 64:
            raise RuntimeError("Unexpectedly large Typst package dependency graph")
        target = root / name / version
        if not (target / "typst.toml").is_file():
            target.parent.mkdir(parents=True, exist_ok=True)
            with urllib.request.urlopen(
                f"https://packages.typst.org/preview/{name}-{version}.tar.gz",
                timeout=60,
            ) as response:
                archive = response.read()
            with tempfile.TemporaryDirectory(
                dir=target.parent, prefix=".download-"
            ) as staging:
                with tarfile.open(fileobj=io.BytesIO(archive)) as bundle:
                    bundle.extractall(staging, filter="data")
                metadata = tomllib.loads((Path(staging) / "typst.toml").read_text())[
                    "package"
                ]
                if metadata["name"] != name or metadata["version"] != version:
                    raise RuntimeError(
                        f"Typst package metadata mismatch: {name}:{version}"
                    )
                if target.exists():
                    raise RuntimeError(f"Incomplete existing package cache: {target}")
                Path(staging).rename(target)
            print(f"Cached Typst package: {name}:{version}")
        pending.update(imports([target]) - visited)


if __name__ == "__main__":
    main([Path(argument) for argument in sys.argv[1:]])
