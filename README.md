# Zhan Rongrui's Agent Skills

An Agent Skills collection for my own projects, to provide reusable workflows in tools like Cursor, Copilot, etc.

## Related: `roles` repo

The sibling [`zrr1999/roles`](https://github.com/zrr1999/roles) package defines **expert subagent roles** only (`researcher`, `analyst`, `coder`, `tester`, `writer`). There is **no** director / work-mode role layer there.

- **Skills** (this repo): reusable *methods*—how to kick off a project, run a maintenance pass, read a foreign repo, stack prefs, etc.
- **Roles**: *who* runs a bounded brief; orchestration picks experts and merges results.

Load `work-mode-routing` when you need a consistent rule for **which expert to call** and when to parallelize; load domain skills (`project-kickoff`, `maintenance-pass`, `project-reading`, `tech-preferences`, …) when the task benefits from that playbook, independent of which expert is active.

**Routing overview**

- `work-mode-routing` — when the split is unclear: pick experts and parallelization; pair with domain skills as needed.
- `project-kickoff` — greenfield shaping (often with `researcher` / `analyst` / `coder`).
- `maintenance-pass` — continuing existing work (`analyst` / `tester` / `coder`).
- `project-reading` — study another codebase (`researcher` / `analyst` / `writer`).
- `tech-preferences` — cross-cutting stack/tooling defaults before real choices.
- Specialized: `agent-cli-toolkit` (CLI 探索), `unix-software-design` (设计原则).

**数量说明**：7 个 skill，职责互不重叠。skills 按 description 匹配按需加载，不会全部同时加载；合并会模糊边界、增加单 skill 体积，不建议减少。

## Evals（skill-creator 格式）

每个 skill 在 `skills/<skill-name>/evals/evals.json` 下有评测用例。7 个 skill 均有 evals，效果对比与改进建议见 `evals/EVAL_REPORT.md`。

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

## 常用 Skills

```bash
# 添加全局可用的 skill
bunx skills add anthropics/skills -g --skill skill-creator

# 添加工作模式路由（按场景选专家、并行策略）
bunx skills add ./skills -g --skill work-mode-routing

# 添加现代 CLI 工具使用指南
bunx skills add ./skills -g --skill agent-cli-toolkit

# 添加开新坑方法
bunx skills add ./skills -g --skill project-kickoff

# 添加维护老项目方法
bunx skills add ./skills -g --skill maintenance-pass

# 添加读项目学习方法
bunx skills add ./skills -g --skill project-reading
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
