#!/usr/bin/env python3
"""Snapshot and restore the canonical skill collection and manager lock."""

import shutil
import sys
import tarfile
from pathlib import Path

MANAGED = ("skills", ".skill-lock.json")


def snapshot(agent_root: Path, run: Path) -> None:
    run.mkdir(parents=True, exist_ok=True)
    with tarfile.open(run / "previous-skills.tar.gz", "w:gz") as archive:
        for name in MANAGED:
            path = agent_root / name
            if path.exists() or path.is_symlink():
                archive.add(path, arcname=name)


def restore(agent_root: Path, run: Path) -> None:
    failed = run / "failed-collection"
    failed.mkdir()
    agent_root.mkdir(parents=True, exist_ok=True)
    for name in MANAGED:
        path = agent_root / name
        if path.exists() or path.is_symlink():
            shutil.move(str(path), failed / name)
    # This archive was created locally by snapshot under the same refresh lock.
    # Preserve user symlinks as well as files; it is not a downloaded archive.
    with tarfile.open(run / "previous-skills.tar.gz") as archive:
        archive.extractall(agent_root, filter="fully_trusted")


if __name__ == "__main__":
    operation, agent, run = sys.argv[1:]
    {"snapshot": snapshot, "restore": restore}[operation](Path(agent), Path(run))
