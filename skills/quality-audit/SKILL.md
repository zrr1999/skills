---
name: quality-audit
description: >-
  适用于对单个仓库、指定子树或跨多个相关仓库做质量检查与优化规划：技术债、架构健康、代码质量、可维护性、测试债、依赖/配置债、重复代码、复杂度、CI/仓库卫生，以及公开发布/开源/v1.0/package publish 前的 release readiness、OpenSSF Scorecard、安全、许可证与 public surface 预检。先判定 maintenance audit、public-release preflight 或 portfolio/mixed 模式；直接调用可用工具并在对话中输出带 file:line 或工具证据、风险分级、用户决策、Top priorities、quick wins、误报排除和开放问题的结论。默认不生成报告文件，除非用户明确要求保存。不要用于普通 PR diff review、单点 bug 调试或纯安全渗透审计。
---

# Quality Audit

对项目做统一的质量检查与优化规划。这个 skill 覆盖两类常被混在一起的需求：

- **Maintenance / technical-debt audit**：代码库长期健康、架构债、可维护性、测试债、依赖与配置债。
- **Public-release preflight**：公开发布、开源、v1.0、package publish 前的仓库卫生、安全、许可证、CI 与 public surface 检查。

目标不是跑一串 checklist 或把分数刷高，而是收集证据，区分真正阻塞、需要用户决策、可安全修复与可排入 backlog 的事项。

## 核心原则

- **先判定模式**：开头明确本次是 maintenance audit、public-release preflight、portfolio audit，还是 mixed。模式决定工具、输出结构与是否需要用户决策。
- **先看现场，再判断**：不要在理解 README、manifest、目录、入口、测试、CI 与近期 churn 之前形成结论。
- **证据优先**：每个具体 finding 必须有 `file:line` 或明确工具输出来源。没有证据的直觉只能进入 open questions。
- **工具是信号，不是裁判**：Scorecard、lint、复杂度、漏洞扫描等结果必须结合项目语义解释，不要机械追分或堆原始输出。
- **发布相关事项先决策**：不要在未获确认时公开 repo、创建 release、选择/更换 license、重写历史、轮换密钥、删除用户数据或做高风险升级。
- **优化要可落地**：不要建议“重写项目”。给出小步、可验证、能分阶段落地的改进。
- **不要凑数**：finding 数量服从证据质量。小仓库只有 5 个高质量 finding 也比 50 个泛泛建议好。

## 1. 判定模式与边界

### Public-release preflight

当用户说到以下意图时，优先使用发布预检模式：

- “make this repo public”、私有转公开、开源、公开发布。
- first release、v1.0、GitHub release/tag、package publish。
- public-ready check、release quality、preflight。
- OpenSSF Scorecard、supply-chain、security posture、license、REUSE、仓库公开面。

发布预检的核心是**把公开曝光风险讲清楚**，不是把所有技术债一次性修完。

### Maintenance / technical-debt audit

当用户要求技术债、架构健康、代码质量、可维护性、测试债、复杂度、重复代码、依赖/配置债、文档漂移、长期优化路线时，使用 maintenance audit 模式。

维护审计的核心是**找结构性问题和优化优先级**，不是决定仓库能不能公开。

### Mixed mode

如果用户同时提到“准备公开/发布”和“顺便把技术债处理一下”，使用 mixed mode：

1. 先做 public-release preflight，找 Blocker 与 User Decision。
2. 再做 maintenance audit，给出发布后或发布前可选的 Top priorities。
3. 输出中明确哪些是“公开前必须处理”，哪些只是“长期质量优化”。

### 不适用场景

- PR 或 diff review：不要启动全仓库审计；做范围限定的 code review，可借用质量维度作为 lens。
- 单个 bug、报错、CI 失败：先复现和调试，不做全仓质量审计。
- 纯安全审计、渗透测试、合规法律意见：本 skill 只覆盖 security hygiene 与发布风险，不替代专项审计。

## 2. 定义范围

### 单仓 / 子树（默认）

确认审计目标是整个仓库还是指定子树。如果用户没有给范围，默认从当前仓库根目录开始。

记录：当前分支、commit、remote、dirty status、用户指定目标与排除项。发布预检必须说明工作树是否就是将要发布的状态。

### 跨仓 / 组合（portfolio）

当用户明确要求审计多个相关仓库（同一 org 的主要 repos、微服务组合、用户给出的 repo 列表）时，进入 portfolio mode。先对齐：

