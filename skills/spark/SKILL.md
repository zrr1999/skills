---
name: spark
description: >
  Use when the user wants to capture, clarify, plan, or advance a project idea or repo in Chinese or English.
  Triggers include "I have an idea", "help me think through X", "what should I do next in this repo",
  "split this into tasks", "write/update SPARK.md", "create a repo", "我有个想法", "帮我想清楚",
  "帮我理一理下一步", "这个项目接下来做什么", "把任务拆一下", or open-ended project/design/workflow requests.
---

# SPARK Skill

Spark is the default **project-level workflow**:

- clarify the current goal before implementation
- inspect the current repo / docs / scripts / runtime reality instead of assuming
- choose the smallest useful next slice
- split work or parallelize only when boundaries are genuinely clear
- use CLI-first evidence gathering when terminal proof matters
- hand off narrow concerns to narrower skills
- materialize or refine `SPARK.md` when durable intent would help

Do **not** ask the user to choose a mode up front. Infer the mode from the request and project state.

## Working language

Support both 中文 and English.

1. Choose the working language from the user's current request. If editing an existing `SPARK.md`, use the document language unless the user asks to switch.
2. Use the working language for conversation, questions, summaries, confirmation prompts, drafted `SPARK.md` body, plans, task packets, and uncertainty comments.
3. If the request is mixed or unclear, ask one short question: `中文还是 English?` / `Chinese or English?`
4. Keep YAML frontmatter keys unchanged in both languages. Read `references/spark-spec.md` before drafting or editing `SPARK.md`; it contains the Chinese and English section names.

Useful paired phrases:

| Situation | 中文 | English |
|---|---|---|
| Uncertainty marker | `<!-- 待确认 -->` | `<!-- to confirm -->` |
| Draft confirmation | `有没有明显偏差的地方？` | `Anything obviously off?` |
| Direction changed | `这个方向变了` | `the direction changed` |

## Entry modes

Infer the mode; don't make the user pick one.

| Mode | When to use |
|---|---|
| **Clarify / Inspect** | The user wants to understand a repo, choose the next slice, compare a reference project, or decide whether to refactor / rewrite |
| **Capture** | The user has an idea but no `SPARK.md` yet |
| **Refine** | The user already has a `SPARK.md` and wants to sharpen or change it |
| **Advance** | The user wants concrete next actions, task splits, or agent briefs from the current project state or from `SPARK.md` |

These modes often chain: Clarify / Inspect → Capture or Refine → Advance.

## Unified project workflow

For most project-level requests, follow this sequence:

1. **Restate the objective** — summarize the current goal in one sentence.
2. **Fill the highest-signal gap** — if scope, boundary, constraints, or success criteria are unclear, ask only the most decision-changing question first. Ask at most 2–3 questions at a time.
3. **Inspect reality** — read the current code, docs, scripts, repo structure, reference project, or runtime evidence before proposing major moves.
4. **Name constraints and success criteria** — make explicit what must stay true, what “done” means, and what should *not* be broadened yet.
5. **Choose the smallest next slice** — prefer the smallest step that reduces uncertainty or creates a meaningful validation point.
6. **Decide whether to split work** — only split into subproblems or parallel workstreams when the boundaries, dependencies, and outputs are clear.
7. **Call narrower skills when needed** — use specialized skills for preferences, design, APIs, Python engineering, or learnings rather than swallowing those concerns whole.
8. **Deliver a unified packet** — give the user an actionable, mergeable next-step packet rather than vague advice.

## Unified packet

Unless the user asks for a different format, the project-level response should include at least:

- **Objective** — what the current step is trying to achieve
- **Current context** — repo facts, evidence, reference inputs, or observed constraints
- **Constraints** — boundaries and non-goals that matter right now
- **Success criteria** — how to tell whether this step worked
- **Recommended approach** — the suggested path and why
- **Smallest next slice** — the minimum useful next deliverable
- **Subproblems / dependencies** — if applicable, what can be separated and what cannot
- **Parallelization** — what can run in parallel vs. what must stay serial
- **Risks / open questions** — the unresolved points that still matter
- **Next 3 actions** — the next three concrete actions

## Mode 1 — Clarify / Inspect

Use this for most "project work" requests, including:

- maintaining an existing repo
- reading a reference project and translating lessons back
- choosing the next worthwhile slice in a messy project
- judging whether a rewrite is justified
- planning how to split work among agents

### Rules

1. **Inspect before prescribing**. Do not endorse a rewrite, big refactor, or parallel split without evidence from the current repo or reference inputs.
2. **Do not force a fake mode choice**. The user should not have to choose “new / maintain / learn” first.
3. **Let reference reading and project planning coexist**. If the user wants to inspect a great repo *and* decide the next step for their own repo, keep both stages in one packet.
4. **Prefer the smallest credible move**. In a messy project, pick the most leverageful next slice instead of proposing a reset.

### CLI-first evidence gathering

When terminal proof matters, use CLI-first working inside Spark instead of inventing a separate toolkit.

Default tools to prefer:

- search code: `rg`
- find files by name: `fd`
- inspect files quickly: `bat`
- simple replacements: `sd`
- inspect diffs: `delta` / `difft`
- GitHub context: `gh` / `gh llm`
- HTTP + JSON: `http` + `jq`
- benchmarking: `hyperfine`
- disk / process inspection: `dust` / `duf` / `procs` / `btm`
- multi-pane / named sessions: `zellij`

Principles: terminal evidence first, structured output first, automate repeated steps when useful.

## Mode 2 — Capture

