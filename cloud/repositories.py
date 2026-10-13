#!/usr/bin/env python3
"""Restore pilot repositories without replacing local edits or task branches."""

import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path


def git_environment() -> dict[str, str]:
    # Hook path/index variables would override an explicit -C repository path.
    context = {
        "GIT_DIR",
        "GIT_WORK_TREE",
        "GIT_INDEX_FILE",
        "GIT_COMMON_DIR",
        "GIT_PREFIX",
    }
    return {
        **{name: value for name, value in os.environ.items() if name not in context},
        "GIT_TERMINAL_PROMPT": "0",
    }


def git(path: Path, *arguments: str) -> str:
    return subprocess.check_output(
        ["git", "-C", str(path), *arguments],
        text=True,
        env=git_environment(),
    ).strip()


def sync_repository(root: Path, name: str, url: str | None = None) -> tuple[Path, str]:
    parts = name.split("/")
    if len(parts) != 2 or any(part in ("", ".", "..") for part in parts):
        raise ValueError(f"Expected owner/repository: {name}")
    path = root.joinpath(*parts)
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            [
                "git",
                "clone",
                "--filter=blob:none",
                url or f"https://github.com/{name}.git",
                str(path),
            ],
            check=True,
            env=git_environment(),
        )
    elif not (path / ".git").exists():
        raise RuntimeError(f"Refusing to overwrite a non-repository: {path}")

    if git(path, "status", "--porcelain"):
        print(f"Preserved local changes: {name}")
        return path, "local-changes"
    default_ref = git(path, "symbolic-ref", "--short", "refs/remotes/origin/HEAD")
    branch = default_ref.removeprefix("origin/")
    if git(path, "branch", "--show-current") != branch:
        print(f"Preserved task branch: {name}")
        return path, "task-branch"
    git(path, "fetch", "origin", f"{branch}:refs/remotes/origin/{branch}")
    if git(path, "rev-list", "--count", f"{default_ref}..HEAD") != "0":
        print(f"Preserved local commits: {name}")
        return path, "local-commits"
    git(path, "merge", "--ff-only", default_ref)
    git(path, "submodule", "update", "--init", "--recursive")
    return path, "ready"


def dependency_digest(path: Path) -> str:
    digest = hashlib.sha256()
    for name in (
        "uv.lock",
        "pyproject.toml",
        "pnpm-lock.yaml",
        "pnpm-workspace.yaml",
        "package.json",
        ".python-version",
        ".node-version",
        ".nvmrc",
    ):
        candidate = path / name
        if candidate.is_file():
            digest.update(name.encode())
            digest.update(candidate.read_bytes())
    return digest.hexdigest()


def main(profile: Path) -> None:
    root = Path(os.environ.get("CLOUD_PILOT_ROOT", "/workspace/cloud-repos"))
    state_root = Path(os.environ["CLOUD_PILOT_STATE_DIR"])
    state_root.mkdir(parents=True, exist_ok=True)
    state_path = state_root / "repositories.json"
    previous = json.loads(state_path.read_text()) if state_path.exists() else {}
    current = {}
    for repository in json.loads(profile.read_text())["repositories"]:
        name, installer = repository["name"], repository["installer"]
        path, outcome = sync_repository(root, name)
        if outcome != "ready":
            current[name] = {**previous.get(name, {}), "status": outcome}
            continue
        digest = dependency_digest(path)
        dependency_path = path / (".venv" if installer == "uv" else "node_modules")
        if (
            previous.get(name, {}).get("dependency_digest") != digest
            or not dependency_path.exists()
        ):
            commands = {
                "uv": ["uv", "sync", "--locked", "--all-packages", "--all-groups"],
                "vp": ["vp", "install", "--frozen-lockfile"],
                "pnpm": ["pnpm", "install", "--frozen-lockfile"],
            }
            subprocess.run(commands[installer], cwd=path, check=True)
        if repository.get("typst_paths"):
            subprocess.run(
                [
                    sys.executable,
                    str(Path(__file__).with_name("typst-cache.py")),
                    *[str(path / item) for item in repository["typst_paths"]],
                ],
                check=True,
            )
        current[name] = {
            "status": "ready",
            "path": str(path),
            "head": git(path, "rev-parse", "HEAD"),
            "dependency_digest": digest,
        }
    temporary = state_path.with_suffix(".tmp")
    temporary.write_text(json.dumps(current, indent=2) + "\n")
    temporary.replace(state_path)


if __name__ == "__main__":
    main(Path(sys.argv[1]))
