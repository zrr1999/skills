#!/usr/bin/env bash

set -euo pipefail

status=0

for file in skills/*/evals/evals.json; do
  skill_dir="${file#skills/}"
  skill_dir="${skill_dir%%/*}"

  if ! jq -e --arg skill_dir "$skill_dir" '
    def nonempty_string: type == "string" and length > 0;
    (.skill_name == $skill_dir)
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