### Step 1 — Elicit

Don't ask for a form. Have a conversation in the working language. Extract enough signal to write a first draft. Use these concepts, translated into the working language:

- **核心洞察 / Core insight**: what problem or opportunity sparked this?
- **目标体验 / Target experience**: what does it feel like to use the thing?
- **目标用户 / Who it's for**: even roughly ("myself", "other developers", "small teams")
- **排除方向 / What it's NOT**: what would be an obvious wrong turn?
- **启发来源 / Inspirations**: what tools, papers, projects, or conversations influenced this?

Ask at most 2–3 questions at a time. If the user gives a long description upfront, extract what you can and only ask about genuine gaps.
If the user only provides a one-sentence idea, stay in Elicit and ask the highest-signal gaps before drafting.

One useful question to always ask if not answered:

- 中文：`什么现象出现时，会让你觉得这个项目方向是对的？`
- English: `What would make you feel like this project is going in the right direction?`

This seeds the `成功信号` / `Success signals` section.

### Step 2 — Draft `SPARK.md`

Read `references/spark-spec.md` for the exact format before writing.

Write a complete draft in the working language. Don't leave placeholder lorem ipsum — make real guesses based on the conversation and mark uncertainty with the localized inline comment from Working language. It's easier for the user to correct a concrete wrong answer than to fill a blank.

Present the draft inline in conversation first. Ask the localized draft-confirmation question before creating any files.

### Step 3 — Create repo + commit

Once the user confirms the draft (or says "looks good enough, let's go"):

```bash
# 1. Create repo (gh CLI)
gh repo create <name> --private --clone
cd <name>

# 2. Write SPARK.md
cat > SPARK.md << 'EOF'
<draft content>
EOF

# 3. Initial commit
git add SPARK.md
git commit -m "docs: add SPARK.md"
git push
```

If the repo name isn't decided yet, ask — but don't block on a perfect name. A working name is fine; `SPARK.md`'s `description` field carries the real meaning.

After creating, print the repo URL and confirm with the user.

## Mode 3 — Refine

Read the existing `SPARK.md` first. Then:

1. Summarize what you understand the idea to be (2–3 sentences). Ask if that's right.
2. Identify the weakest sections — usually `开放问题` / `Open questions`, `什么不是本项目要做的（Non-goals）` / `Non-goals`, or missing `成功信号` / `Success signals`.
3. Propose specific edits, not just "you should add X". Write the actual text.
4. Update the file and bump `updated` in frontmatter.

When the user says the direction changed or a major assumption gets invalidated, add an entry to `## 修订记录` / `## Revision log` explaining why.

## Mode 4 — Advance

Turn the current repo state or `SPARK.md` into actionable next steps. This is not a roadmap — it's the smallest useful move that should happen next.

### What to produce

- concrete actions, not vague themes
- subproblem boundaries and dependencies when relevant
- clear serial vs. parallel guidance
- brief-ready task packets when the user wants delegation
- explicit mention of blockers or missing evidence

When useful, tag actions with rough size:
- `[small]` — less than 2 hours
- `[medium]` — about half a day
- `[large]` — needs breakdown

If no `SPARK.md` exists yet, you may still work directly from the repo reality. Only write or update `SPARK.md` when durable project intent would materially help.

### Delegation / agent briefs

If the user wants subagent planning, align with [`zrr1999/roles`](https://github.com/zrr1999/roles/blob/main/README.md#brief-contract):

| Field | Meaning |
|---|---|
| `goal` | What should be produced or decided |
| `inputs` | Repo, paths, commits, logs, links, or evidence |
| `non_goals` | What this brief explicitly should not do |
| `expected_output` | The expected artifact or result shape |
| `blocking` | Whether this work blocks other work |
| `lens` (optional) | Only for `verifier`: `security`, `performance`, or `architecture` |

Use the current agent-first role split:

- **`inspector`** — evidence gathering, reading unfamiliar code/docs, surfacing options, summarizing current state
- **`executor`** — bounded implementation with concrete deliverables and validation notes
- **`verifier`** — reproduction, regression checks, and claim review; deepen with `lens: security | performance | architecture` when needed

Only parallelize low-coupled work. If tasks overlap heavily in context or code ownership, keep them serial.

## When to call other skills

- **`tech-preferences`** — choosing languages, frameworks, tools, data formats, or deciding whether to deviate from an existing baseline
- **`modern-python`** — Python project engineering work: `uv`, `ruff`, `ty`, `pyproject.toml`, CI, hooks, scaffolding
- **`unix-software-design`** — module boundaries, interface design, decomposition strategy, complexity control
- **`get-api-docs`** — current third-party SDK / API / platform documentation
- **Spark learnings tools** — in pi-spark workspaces, use `spark_learning_search` before related work and `spark_learning_record` / task-finish candidates after non-trivial fixes or decisions

## General principles

- **Conversation before document**. `SPARK.md` is a durable product of the conversation, not a replacement for it.
- **Don't wait for perfect clarity**. A concrete draft or packet is easier to correct than a blank page.
- **Don't fake certainty**. If scope or constraints are genuinely missing, ask the most decision-changing question first.
- **Don't endorse rewrites without evidence**. Large resets need repo evidence, not frustration alone.
- **Keep plans short**. Spark produces the next useful slice, not a giant roadmap unless the user explicitly asks for one.
- **Update `updated` on every substantive `SPARK.md` edit**. It is the only manually maintained date field.

## Reference files

- `references/spark-spec.md` — complete `SPARK.md` format in 中文 and English; read it before drafting or editing
