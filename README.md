# Zhan Rongrui's Agent Skills

An Agent Skills collection for my own projects, to provide reusable workflows in tools like Cursor, Copilot, etc.

## Related: `roles` repo

The sibling [`zrr1999/roles`](https://github.com/zrr1999/roles) package defines **agent-first** subagent roles only:

- **`inspector`** — bounded evidence, reading, structure, tradeoffs, scoping
- **`executor`** — focused implementation with a merge-ready diff / checks contract
- **`verifier`** — repro, regression, and review against a named claim; set optional **`lens`** (`security`, `performance`, `architecture`) on the brief for specialized review depth

There is **no** director / work-mode role layer there.

- **Skills** (this repo): reusable *methods*—workflows, preferences, design principles, docs, learnings.
- **Roles**: *which responsibility contract* runs a bounded brief; orchestration picks roles and merges results.

Load **`project-workflows`** when you need a consistent playbook for greenfield / maintenance / learning-from-a-repo / mixed asks, when to clarify, when to parallelize, and when to call other skills. **Requirement clarification, parallel brief splitting, and CLI-first investigation are built into `project-workflows`**—they are not separate skills in this repository. Load domain skills when the task benefits, independent of which [`roles`](https://github.com/zrr1999/roles) contract is active (`inspector` / `executor` / `verifier`).

**Skills in this repository**

| Skill | What it covers |
|-------|----------------|
| `project-workflows` | Unified project workflow: packet contract, clarification, parallelization boundaries, CLI-first, delegation to other skills; **brief fields align with [`zrr1999/roles` Brief contract](https://github.com/zrr1999/roles/blob/main/README.md#brief-contract)** when dispatching subagents |
| `tech-preferences` | Stack and tooling preferences / tradeoffs |
| `unix-software-design` | Module boundaries, interfaces, simplicity |
| `modern-python` | uv, ruff, ty, Python project hygiene |
| `get-api-docs` | Third-party library / API documentation |
| `compound-learnings` | Structured learnings and retrieval |
| `spark` | Capture, refine, and plan from project ideas via SPARK.md |
| `release-quality` | Public-release preflight for repo hygiene, Scorecard, security checks, and user decisions |
| `tech-debt-audit` | Evidence-based codebase health and technical debt audit with categorized tool signals and structural/algebraic design lenses |

**Typical pairings with `roles` (examples)**

- **Greenfield** — parallel `inspector` briefs when feasibility splits; then `executor`; then `verifier` to validate the claim.
- **Maintenance** — `inspector` + `verifier` in parallel when structure review and repro are independent; then `executor`; then `verifier` for regression.
- **Study another repo** — parallel `inspector` briefs per subsystem or question; synthesize in one pass or merge at orchestration; no separate “writer” role—packaging is orchestrator output unless you split a brief explicitly.
- **Focused review** — `verifier` with `lens: security` / `performance` / `architecture` as needed.

**数量说明**：下表列出本仓库内全部 skill，职责互不重叠。`project-workflows` 合并了原先分散的开坑/维护/读项目/路由与澄清、并行、CLI-first 说明；不再单独提供 `requirements-shaping`、`expert-orchestration` 或 `agent-cli-toolkit` 作为本仓库内的 skill。

## Evals（skill-creator 格式）

每个 skill 在 `skills/<skill-name>/evals/evals.json` 下有评测用例。本地快速校验 JSON 语法：`for f in skills/*/evals/evals.json; do jq empty "$f"; done`。

### One-click install

Installer 会（按需）安装 **Vite+**（[`curl -fsSL https://vite.plus | bash`](https://vite.plus)）以获得托管的 **Node.js**，再装 **pnpm**，升级或安装 **`gh-llm`** 扩展，全局安装 **`@aisuite/chub`**（`get-api-docs` 使用），最后用 **`pnpx skills add`** 安装本仓库全部 skill。默认还会从下列**外仓**再装一组可选 skill；不需要时设置 **`SKIP_EXTERNAL_SKILLS=1`**。

外仓来源（与 `install.sh` 中 `pnpx skills add …` 一致）：

- `anthropics/skills`（`skill-creator`）
- `cloudflare/skills`（`cloudflare`、`wrangler`）
- `shigurelab/gh-llm`（`github-conversation`）
- `aviator-co/agent-plugins`（`av-cli`）
- `vibe-motion/skills`（`svg-assembly-animator`、`procedural-fish-render`、`ruler-progress-render`）
- `spore-lang/spore`（`spore-language`）

非交互场景可设置 `VP_NODE_MANAGER=yes`（安装 Vite+ 时跳过交互提示；`install.sh` 已默认导出）。

```bash
curl -fsSL https://raw.githubusercontent.com/zrr1999/skills/main/install.sh | bash
```

装齐本仓库全部 skill（需已有 Node/pnpm 与 `skills` CLI）：

```bash
pnpx skills add zrr1999/skills --all -g -y
```

### Manual install

不用安装脚本时，可直接用 package-runner（与脚本一致推荐 **pnpm** / `pnpx`；若你用 Bun，可用 `bunx` 代替）：

```bash
pnpx skills add zrr1999/skills --all -g -y
```

## 常用 Skills（本仓库内）

```bash
# 添加全局可用的 skill（本仓库全部）
pnpx skills add zrr1999/skills --all -g -y

# 或按需单独添加示例
pnpx skills add zrr1999/skills -g --skill project-workflows
pnpx skills add zrr1999/skills -g --skill tech-preferences
pnpx skills add zrr1999/skills -g --skill unix-software-design
pnpx skills add zrr1999/skills -g --skill modern-python
pnpx skills add zrr1999/skills -g --skill get-api-docs
pnpx skills add zrr1999/skills -g --skill compound-learnings
pnpx skills add zrr1999/skills -g --skill spark
pnpx skills add zrr1999/skills -g --skill release-quality
pnpx skills add zrr1999/skills -g --skill tech-debt-audit
```

## 本地开发

```bash
# 默认安装已发布的 GitHub 仓库版本（含 Vite+ / pnpm / chub / skills）
bash install.sh

# 调试本地未发布改动时，覆盖技能来源
REPO_SOURCE=./skills bash install.sh

# 调试本地未发布改动时，直接从本地目录添加
pnpx skills add ./skills -g --skill unix-software-design

# 与 prek.toml 对齐的本地检查（需已 prek install）
prek run check-json check-yaml check-executables-have-shebangs --all-files
# 或运行全部已配置 hooks：
prek run --all-files
```
