---
name: work-mode-routing
description: >-
  When the task type is unclear or you need to split work, route straight to
  roles-repo experts (researcher, analyst, coder, tester, writer) with explicit
  briefs. No director or work-mode role layer.
---

## Constraints

- The `roles` package does **not** define `new-project`, `maintain-project`, or `learn-project`. Do not assume a coordinator role exists.
- You (or the main agent) orchestrate: merge outputs, choose serial vs parallel, and keep briefs explicit (`goal`, `inputs`, `non-goals`, `expected output`, blocking or not).

## Pick experts by scenario

| Scenario | Typical flow |
|----------|--------------|
| Greenfield / prototype / smallest first step | Parallel `researcher` + `analyst` when feasibility splits into independent questions; then `coder`; then `tester` to validate the claim. |
| Existing repo: continue, fix, refactor | Parallel `analyst` + `tester` when structure review and repro are independent; then `coder`; then `tester` for regression. |
| Study another codebase | Parallel `researcher` briefs per question or subsystem; then `analyst` for pattern/tradeoff synthesis; `writer` only to package—no new facts. |
| Mixed ask (e.g. learn external + change own repo) | Two separate expert pipelines; finish learning track before collapsing into implementation briefs for your repo. |

## Skills to load alongside (optional)

Use when they shorten the path; they do **not** replace an expert:

- `project-kickoff` — greenfield shape and constraints
- `maintenance-pass` — ongoing repo continuation
- `project-reading` — structured reading of foreign projects
- `tech-preferences` — stack/tooling defaults before real choices

## Cross-cutting

- For any meaningful technology choice, load and apply the `tech-preferences` skill when it helps.
- Treat preference discovery as part of the work. Infer what you can from the request and the repo before asking questions.
- Default to English for code comments, docstrings, README additions, and design notes unless the user explicitly asks for another language.
- Keep the conversation language aligned with the user's language.
- Do not invent durable memory responsibilities. This skill is about routing and execution boundaries, not maintaining a global memory file.

## Parallelization

- Independent briefs → parallel by default.
- Serial when one result materially changes the next brief.
