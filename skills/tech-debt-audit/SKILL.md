---
name: tech-debt-audit
description: >-
  适用于用户要求对单个仓库、指定子树、或跨多个相关仓库（同一 org 的主要 repos、用户给出的 repo 列表、强相关的多仓系统）做技术债、架构健康、代码质量、可维护性、测试债、依赖/配置债、重复代码、复杂度或结构性腐烂审计时使用。
  产出带 file:line 证据、工具结果、严重度/工作量、Top priorities、quick wins、误报排除和开放问题的审计报告；跨仓时在每仓报告之外增加组合级摘要与跨边界发现。
  包含可选的数学结构 lens（对称性/代数结构/组合性）来发现宏观设计债，但每个结论必须落到代码证据。
  不用于普通 PR diff review、公开发布预检、单点 bug 调试或纯安全审计；这些场景分别走 review、release-quality、debug 或安全专项流程。
---

# Tech Debt Audit

对单个仓库、指定子树，或多仓组合（portfolio）做证据化技术债审计。目标不是产出一份看起来全面的 checklist，而是找出工程师愿意行动的结构性问题。

## 核心原则

- **先看现场，再判断**：不要在理解 README、manifest、目录、入口、测试与近期 churn 之前形成结论。
- **证据优先**：每个具体 finding 必须有 `file:line` 或明确的工具输出来源。没有证据的直觉只能进入 open questions。
- **工具是信号，不是裁判**：工具结果必须结合代码语义解释。不要因为某个分数低就机械要求修复。
- **数学 lens 要翻译成人话**：可以用对称性、代数结构、组合性观察系统，但报告必须说明它对应的真实维护风险。
- **不要建议重写**：除非用户明确要重写评估，否则只给具体、可分阶段落地的改进。
- **不要凑数**：finding 数量服从证据质量。小仓库只有 5 个高质量 finding 也比 50 个泛泛建议好。

## 工作流

### 1. 定义审计范围

#### 单仓 / 子树（默认）

确认审计目标是整个仓库还是指定子树。如果用户没有给范围，默认从当前仓库根目录开始。

#### 跨仓 / 组合（portfolio）

当用户明确要求审计**多个仓库**时（例如「org 下主要 repo」「这几个强相关服务一起审」「微服务全家桶」），进入**组合审计**模式。必须先与用户（或显式输入）对齐下面几项，再对每个被纳入的仓执行下文的 Orientation pass：

| 项 | 说明 |
|---|---|
| **Repo 集合** | 优先使用用户给出的列表（`owner/repo`）。若只有 org 名，用 `gh repo list <ORG> --limit <N>`、`gh api orgs/ORG/repos` 等列出候选，再按下列规则收敛到「主要」集合；不要把 org 里每一个 fork/空壳/存档仓不经筛选全跑一遍。 |
| **纳入准则** | 默认：非 archive、`--source` 为 org 自有（按需可含 fork）、最近 12 个月有提交或仍有生产依赖证据、体积/LOC 与 churn 在合理范围。用户说「只要核心 N 个」时以用户为准。 |
| **排除准则** | 自动生成仓、镜像仓、纯文档站、已无维护且用户未要求纳入的仓，写入 `Portfolio scope` 的 excluded 列表并简述原因。 |
| **检出方式** | 若工作区只有清单没有克隆：记录「需用户本地克隆或 CI 挂载的路径」，或引导用 `gh repo clone` / workspace 多 root；每个被审计仓必须有**可读的本地根目录**才能写 file:line 证据。无法检出只能写 open questions，不得编造路径。 |
| **交付物布局** | 每个被审计仓一份单仓报告（见下）；组合根目录（用户指定目录或当前工作区根）一份 `TECH_DEBT_AUDIT_PORTFOLIO.md`（或用户指定名），汇总跨仓结论。 |

**单仓报告路径（组合模式下）**：`tech-debt-audits/<owner>_<repo>/TECH_DEBT_AUDIT.md`（下划线避免嵌套路径歧义；若用户指定统一输出目录则听从用户）。单仓模式仍默认可用仓库根目录的 `TECH_DEBT_AUDIT.md`。

