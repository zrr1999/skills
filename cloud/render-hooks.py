#!/usr/bin/env python3
"""Render paste-ready hooks pinned to a published, reviewed Git commit."""

import json
import re
import sys
from pathlib import Path


def render(ref: str, output: Path) -> None:
    if not re.fullmatch(r"[0-9a-f]{40}", ref):
        raise ValueError("Use the full published Git commit SHA")
    output.mkdir(parents=True, exist_ok=True)
    hooks = {}
    for mode in ("setup", "maintenance"):
        text = f"""#!/usr/bin/env bash
set -euo pipefail
pilot_ref='{ref}'
pilot_script="$(mktemp)"
trap 'rm -f "$pilot_script"' EXIT
curl -fsSL --retry 2 --max-time 120 \\
  "https://raw.githubusercontent.com/zrr1999/skills/$pilot_ref/cloud/bootstrap.sh" \\
  -o "$pilot_script"
CLOUD_PILOT_RUNTIME_REF="$pilot_ref" bash "$pilot_script" {mode}
"""
        path = output / f"{mode}-hook.sh"
        path.write_text(text)
        path.chmod(0o755)
        hooks[f"{mode}_script"] = text
    configuration = {
        "name": "shared-dev-pilot",
        "configuration_status": "prepared; platform binding not yet saved",
        "runtime_revision": ref,
        "source_repository": "zrr1999/skills",
        "environment_variables": {
            "NODE_USE_ENV_PROXY": "1",
            "SKILLS_AGENT": "cline",
            "CLOUD_PILOT_ROOT": "/workspace/cloud-repos",
        },
        **hooks,
    }
    (output / "configuration.json").write_text(
        json.dumps(configuration, indent=2) + "\n"
    )
    print(f"Paste-ready configuration: {output}")


if __name__ == "__main__":
    render(sys.argv[1], Path(sys.argv[2]))