| 项        | 说明                                                                                                                               |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Repo 集合 | 优先使用用户给出的列表。若只有 org 名，用 `gh repo list <ORG> --limit <N>` 或 `gh api orgs/ORG/repos` 列出候选，再筛选“主要”集合。 |
| 纳入准则  | 默认：非 archive、org 自有、最近 12 个月有提交或仍有生产依赖证据、体积/LOC 与 churn 合理。用户指定优先。                           |
| 排除准则  | 自动生成仓、镜像仓、纯文档站、已无维护且用户未要求纳入的仓，写入 scope 并说明原因。                                                |
| 检出方式  | 每个被审计仓必须有可读本地根目录才能写 `file:line` 证据；无法检出只能写 open questions，不得编造路径。                             |
| 输出组织  | 默认直接在对话中给每仓结论与组合 roll-up；只有用户明确要求保存时才写文件。                                                         |

默认输出方式：

- 直接调用可用工具，随后在对话中输出结构化结论。
- 不默认创建或更新 `QUALITY_AUDIT.md`、`TECH_DEBT_AUDIT.md`、portfolio 文档或其它审计文件。
- 只有用户明确说“保存成文件”“更新已有审计文档”“生成报告”时，才写入 `QUALITY_AUDIT.md` 或用户指定路径。
- 如果用户要求基于已有审计继续，可以先读取旧审计文档（如 `QUALITY_AUDIT.md` / `TECH_DEBT_AUDIT.md`）来保留上下文，但不要自动覆盖它。

组合级对话输出必须包含：repo 列表、分支/commit 基线、排除项、跨仓 mental model、跨仓 findings、每仓 roll-up、组合级 Top priorities / Quick wins。

## 3. Orientation pass

形成项目 mental model，至少读取或检查：

- README、贡献文档、架构文档、ADR、重要 docs。
- manifest 与 lockfile：如 `package.json`、`pyproject.toml`、`Cargo.toml`、`go.mod`、`pom.xml`、`Gemfile`。
- 目录结构、入口点、主要模块、测试目录、脚本命令。
- CI/workflow、发布脚本、package metadata、公开 URL 与示例。
- `git status`、当前分支、remote、最近提交、最近 6 个月 churn。
- 最大文件、最长函数、最常改文件，以及它们的交集。

在继续之前，写出 1-2 段 mental model：系统实际如何组织、主要数据/控制流是什么、README 与现实是否一致。

## 4. Deterministic tool pass

优先运行仓库已有命令。额外工具按场景选择；工具缺失时记录“未运行原因”和“是否值得安装”，不要静默跳过，也不要全局安装工具。

| 类别                        | 工具示例                                                                                   | 适用模式                           | 典型证据                                                                        |
| --------------------------- | ------------------------------------------------------------------------------------------ | ---------------------------------- | ------------------------------------------------------------------------------- |
| Repo posture / supply chain | `scorecard --repo=github.com/OWNER/REPO --format=json`, `osv-scanner`                      | release / mixed / maintenance 背景 | 具体 check、漏洞、CI/权限风险；不要只看聚合分数                                 |
| GitHub Actions security     | `zizmor .github/workflows` 或 `uvx zizmor .github/workflows`                               | release / mixed                    | `pull_request_target`、过宽 permissions、credential persistence、未 pin actions |
| Secrets / sensitive data    | `gitleaks detect --source . --redact`, `rg` patterns                                       | release / mixed / maintenance      | 确认 secret、私密 URL、样例凭据；注意历史泄漏风险                               |
| License / provenance        | `reuse lint`, licensee, README/LICENSE/package metadata                                    | release / mixed / maintenance      | 缺失 license、SPDX、版权、许可证冲突、不明来源文件                              |
| CI / release path           | repo test/build/package/smoke commands                                                     | release / mixed                    | 公开 quickstart、install、build、package、release artifact 是否可复现           |
| Complexity hotspots         | `lizard`, language-native complexity tools                                                 | maintenance / mixed                | 函数名、NLOC、CCN、参数数                                                       |
| Duplication / clones        | `jscpd`, language-native clone tools                                                       | maintenance / mixed                | clone group、重复行数、文件位置                                                 |
| Dependency hygiene          | `depcheck`, `knip`, `cargo machete`, `cargo udeps`, `pip-audit`, `npm audit`, `pnpm audit` | all                                | 未用/重复依赖、漏洞、lockfile 证据                                              |
| Architecture graph          | `madge`, `pydeps`, `go list`, `cargo metadata`, `bazel query`                              | maintenance / mixed                | 依赖环、import path、模块边界                                                   |
| Static analysis / typing    | `tsc --noEmit`, `ruff`, `mypy`, `ty`, `clippy`, `go vet`, `staticcheck`                    | maintenance / mixed                | diagnostic、规则 ID、文件位置                                                   |
| Tests and coverage          | repo test command, coverage tools                                                          | all                                | 覆盖缺口、skip/flaky 标记、高 churn 无测试                                      |
| Documentation drift         | README quickstart vs actual commands                                                       | release / mixed / maintenance      | 文档命令失败、过期 API、私有链接                                                |