**组合级必须额外产出**（写入 `TECH_DEBT_AUDIT_PORTFOLIO.md`）：

- **Portfolio scope**：repo 列表、分支/commit 基线、检出状态、排除的仓及原因。
- **Cross-repo/system mental model**：这些仓如何接在一起（数据流、发布边界、共享库、API 版本假设）。无证据处写 open questions。
- **Cross-cutting findings**：只属于「多仓一起看」才明显的问题（例如同一逻辑在 3 个 repo 各实现一套、breaking API 与用户端版本漂移、共享 proto/类型不同步、重复且矛盾的配置约定）。**每条仍须给出至少一个仓内的 `file:line`（或等价工具输出锚点）**；纯「org 范围很大」的泛泛判断不算 finding。
- **Per-repo roll-up 表**：每行一个 repo：Critical/High/Med/Low 计数、一句话最大债、链到该仓完整报告路径。
- **组合级 Top 5 / Quick wins**：优先列「不动会拖累多仓」的项；若某事项只影响单仓，留在该仓报告里。

**并行**：多仓时按仓拆分 orientation + deterministic + semantic pass（边界清楚时并行），**最后一轮 synthesis 必须合并去重**：同一根因跨多仓只保留一条组合 finding，并在表格里引用多仓 `file:line`。

**与单仓流程的关系**：每个被纳入的仓仍完整执行下文 **Orientation → 工具 → 语义 →（可选）structural lens → 单仓 synthesis**；组合文档是增量层，不替代单仓证据。

若请求实际是以下任务，转给更合适的流程：

- PR 或 diff review：走代码审查，不启动全仓库技术债审计。
- 公开发布、开源前检查、Scorecard 分数修复：优先使用 `release-quality`。
- 单个 bug、报错、CI 失败：先调试或复现，不做全仓库审计。
- 专门安全审计或渗透测试：本 skill 只能覆盖 security hygiene，不替代安全专项。

### 2. Orientation pass

形成架构 mental model，至少读取或检查：

- README、贡献文档、架构文档、ADR、重要 docs。
- manifest 和 lockfile：如 `package.json`、`pyproject.toml`、`Cargo.toml`、`go.mod`、`pom.xml`、`Gemfile`。
- 目录结构、入口点、主要模块、测试目录、脚本命令。
- `git status`、当前分支、最近提交、最近 6 个月 churn。
- 最大文件、最长函数、最常改文件，以及它们的交集。

在继续之前，写出 1-2 段 mental model：系统实际如何组织、主要数据/控制流是什么、README 与现实是否一致。

### 3. Deterministic tool pass

优先运行仓库已有命令。额外工具按类别选择；工具缺失时记录“未运行原因”和“是否值得安装”，不要静默跳过，也不要全局安装工具。

| 类别 | 工具示例 | 用途 | 典型证据 |
|---|---|---|---|
| Repo posture / supply chain | `scorecard`, `osv-scanner`, ecosystem audit | 发现仓库维护、安全实践、依赖风险 | 具体 check 名称、漏洞、CI/权限风险 |
| License / provenance | `reuse lint`, licensee | 检查 SPDX、版权、许可证覆盖 | 缺失 SPDX、许可证冲突、不明来源文件 |
| Complexity hotspots | `lizard`, language-native complexity tools | 找长函数、高圈复杂度、高参数数热点 | 函数名、NLOC、CCN、参数数 |
| Duplication / clone detection | `jscpd`, language-native clone tools | 找复制粘贴和抽象缺失 | clone group、重复行数、文件位置 |
| Dependency hygiene | `depcheck`, `knip`, `cargo machete`, `cargo udeps`, `pip-audit`, `npm audit` | 找未用依赖、重复依赖、漏洞 | 包名、调用位置、lockfile 证据 |
| Architecture graph | `madge`, `pydeps`, `go list`, `cargo metadata`, `bazel query` | 找依赖环、层级倒置、跨边界引用 | cycle、import path、模块边界 |
| Static analysis / typing | `tsc --noEmit`, `ruff`, `mypy`, `ty`, `clippy`, `go vet`, `staticcheck` | 找类型和静态规则债 | diagnostic、规则 ID、文件位置 |
| Test and coverage | repo test command, coverage tools | 找关键路径缺测试、跳过/脆弱测试 | 覆盖缺口、skip/flaky 标记、高 churn 无测试 |
| Secrets / config hygiene | `gitleaks`, `rg` patterns, env docs check | 找硬编码 secret、配置漂移 | 变量名、文件位置、文档缺口 |

