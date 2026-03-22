# Zhan Rongrui's Agent Skills

An Agent Skills collection for my own projects, to provide reusable workflows in tools like Cursor, Copilot, etc.

## Related: `roles` repo

The sibling [`zrr1999/roles`](https://github.com/zrr1999/roles) package defines **expert subagent roles** only (`researcher`, `analyst`, `coder`, `tester`, `writer`). There is **no** director / work-mode role layer there.

- **Skills** (this repo): reusable *methods*—how to kick off a project, run a maintenance pass, read a foreign repo, stack prefs, etc.
- **Roles**: *who* runs a bounded brief; orchestration picks experts and merges results.

Load `project-workflows` when you need a consistent playbook for **新开 / 维护 / 读项目 / 混合模式路由** and when to parallelize; load domain skills (`tech-preferences`, …) when the task benefits from that layer, independent of which expert is active.

**Routing overview**

- `project-workflows` — greenfield shaping, continuing existing work, studying another codebase, or clarifying mixed modes (合并原 `work-mode-routing`、`project-kickoff`、`maintenance-pass`、`project-reading`). Typical pairings with roles: 新开 often `researcher` / `analyst` / `coder`; 维护 `analyst` / `tester` / `coder`; 读项目 `researcher` / `analyst` / `writer`.
- `tech-preferences` — cross-cutting stack/tooling defaults before real choices.
- Specialized: `agent-cli-toolkit` (CLI 探索), `modern-python` (uv / ruff / ty 工程化), `unix-software-design` (设计原则).

**数量说明**：5 个 skill，职责互不重叠。`project-workflows` 合并了原先分开的开坑/维护/学习/路由说明，按需加载时仍按 description 匹配。

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

## 常用 Skills

```bash
# 添加全局可用的 skill
bunx skills add anthropics/skills -g --skill skill-creator

# 开新坑 / 维护老项目 / 读项目学习 / 模式路由（合并为一个 skill）
bunx skills add ./skills -g --skill project-workflows

# 现代 CLI 工具使用指南
bunx skills add ./skills -g --skill agent-cli-toolkit

# Python 现代工具链（uv、ruff、ty）
bunx skills add ./skills -g --skill modern-python
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