工具结果处理规则：

- 将工具发现折叠进 finding，而不是把原始输出整段粘贴到最终回答里。
- 同一个根因只保留一个 finding，其他工具证据放在同一条 finding 的 evidence 中。
- Scorecard 聚合分数只能作为背景，优先看具体 check；公开发布要按风险与用户目标排序。
- `reuse lint` 与 license/provenance 问题可作为质量证据；是否选择或变更许可证需要用户决策。

## 5. Semantic passes

### Maintenance / technical debt dimensions

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

### Public-release readiness dimensions

围绕公开曝光风险检查：

- **Public surface**：README、quickstart、examples、screenshots、package metadata、公开 URL、private notes、生成文件、大文件/二进制。
- **Legal / policy decisions**：LICENSE、NOTICE、SECURITY.md、CONTRIBUTING、Code of Conduct（如用户需要）、package license 字段。
- **Secrets and history**：当前文件与 Git 历史中的 secret、客户数据、内部 URL；确认 secret 后要询问 rotate 与是否 rewrite history。
- **Advertised path**：用户会照 README 执行的安装、构建、测试、运行、发布路径是否成立。
- **Repo / CI security**：workflow permissions、branch protection、token 权限、第三方 actions pinning、release/signing policy。
- **Supply chain**：漏洞、未维护依赖、锁文件、发布 artifact provenance、binary artifacts。

## 6. Structural / algebraic lens（可选）

当用户要求更抽象的结构视角，或系统表现出强组合/状态/变换特征时使用。这个 lens 不能替代代码证据，也不能输出纯术语结论。

| Lens                            | 观察问题                                                                                  | 债务信号                                                           | 输出翻译                                                                   |
| ------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| Symmetry / group-like structure | 同一业务概念的变换、反变换、权限、状态迁移是否成组且一致                                  | 多处“几乎一样”的状态转换；undo/rollback 不闭合；权限正反逻辑不对称 | “同一状态机在 3 个模块各自实现，导致新增状态要改 3 处且容易漏掉回滚路径。” |
| Algebraic structure             | merge、reduce、pipeline、配置叠加、错误累积是否有 identity、associativity、zero-like 行为 | 合并顺序敏感；默认值不是中性元；错误累积短路规则不一致             | “配置合并不是结合的，调用顺序改变会改变最终行为，测试难以覆盖所有排列。”   |
| Category / composition          | 模块作为对象、接口/数据流作为 morphism，组合后语义是否保持                                | adapter 泄漏；跨层调用；组合后类型/错误/生命周期语义变形           | “两个看似可组合的 adapter 实际共享隐藏全局状态，组合顺序影响请求上下文。”  |
| Representation                  | 数据结构是否承载知识，让逻辑保持简单                                                      | 业务规则散在 if/else；缺显式状态/表驱动；编码约定靠命名猜          | “规则没有进入数据表示，导致每个入口都重新解释字符串约定。”                 |

Structural finding 必须满足：有至少一个 `file:line` 证据；能说明维护风险；能给出具体修复方向，如集中状态表、定义 merge contract、收敛 adapter interface、补 property-style test。

## 7. Triage and synthesis

合并工具结果和人工阅读结果，按影响排序。默认不要超过 50 条 findings；如果证据非常多，保留高影响项，把其余放入 appendix 或 backlog。

### 发布预检分类

| Class         | Meaning                                           | Examples                                                                                   | Action                       |
| ------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------ | ---------------------------- |
| Blocker       | 公开发布不应继续，除非先处理或用户明确接受风险    | 确认 secret、私有客户数据、意图开源但缺 license、README 安装路径坏、已知可利用漏洞         | 停下并要求用户决策或批准修复 |
| User Decision | 多个合理选择，需要用户承担产品/法律/安全/声誉取舍 | license 选择、是否 rewrite history、是否延后发布、branch protection、signed release policy | 给选项、后果、推荐默认值     |
| Fix Now       | 低风险且符合用户意图的清理                        | README typo、过期私有链接、缺 `.env.example`、明显 `.gitignore` 漏项                       | 可提出或应用聚焦修复         |
| Backlog       | 有用但不阻塞本次发布                              | 更多 examples、badge polish、非关键 Scorecard 提升、低风险 fuzzing                         | 记录为后续，不默认阻塞       |

### 维护审计严重度与工作量

严重度：

