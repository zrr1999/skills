---
name: work-mode-routing
description: >-
  Routes requests into `directors/new-project`, `directors/maintain-project`, or
  `directors/learn-project` when work mode is unclear, mixed, or needs explicit
  selection. Use when the user's request involves starting new projects,
  maintaining existing projects, or studying other projects.
---

# Work Mode Routing

When routing work to directors, follow these rules.

## Director Selection

- Choose one primary lane: `directors/new-project`, `directors/maintain-project`, or `directors/learn-project`.
- Keep the chosen mode explicit in reasoning and handoffs.
- `directors/new-project`: greenfield shaping and first proof.
- `directors/maintain-project`: continuing and improving existing work.
- `directors/learn-project`: extracting reusable lessons from other projects.

## Routing Rules

- Delegate to directors first.
- For non-trivial work, require the active director to make decomposition explicit: subproblems, dependencies, output floors, and which specialist briefs can run in parallel.
- Keep one primary mode active unless the user clearly wants a combined pass.
- If the request mixes modes, sequence them deliberately instead of blurring them together. Prefer parallel lanes inside one mode before mixing modes together.
- If two or more subproblems inside the same mode are independent, expect the director to launch them in parallel rather than serializing them.
- Do not let directors absorb clearly specialist-sized work unless the task is too small to justify delegation or the work requires tight synthesis that would make delegation wasteful.
- Ask each active director for a concrete output floor and a merge-ready packet before accepting the result.

## Cross-Cutting

- For any meaningful technology choice, load and apply the `tech-preferences` skill first.
- Treat preference discovery as part of the work. Infer what you can from the request and the repo before asking questions.
- Default to English for code comments, docstrings, README additions, and design notes unless the user explicitly asks for another language.
- Keep the conversation language aligned with the user's language.
- Do not invent durable memory responsibilities. This skill is about routing and execution boundaries, not maintaining a global memory file.