工具结果的处理规则：

- 将工具发现折叠进 finding，而不是把原始输出整段粘贴到报告里。
- 同一个根因只保留一个 finding，其他工具证据放在同一条 finding 的 evidence 中。
- Scorecard 聚合分数只能作为背景，优先看具体 check；公开发布决策仍交给 `release-quality`。
- `reuse lint` 发现的 license/provenance 问题可以作为技术债；是否选择或变更许可证需要用户决策。

### 4. Semantic debt pass

围绕以下维度找具体证据：

- **Architecture decay**：依赖环、层级倒置、god files/functions、跨边界调用、抽象无人使用。
- **Consistency rot**：HTTP client、日志、错误处理、配置、校验、日期、序列化等存在多套做法。
- **Type and contract debt**：`any`、`unknown` 滥用、`type: ignore`、松散 dict、trust boundary 缺 schema。
- **Test debt**：关键路径无测试、高 churn 文件无测试、测试只锁实现细节、skip/flaky。
- **Dependency and config debt**：未用/重复依赖、env sprawl、默认值不一致、文档与实际命令不一致。
- **Performance and resource hygiene**：N+1、热路径阻塞 I/O、重复序列化、未清理 handle/listener。
- **Error handling and observability**：吞异常、blanket catch、错误 shape 不一致、关键路径缺日志/trace。
- **Security hygiene**：硬编码 secret、字符串拼 SQL、弱 crypto、过宽 CORS/auth、输入未校验。
- **Documentation drift**：README、注释、API 文档与代码现实冲突。

### 5. Structural / algebraic lens pass

这一阶段用于发现宏观结构债。它不能替代代码证据，也不能输出纯术语结论。

| Lens | 观察问题 | 债务信号 | 报告翻译 |
|---|---|---|---|
| Symmetry / group-like structure | 同一业务概念的变换、反变换、权限、状态迁移是否成组且一致 | 多处“几乎一样”的状态转换；undo/rollback 不闭合；权限正反逻辑不对称 | “同一状态机在 3 个模块各自实现，导致新增状态要改 3 处且容易漏掉回滚路径。” |
| Algebraic structure | merge、reduce、pipeline、配置叠加、错误累积是否有 identity、associativity、zero-like 行为 | 合并顺序敏感；默认值不是中性元；错误累积短路规则不一致 | “配置合并不是结合的，调用顺序改变会改变最终行为，测试难以覆盖所有排列。” |
| Category / composition | 模块作为对象、接口/数据流作为 morphism，组合后语义是否保持 | adapter 泄漏；跨层调用；组合后类型/错误/生命周期语义变形 | “两个看似可组合的 adapter 实际共享隐藏全局状态，组合顺序影响请求上下文。” |
| Representation | 数据结构是否承载知识，让逻辑保持简单 | 业务规则散在 if/else；缺显式状态/表驱动；编码约定靠命名猜 | “规则没有进入数据表示，导致每个入口都重新解释字符串约定。” |

Structural finding 必须满足：

- 有至少一个 `file:line` 证据。
- 能说明维护风险，而不是只说“不够范畴论”。
- 能给出具体修复方向，如集中状态表、定义 merge contract、收敛 adapter interface、补 property-style test。

### 6. Synthesis

合并工具结果和人工阅读结果，按影响排序。默认不要超过 50 条 findings；如果证据非常多，保留高影响项，把其余放入 appendix 或 backlog。

严重度建议：

