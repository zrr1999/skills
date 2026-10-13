#!/usr/bin/env python3
"""Install one official Linux release binary into the user's local bin directory."""

import hashlib
import json
import os
import platform
import shutil
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

tool = sys.argv[1]
architecture = {"x86_64": "x86_64", "aarch64": "aarch64"}.get(platform.machine())
if platform.system() != "Linux" or architecture is None:
    raise SystemExit("This installer supports Linux x86_64 and aarch64")
repositories = {
    "fd": "sharkdp/fd",
    "zellij": "zellij-org/zellij",
    "shellcheck": "koalaman/shellcheck",
    "gh": "cli/cli",
    "lychee": "lycheeverse/lychee",
}
repository = repositories[tool]
endpoint = f"repos/{repository}/releases/latest"
if (
    shutil.which("gh")
    and subprocess.run(
        ["gh", "auth", "status"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    ).returncode
    == 0
):
    metadata = subprocess.check_output(["gh", "api", endpoint], text=True)
else:
    metadata = subprocess.check_output(
        ["curl", "-fsSL", f"https://api.github.com/{endpoint}"], text=True
    )
release = json.loads(metadata)


def matches(name):
    if tool == "zellij":
        return name == f"zellij-{architecture}-unknown-linux-musl.tar.gz"
    if tool == "fd":
        return name.startswith("fd-") and name.endswith(
            f"-{architecture}-unknown-linux-musl.tar.gz"
        )
    if tool == "gh":
        return name.endswith(
            f"linux_{'amd64' if architecture == 'x86_64' else 'arm64'}.tar.gz"
        )
    if tool == "lychee":
        return name.endswith(f"-{architecture}-unknown-linux-musl.tar.gz")
    return name.startswith("shellcheck-") and name.endswith(
        f".linux.{architecture}.tar.xz"
    )


assets = [asset for asset in release["assets"] if matches(asset["name"])]
if len(assets) != 1:
    raise SystemExit(
        f"Expected one official release asset for {tool}; found {len(assets)}"
    )
asset = assets[0]
target_directory = Path.home() / ".local/bin"
target_directory.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix=f"cloud-pilot-{tool}-") as temporary:
    archive = Path(temporary) / asset["name"]
    subprocess.run(
        [
            "curl",
            "-fsSL",
            "--retry",
            "2",
            "--max-time",
            "180",
            asset["browser_download_url"],
            "-o",
            str(archive),
        ],
        check=True,
    )
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    expected = asset.get("digest")
    if expected and expected != f"sha256:{digest}":
        raise SystemExit(f"Release checksum mismatch for {tool}")
    with tarfile.open(archive) as bundle:
        binaries = [
            member
            for member in bundle.getmembers()
            if member.isfile() and Path(member.name).name == tool
        ]
        if len(binaries) != 1:
            raise SystemExit(f"Expected one {tool} executable in the release archive")
        staged = Path(temporary) / tool
        with (
            bundle.extractfile(binaries[0]) as source,
            staged.open("wb") as destination,
        ):
            shutil.copyfileobj(source, destination)
        staged.chmod(0o755)
        local_stage = target_directory / f".{tool}.install-{os.getpid()}"
        shutil.copy2(staged, local_stage)
        local_stage.replace(target_directory / tool)
    print(f"Installed {tool} {release['tag_name']} (archive sha256 {digest})")
