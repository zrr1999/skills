# Zhan Rongrui's Agent Skills

An Agent Skills collection for my own projects, to provide reusable workflows in tools like Cursor, Copilot, etc.

These skills are designed to pair with the sibling `roles` repo:

- roles choose the work mode and delegation path
- skills provide the reusable working method

Current work modes:

- `work-mode-routing` -> routes to directors when mode is unclear
- `directors/new-project` -> `project-kickoff`
- `directors/maintain-project` -> `maintenance-pass`
- `directors/learn-project` -> `project-reading`
- cross-cutting choices -> `tech-preferences`
- specialized: `agent-cli-toolkit` (CLI 探索), `unix-software-design` (设计原则)

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

# 添加工作模式路由（开坑/维护/学习）
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
