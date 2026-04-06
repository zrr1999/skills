---
name: project-workflows
description: >-
  适用于绝大多数“项目级”任务：开新 repo/原型、维护现有项目、阅读参考项目、需求不清时先澄清、任务可拆时做职责并行、需要终端取证与 CLI 自动化时优先走 CLI-first 工作法。
  这是统一入口 skill：先收敛目标与最小下一步，再决定是否并行，以及是否调用 tech-preferences、modern-python、unix-software-design、get-api-docs、compound-learnings 等专项 skill。
  与 zrr1999/roles 的职责型角色（inspector / executor / verifier，verifier 可选 lens）配套编排 brief。
---

# Project Workflows

把绝大多数项目工作收敛成**一个统一工作流**：先澄清目标，再看现状与约束，选最小可交付切片，必要时拆子问题并行推进，并在过程中调用更专项的 skill。

## 统一工作流

1. **先复述任务**：用一句话说清当前要推进的目标，不把多个目标混成一句空泛表述。
2. **先补最关键的缺口**：若目标、边界、约束、成功标准或最小可行范围仍模糊，先澄清，不急着实现。
3. **看现场而不是看理想蓝图**：优先读取当前代码、目录、脚本、文档、参考项目或运行状态。
4. **选最小可交付切片**：优先推进最能降低不确定性、最容易验证价值的一步，而不是一口气铺完整方案。
5. **必要时拆子问题**：当子问题边界清楚、可独立推进时，显式标出依赖和并行边界。
6. **调用专项 skill**：技术选型、架构边界、Python 工程化、第三方库文档、经验沉淀等，交给更窄的 skill 处理。
7. **交付统一 packet**：向用户交付一个可继续推进、可执行、可合并的统一 packet，而不是停留在泛泛建议。

## 统一 Packet（输出契约）

至少包含：

- **Objective**：当前要完成什么
- **Current context**：现状、证据或参考输入
- **Constraints**：约束与边界
- **Success criteria**：怎么判断这一步算完成
- **Recommended approach**：建议路径及原因
- **Smallest next slice**：下一步最小可交付切片
- **Subproblems / dependencies**：如有拆分，列出子问题与依赖
- **Parallelization**：哪些可并行，哪些要串行
- **Risks / open questions**：当前还未完全解决的风险或待确认点
- **Next 3 actions**：接下来三个具体动作

## 与 `zrr1999/roles` 的 brief 对齐

