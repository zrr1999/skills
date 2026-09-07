#!/usr/bin/env bash

set -euo pipefail

status=0

for skill_file in skills/*/SKILL.md; do
  skill_dir="${skill_file%/SKILL.md}"
  skill_name="${skill_dir#skills/}"
  file="$skill_dir/evals/evals.json"

  if [[ ! -f "$file" ]]; then
    printf 'Missing eval file: %s\n' "$file" >&2
    status=1
    continue
  fi

  if ! jq -e --arg skill_name "$skill_name" '
    def nonempty_string: type == "string" and length > 0;
    (.skill_name == $skill_name)
    and (.evals | type == "array" and length > 0)
    and (([.evals[].id] | length) == ([.evals[].id] | unique | length))
    and all(.evals[];
      (.id | type == "number")
      and (.prompt | nonempty_string)
      and (.expected_output | nonempty_string)
      and (.files | type == "array")
      and (.expectations | type == "array" and length > 0)
      and all(.expectations[]; nonempty_string)
    )
  ' "$file" >/dev/null; then
    printf 'Invalid eval schema: %s\n' "$file" >&2
    status=1
  fi
done

exit "$status"
