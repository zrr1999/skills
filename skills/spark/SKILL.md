---
name: spark
description: >
  Use when the user wants to capture, refine, or act on a project idea in Chinese or English.
  Triggers include "I have an idea", "help me think through X", "write a SPARK.md",
  "turn this into a plan", "create a repo", "我有个想法", "帮我想清楚", "写 SPARK.md",
  "把想法变成计划", or open-ended product/design brainstorming.
---

# SPARK Skill

Helps users go from a rough idea to a structured SPARK.md, a GitHub repo, and concrete next steps — through conversation, not forms.

## Overview

The workflow has three modes. Detect where the user is and jump in:

| Mode | When to use |
|---|---|
| **Capture** | User has an idea but no SPARK.md yet → elicit, draft, create repo |
| **Refine** | User has an existing SPARK.md → read it, discuss, update it |
| **Plan** | User wants to act on a SPARK.md → break it into concrete next steps |

These modes naturally chain: Capture → Refine → Plan. But the user may enter at any point.

## Language Policy

Support both 中文 and English.

1. Choose the working language from the user's current request. If editing an existing SPARK.md, use the document language unless the user asks to switch.
2. Use the working language for conversation, questions, summaries, confirmation prompts, drafted SPARK.md body, plans, GitHub issue titles/bodies, and uncertainty comments.
3. If the request is mixed or unclear, ask one short question: `中文还是 English?` / `Chinese or English?`
4. Keep YAML frontmatter keys unchanged in both languages. Read `references/spark-spec.md` before drafting; it contains the Chinese and English section names.

Useful paired phrases:

| Situation | 中文 | English |
|---|---|---|
| Uncertainty marker | `<!-- 待确认 -->` | `<!-- to confirm -->` |
| Draft confirmation | `有没有明显偏差的地方？` | `Anything obviously off?` |
| Direction changed | `这个方向变了` | `the direction changed` |

---

## Mode 1: Capture

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

### Step 2 — Draft SPARK.md

Read `references/spark-spec.md` for the exact format before writing.

Write a complete draft in the working language. Don't leave placeholder lorem ipsum — make real guesses based on the conversation and mark uncertainty with the localized inline comment from Language Policy. It's easier for the user to correct a concrete wrong answer than to fill a blank.

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

If the repo name isn't decided yet, ask — but don't block on a perfect name. A working name is fine; SPARK.md's `description` field carries the real meaning.

After creating, print the repo URL and confirm with the user.

---

## Mode 2: Refine

Read the existing SPARK.md first. Then:

1. Summarize what you understand the idea to be (2–3 sentences). Ask if that's right.
2. Identify the weakest sections — usually `开放问题` / `Open questions`, `什么不是本项目要做的（Non-goals）` / `Non-goals`, or missing `成功信号` / `Success signals`.
3. Propose specific edits, not just "you should add X". Write the actual text.
4. Update the file and bump `updated` in frontmatter.

When the user says the direction changed or a major assumption gets invalidated, add an entry to `## 修订记录` / `## Revision log` explaining why.

---

## Mode 3: Plan

Turn the SPARK.md into actionable next steps in the working language. This is not a roadmap — it's "what should I do this week/sprint to move the needle."

### Read first

Look at:

| 中文 section | English section | Use it to answer |
|---|---|---|
| `能力地图（方向性）` | `Capability map (directional)` | What capabilities need to exist? |
| `成功信号` | `Success signals` | What's the earliest signal you could get? |
| `生态关系` | `Ecosystem` | What dependencies need to be in place first? |
| `开放问题` | `Open questions` | Which open questions are blockers vs. noise? |

### Output

Produce a prioritized list of **concrete actions**, not vague tasks. Each action should be:
- Specific enough to start without further clarification
- Tied back to a capability or success signal in the SPARK
- Tagged with rough size: `[small]` (< 2h), `[medium]` (half day), `[large]` (needs breakdown)

Use localized headings. Example formats:

```markdown
## 本阶段行动计划

基于 SPARK.md 中的能力地图和成功信号，优先解锁最早的验证点。

### 立即可做
- [small] 初始化 Rust workspace，验证 crate 结构 → 解锁"能力 A"的基础
- [medium] 实现 X 的最小原型，跑通核心路径 → 直接验证成功信号 #1

### 需要先解决的开放问题
- "Y 用哪种协议？" — 这是能力 B 的前置，建议本周内决策

### 暂缓
- Z 相关的能力：依赖上游项目，现在动没有收益
```

```markdown
## Action Plan For This Stage

Based on the capability map and success signals in SPARK.md, prioritize the earliest validation point.

### Do now
- [small] Initialize the Rust workspace and verify crate structure → unlocks the foundation for "Capability A"
- [medium] Build the smallest prototype for X and run the core path → directly validates success signal #1

### Open questions to resolve first
- "Which protocol should Y use?" — this blocks Capability B, decide this week

### Defer
- Z-related capability: depends on an upstream project, so it has little payoff right now
```

If the user has a GitHub repo, offer to create issues:

```bash
gh issue create --title "<action>" --body "<tie-back to SPARK>" --label "spark-plan"
```

---

## General principles

- **对话优先，文档其次**。SPARK.md 是对话的产物，不是对话的替代品。
- **不要等用户想清楚再动手**。先写一个有缺陷的草稿，比等一个完美输入有效得多。
- **每次修改都更新 `updated` 字段**。这是 frontmatter 里唯一需要手动维护的日期。
- **计划要短**。Mode 3 的输出不是 ROADMAP.md，是"下一步"。如果用户需要完整路线图，那是另一个任务。
- **Conversation before document**. SPARK.md is the result of the conversation, not a substitute for it.
- **Don't wait for perfect clarity**. A flawed concrete draft is easier to correct than a blank page.
- **Update `updated` on every substantive edit**. It is the only manually maintained date field.
- **Keep plans short**. Mode 3 produces next steps, not a full roadmap.

## Reference files

- `references/spark-spec.md` — complete SPARK.md format in 中文 and English; read it before drafting.
