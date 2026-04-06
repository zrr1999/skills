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

**Skills in this repository (6)**

| Skill | What it covers |
|-------|----------------|
| `project-workflows` | Unified project workflow: packet contract, clarification, parallelization boundaries, CLI-first, delegation to other skills; **brief fields align with [`zrr1999/roles` Brief contract](https://github.com/zrr1999/roles/blob/main/README.md#brief-contract)** when dispatching subagents |
| `tech-preferences` | Stack and tooling preferences / tradeoffs |
| `unix-software-design` | Module boundaries, interfaces, simplicity |
| `modern-python` | uv, ruff, ty, Python project hygiene |
| `get-api-docs` | Third-party library / API documentation |
| `compound-learnings` | Structured learnings and retrieval |

**Typical pairings with `roles` (examples)**

- **Greenfield** — parallel `inspector` briefs when feasibility splits; then `executor`; then `verifier` to validate the claim.
- **Maintenance** — `inspector` + `verifier` in parallel when structure review and repro are independent; then `executor`; then `verifier` for regression.
- **Study another repo** — parallel `inspector` briefs per subsystem or question; synthesize in one pass or merge at orchestration; no separate “writer” role—packaging is orchestrator output unless you split a brief explicitly.
- **Focused review** — `verifier` with `lens: security` / `performance` / `architecture` as needed.

**数量说明**：本仓库当前 **6** 个 skill，职责互不重叠。`project-workflows` 合并了原先分散的开坑/维护/读项目/路由与澄清、并行、CLI-first 说明；不再单独提供 `requirements-shaping`、`expert-orchestration` 或 `agent-cli-toolkit` 作为本仓库内的 skill。

## Evals（skill-creator 格式）

每个 skill 在 `skills/<skill-name>/evals/evals.json` 下有评测用例。效果对比与改进建议见 `evals/EVAL_REPORT.md`。

### One-click install

Run the installer directly:

```bash
curl -fsSL https://raw.githubusercontent.com/zrr1999/skills/main/install.sh | bash
```

The script installs `x-cmd`, uses it to provision a curated modern CLI toolbelt, adds the `gh-llm` GitHub CLI extension, then installs all skills from this repo.

```bash
bunx skills add zrr1999/skills --all -g
```

### Manual install

If you do not want to use the script, run the equivalent command directly:

```bash
bunx skills add zrr1999/skills --all -g
```

## 常用 Skills（本仓库内）

```bash
# 添加全局可用的 skill（一次性装齐 6 个）
bunx skills add zrr1999/skills --all -g

# 或按需单独添加示例
bunx skills add ./skills -g --skill project-workflows
bunx skills add ./skills -g --skill tech-preferences
bunx skills add ./skills -g --skill unix-software-design
bunx skills add ./skills -g --skill modern-python
bunx skills add ./skills -g --skill get-api-docs
bunx skills add ./skills -g --skill compound-learnings
```

## 本地开发

```bash
# 默认安装已发布的 GitHub 仓库版本
bash install.sh

# 调试本地未发布改动时，覆盖技能来源
REPO_SOURCE=./skills bash install.sh

# 调试本地未发布改动时，直接从本地目录添加
bunx skills add ./skills -g --skill unix-software-design
```