向子代理派发任务且使用 [`zrr1999/roles`](https://github.com/zrr1999/roles) 中的职责型角色时，brief **字段名与含义**须与该仓库一致（见 [`roles` README · Brief contract](https://github.com/zrr1999/roles/blob/main/README.md#brief-contract)）：

| 字段 | 含义 |
|------|------|
| `goal` | 要产出或判定什么 |
| `inputs` | 仓库、路径、commit、日志、链接等 |
| `non_goals` | 明确不做的范围 |
| `expected_output` | 交付物形态 |
| `blocking` | 是否阻塞其他工作 |
| `lens`（可选） | 仅用于 `verifier`：`security`、`performance`、`architecture` |

角色分工仍为三件：`inspector` / `executor` / `verifier`；专项审查通过 `verifier` + `lens`，不设独立顶层 role。

## 统一工作流里的常见侧重

不用再先选“新开 / 维护 / 学习”模式；统一工作流里按当前任务侧重调整：

- **从零起步时**：更重视目标、约束、最小可行范围和最大不确定性
- **维护现有项目时**：更重视当前现场、最值得推进的一点、已有模式延续和风险控制
- **阅读参考项目时**：更重视项目快照、可借鉴模式、不宜照搬之处，以及迁回当前项目的落点
- **混合请求时**：可以分阶段，但仍使用同一个 packet 结构；只在需要时把不同阶段明确分段

## 内建需求澄清

- 若目标、边界、约束、成功标准或最小可行范围不清，先在本 skill 内做澄清，不再依赖单独的 `requirements-shaping`。
- 一次只推进一个关键不确定点；优先问最影响方案选择的问题。
- 当请求本质上是技术选型、工具偏好或是否偏离已有基线时，不要把它当作需求澄清，应转给 `tech-preferences`。
- 若用户尚未确认范围，不要把模糊想法伪装成已定方案。

## 内建并行与 roles 分工

- 当存在两个以上边界清楚、可独立推进的子问题时，在本 skill 内做任务拆解与并行边界判断，不再依赖单独的 `expert-orchestration`。
- 拆解时至少写明：子任务目标、依赖、输入上下文、预期产出、完成标准。
- 只有低耦合任务才并行；共享上下文重、依赖强、改动区域重叠的任务应串行。
- 需要与 `zrr1999/roles` 配合时，按 **职责型** 角色分工（不是人类岗位名）：
  - **`inspector`**：补外部上下文、读陌生代码/文档、拆问题、比较方案、总结现状、提炼判断（原 `researcher` / `analyst` 类工作合并到这里）
  - **`executor`**：在 brief 边界内实施改动，产出可合并的 diff 与检查/阻塞说明
  - **`verifier`**：复现、补测试、回归检查、对照声明做审查；需要安全/性能/架构专项深度时，在 brief 上设 **`lens: security`**、**`lens: performance`** 或 **`lens: architecture`**（见 `roles` 仓库中的 `verifier` 定义）
  - **交付说明**：对用户可见的整理与包装默认由编排层或 `project-workflows` 的 packet 完成，不设独立 `writer` role

## 内建 CLI-first 工作法

- 当任务需要终端取证、搜仓库、看 diff、调 API、看 JSON、查 GitHub、比性能、看磁盘/进程、并行跑长时任务时，直接在本 skill 内采用 CLI-first，不再依赖单独的 `agent-cli-toolkit`。
- 默认工具选择：
  - 搜代码：`rg`
  - 按名找文件：`fd`
  - 快速查看文件：`bat`
  - 简单文本替换：`sd`
  - 看 diff：`delta` / `difft`
  - 看 GitHub：`gh` / `gh llm`
  - 调 HTTP / 看 JSON：`http` + `jq`
  - 比性能：`hyperfine`
  - 看磁盘 / 进程：`dust` / `duf` / `procs` / `btm`
  - 多窗格或命名会话：`zellij`
- 原则：终端证据优先、结构化输出优先、能自动化就不要手工重复。

## 什么时候调用其他 skill

- **`tech-preferences`**：要决定语言、框架、工具、数据格式、部署方式，或要判断是否偏离当前技术基线时
- **`modern-python`**：任务明确涉及 Python 工程化落地，如 `uv`、`ruff`、`ty`、`pyproject.toml`、CI、预提交、脚手架时
- **`unix-software-design`**：核心问题是模块边界、接口规划、拆分策略、复杂度控制，而不是日常推进时
- **`get-api-docs`**：需要第三方库、SDK、云服务或 API 的现行文档与正确用法时
- **`compound-learnings`**：刚解决了一个非平凡问题、做了重要决策，或新 session 需要先检索历史经验时

## 不适用

- 只是明确、局部、低风险的小改动，且不需要项目级澄清、拆解、终端取证或跨文件判断
- 纯技术选型讨论而没有项目推进语境；这种优先 `tech-preferences`
- 纯 Python 工程化落地；这种优先 `modern-python`

## 跨切

- 有意义的技术选择：先 `tech-preferences`；偏好发现也是工作的一部分，能从请求与 repo 推断就少问。
- 代码注释、docstring、README 增补、设计笔记默认 **英文**，除非用户明确要求其他语言；**对话语言**与用户一致。
- 不虚构「全局记忆」职责；经验沉淀交给 `compound-learnings`，第三方文档交给 `get-api-docs`。
