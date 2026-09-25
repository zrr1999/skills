#!/usr/bin/env bash

set -euo pipefail

status=0

for skill_file in skills/*/SKILL.md; do
  skill_dir="${skill_file%/SKILL.md}"
  skill_name="${skill_dir#skills/}"
  file="evals/$skill_name/evals.json"
  bundled_dir="$skill_dir/evals"

  if [[ -e "$bundled_dir" ]]; then
    printf 'Eval answers belong in %s; found %s\n' "$file" "$bundled_dir" >&2
    status=1
  fi

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

legacy_pattern='\b(git-worktrees|quality-audit|modern-python|unix-software-design|agent-cli-toolkit|new-project|maintain-project|learn-project|spark-code-review|github:yeet|github:gh-fix-ci)\b|\bSpark\b|(使用|由|加载|路由到|交给)[[:space:]]+spark\b|\bspark[[:space:]]+skill\b'

if rg -n --pcre2 "$legacy_pattern" evals/*/evals.json; then
  printf 'Legacy skill name or deleted route found in evals\n' >&2
  status=1
fi

exit "$status"