- **Critical**：可能导致数据损坏、权限绕过、发布/运行不可恢复失败，或阻塞核心演进。
- **High**：高频修改区的结构债，已明显增加 bug 风险或交付成本。
- **Medium**：真实维护成本或局部风险，但有清晰边界。
- **Low**：低风险清理、文档漂移、局部一致性问题。

工作量：

- **S**：单文件或少量配置，可直接修。
- **M**：跨几个文件，需要测试或迁移。
- **L**：跨模块、需要设计顺序或分阶段迁移。

Mixed mode 中，先列 Blocker/User Decision，再列按严重度排序的维护债；不要把长期 polish 伪装成公开发布 blocker。

## 8. 输出格式

默认只在对话中输出，不生成或更新文件。输出必须短到能帮助决策；原始工具输出只在有用时摘要引用，且不要保存未脱敏 secret。用户明确要求保存时，才把同样结构写入用户指定路径或 `QUALITY_AUDIT.md`。

```markdown
# Quality Audit - <repo or scope>

Generated: <date>
Scope: <repo root, subtree, or portfolio>
Mode: <maintenance / release / mixed / portfolio>
Baseline: <branch/commit, remote, dirty status>

## Executive Summary

- <ranked summary, max 10 bullets>

## Architecture / Release Mental Model

<1-2 paragraphs grounded in files read>

## Evidence Snapshot

| Category | Command / Source | Status | Key signal | Notes |
| -------- | ---------------- | ------ | ---------- | ----- |

## Release Readiness（release/mixed 时必填）

Status: Ready / Ready after decisions / Not ready

Findings:

- [Blocker/User Decision/Fix Now/Backlog] <area>: <evidence> -> <recommendation>

Decisions needed:

1. <decision, options, recommended default>

Safe fixes I can apply now:

- <focused fix and why it is low risk>

## Quality Findings

| ID  | Category | File:Line / Tool Evidence | Severity | Effort | Evidence | Recommendation |
| --- | -------- | ------------------------- | -------- | ------ | -------- | -------------- |

## Top Priorities

1. **F001 - <title>**: <why now, concrete refactor/test/release sketch>

## Quick Wins

- [ ] <low effort, medium+ impact item>

## Structural Lens Notes

- <optional symmetry/algebra/composition observation with plain-language risk>

## Things That Look Bad But Are Actually Fine

- <false positive considered and why it is acceptable>

## Open Questions

- <question that needs maintainer context>

## Appendix: Commands Not Run

- `<command>`: <reason, whether worth installing>
```

组合模式的对话输出还要包含：Portfolio scope、Cross-repo/system mental model、Cross-cutting findings、Per-repo roll-up、组合级 Top priorities / Quick wins。只有用户明确要求保存时，才写 `QUALITY_AUDIT_PORTFOLIO.md` 或其它文件。

## 9. Repeat-run mode

如果用户明确要求复查/延续已有审计，或当前上下文已经指向 `QUALITY_AUDIT.md` / `TECH_DEBT_AUDIT.md` 等旧审计文档：

- 先读取旧文档以理解历史 finding。
- 在对话输出中标记已修复 finding 为 `RESOLVED`。
- 更新 stale line references。
- 同一根因保留稳定 ID。
- 新 finding 标记为 `NEW`。
- 除非用户明确要求保存，不要覆盖旧文档。

组合模式中，每仓结论和 portfolio roll-up 都按同样规则输出；跨仓 finding ID 建议加前缀（如 `X001`）与单仓 `F001` 区分。

## 10. Large repositories and roles

仓库很大时先收敛范围再并行：

1. 识别 top-level modules 与 churn hotspots。
2. 按模块或 lens 拆分独立 reading/audit briefs。
3. 最后一轮 synthesis 必须合并去重并排序，避免把 raw findings 堆进最终回答。

当使用 `zrr1999/roles`：用 `inspector` 做有边界的代码阅读与工具取证；用 `verifier` 搭配 `lens: architecture`、`performance` 或 `security` 做专项复核；需要实现修复时再交给 `executor`。不要在 skill 内发明新 role 名称。

## Common mistakes

- 没判定 mode 就开始跑工具。
- 把工具输出当最终结论，或者把 Scorecard 聚合分数当自动 gate。
- 在没有用户确认前公开 repo、选 license、rewrite history、rotate secrets、删除数据或做行为性大改。
- 公开发布请求里只做技术债清单，漏掉 secrets、license、README quickstart、CI/release path 与 public surface。
- 技术债请求里只追 release hygiene，漏掉架构、测试、重复、复杂度、契约与文档漂移。
- 对数学结构 lens 输出纯术语结论，没有 `file:line` 与维护风险。
- 把普通 PR/diff review 扩大成全仓审计。
- 为了凑数量列每个 lint warning，而不是找根因。
