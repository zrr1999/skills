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
    start_skill = f"""# Start shared-dev-pilot

Before changing any project files in a new task or resuming work, refresh the
shared setup with the following command. Keep the platform's proxy, CA trust,
credentials, and runtime guards intact.

```bash
{hooks["maintenance_script"].rstrip()}
```

If the command fails, inspect the reported refresh log and resolve the setup
failure before proceeding. A failed refresh restores the previous skill files
and source lock; it does not establish that the skills are current.

After success, source `~/.config/cloud-pilot/env.sh` in shells that need the
tools. Check `~/.local/state/cloud-pilot/skills-state.json` and
`~/.local/state/cloud-pilot/repositories.json`. Read the SKILL.md files needed
for this task again from `~/.agents/skills` after the refresh, so earlier cached
instructions do not take precedence over updated files.

Use the owner-qualified repository paths under `/workspace/cloud-repos`:
`zendev-lab/zendev`, `zrr1999/zrr.dev`, and `spore-lang/spore-lang.dev`.
Respect each repository's AGENTS.md and task worktree rules. The refresh keeps
dirty checkouts, task branches, and unpublished commits; review the reported
status before choosing the checkout for the task.

For preview or tests, use each repository's own commands and locked runtimes.
Do not start every site's development server unless the task needs them.
"""
    (output / "start-skill.md").write_text(start_skill)
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
        "install_script": hooks["setup_script"],
        "start_skill": start_skill,
        "legacy_hooks": hooks,
    }
    (output / "configuration.json").write_text(
        json.dumps(configuration, indent=2) + "\n"
    )
    print(f"Paste-ready configuration: {output}")


if __name__ == "__main__":
    render(sys.argv[1], Path(sys.argv[2]))
