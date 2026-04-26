# SPARK.md format specification | SPARK.md 格式规范

Use the **Chinese** sections below when the user’s SPARK.md should be in 中文; use the **English** sections when it should be in English. YAML keys stay the same in both cases.

当 SPARK.md 使用中文时遵循下方「中文」结构；使用英文时遵循「English」结构。Frontmatter 字段名两种语言相同。

---

## 中文：Frontmatter

```yaml
---
description: <一句话说清楚这个想法是什么，不超过两行>
owner: <GitHub 用户名或团队名>
created: YYYY-MM-DD
updated: YYYY-MM-DD
inspired_by:
  - <启发来源，可以是论文、项目、工具、对话、文章等，自由填写>
---
```

字段说明：

- `description`：给工具和人快速定位用，一句话。
- `created` / `updated`：手动维护，`created` 记录想法诞生时间（独立于 git），`updated` 记录内容上次实质性修改时间。
- `inspired_by`：自由填写，留空也可以。

## 中文：正文结构

```markdown
## 起源
<!-- 最初的想法、问题或机会是什么？ -->

## 产品/设计目标
<!-- 用 2–5 段话描述最终期望的形态和体验。 -->

## 目标用户
<!-- 为谁而做？他们是谁？ -->

## 核心原则
<!-- 3–7 条原则，体验侧从用户感受出发，约束侧从工程/价值观边界出发，可混排。 -->

## 能力地图（方向性）
<!-- 项目预期具备的主要能力，不展开实现细节。 -->
- 能力 A：……
- 能力 B：……

## 成功信号
<!-- 感性判断：什么现象出现了，说明方向对了？不写 KPI，写可观察的行为。
     例："用户第一次使用时能不借助文档完成核心任务。"
     对 Agent 自校验尤其有用。 -->

## 生态关系
<!-- 这个项目依赖谁、被谁依赖、边界在哪。
     单项目可省略；多仓库强耦合的生态项目几乎必填。 -->

## 什么不是本项目要做的（Non-goals）
<!-- 明确排除的方向，防止范围蔓延。 -->

## 已考虑的替代方案 & 理由
<!-- 包括：现有工具/竞品的已知方向及为什么不走那条路；
     也包括内部认真考虑过但放弃的方案及原因。 -->

## 开放问题
<!-- 仍未决定、但会影响最终形态的问题。 -->

## 修订记录
<!-- 每次重大方向调整时记录时间与原因，一行即可。
     例：
     - 2026-04-26：初稿。
     - 2026-05-10：Non-goals 新增"不做 UI 层"，与 weft 边界对齐。 -->
```

## 中文：注意事项

- **没有一级标题**：项目名字在想法阶段往往未定，`description` 字段承载简要描述。
- **没有 status 字段**：生命周期状态靠 git 和仓库状态说话，不需要人工维护额外标签。
- **没有 archived 字段**：随仓库归档，不单独维护。
- **长度控制**：2–5 页为宜，不承载任务列表、排期或实现细节。

---

## English: Frontmatter

```yaml
---
description: <One or two lines: what this idea is>
owner: <GitHub username or team name>
created: YYYY-MM-DD
updated: YYYY-MM-DD
inspired_by:
  - <Papers, projects, tools, conversations, articles — optional, free-form>
---
```

Field notes:

- `description`: Quick anchor for humans and tools.
- `created` / `updated`: Maintained by hand; `created` is when the idea started (independent of git); `updated` is last substantive content change.
- `inspired_by`: Optional; can be empty.

## English: Body structure

```markdown
## Origin
<!-- What sparked this — problem, opportunity, or initial thought? -->

## Product / design goals
<!-- 2–5 short paragraphs on the intended shape and experience. -->

## Target audience
<!-- Who is this for? -->

## Core principles
<!-- 3–7 principles: UX from the user’s perspective; constraints from engineering or values. Mix is fine. -->

## Capability map (directional)
<!-- Main capabilities the project should have; no implementation detail. -->
- Capability A: …
- Capability B: …

## Success signals
<!-- Qualitative: what observable behavior means we’re on track? Not KPIs.
     Example: "A first-time user completes the core task without docs."
     Especially useful for agent self-checks. -->

## Ecosystem
<!-- Dependencies, dependents, boundaries.
     Skip for a single isolated repo; often required for tightly coupled multi-repo setups. -->

## Non-goals
<!-- Explicit exclusions to prevent scope creep. -->

## Alternatives considered & rationale
<!-- Known tools/competitors and why not that path;
     internal options considered and rejected, with reasons. -->

## Open questions
<!-- Undecided items that would change the shape of the project. -->

## Revision log
<!-- One line per major direction change, with date.
     Example:
     - 2026-04-26: First draft.
     - 2026-05-10: Added non-goal "no UI layer" to align with weft. -->
```

## English: Notes

- **No H1 title**: The working name may be unset; `description` carries the summary.
- **No `status` field**: Lifecycle is reflected by git and repo state.
- **No `archived` field**: Archive with the repository.
- **Length**: Aim for roughly 2–5 pages; no task lists, schedules, or deep implementation detail.