- **Critical**：可能导致数据损坏、权限绕过、发布/运行不可恢复失败，或阻塞核心演进。
- **High**：高频修改区的结构债，已明显增加 bug 风险或交付成本。
- **Medium**：真实维护成本或局部风险，但有清晰边界。
- **Low**：低风险清理、文档漂移、局部一致性问题。

工作量建议：

- **S**：单文件或少量配置，可直接修。
- **M**：跨几个文件，需要测试或迁移。
- **L**：跨模块、需要设计顺序或分阶段迁移。

## 报告格式

默认写入或建议写入 `TECH_DEBT_AUDIT.md`（组合模式下每仓见「定义审计范围」中的路径约定）。如果用户只要口头评估，可以用同样结构简化输出。

**组合模式**另需 `TECH_DEBT_AUDIT_PORTFOLIO.md`，结构在「跨仓 / 组合」一节已列；可与下面单仓模板共用 Executive Summary / Findings 表格风格，但必须多出 **Cross-cutting** 与 **Per-repo roll-up**。

```markdown
# Tech Debt Audit - <repo or scope>

Generated: <date>
Scope: <repo root or subtree; or "portfolio" + 本文件对应的仓名>
Baseline: <branch/commit, dirty status>

## Executive Summary
- <ranked summary, max 10 bullets>

## Architecture Mental Model
<1-2 paragraphs grounded in files read>

## Tool Evidence
| Category | Command | Status | Key signal | Notes |
|---|---|---|---|---|

## Findings
| ID | Category | File:Line | Severity | Effort | Evidence | Recommendation |
|---|---|---|---|---|---|---|

## Top 5 Priorities
1. **F001 - <title>**: <why now, concrete refactor/test sketch>

## Quick Wins
- [ ] <low effort, medium+ impact item>

## Structural Lens Notes
- <symmetry/algebra/composition observation with plain-language risk>

## Things That Look Bad But Are Actually Fine
- <false positive considered and why it is acceptable>

## Open Questions
- <question that needs maintainer context>

## Appendix: Commands Not Run
- `<command>`: <reason, whether worth installing>
```

## Large repositories

When the repo is large, scope before parallelizing. Prefer:

1. Identify top-level modules and churn hotspots.
2. Split independent reading/audit briefs by module or lens.
3. Keep shared synthesis in one place so findings are deduped and ranked.

When using `zrr1999/roles`, use `inspector` for bounded code reading and tool evidence, and `verifier` with `lens: architecture`, `performance`, or `security` for focused review. Do not invent new role names inside this skill.

## Large portfolios（多仓规模）

当 repo 数量多或总 LOC 极大时：

1. **先收敛清单**：与用户确认「主要」定义（例如核心服务 + 共享库，不含示例与脚手架）。
2. **分批或采样**：未审计的仓在 `TECH_DEBT_AUDIT_PORTFOLIO.md` 的 backlog 中列出，并说明为何本轮未跑。
3. **仍可并行**：每仓独立 brief，组合 synthesis 只合并跨仓结论与 roll-up，避免把多仓 raw findings 无筛选堆进一份文件。

## Repeat-run mode

If `TECH_DEBT_AUDIT.md` already exists:

- Read it first.
- Mark fixed findings as `RESOLVED`.
- Update stale line references.
- Tag new findings as `NEW`.
- Preserve stable IDs when the same root cause remains.

组合模式：

- 每个 `tech-debt-audits/<owner>_<repo>/TECH_DEBT_AUDIT.md` 按上款做 repeat-run。
- `TECH_DEBT_AUDIT_PORTFOLIO.md` 在再次运行时对齐 repo 列表变化；跨仓 finding ID 建议加前缀（如 `X001`）与单仓 `F001` 区分，并在描述中引用各仓文件。

## Common mistakes

- Running tools first and treating their output as the report.
- Producing architecture claims without file citations.
- Using mathematical language as decoration.
- Trying to fix Scorecard aggregate score inside a technical debt audit.
- Expanding into a release-readiness workflow; use `release-quality` for that.
- Listing every lint warning as a finding instead of identifying root causes.
