# Zhan Rongrui's Agent Skills

An Agent Skills collection for my own projects, to provide reusable workflows in tools like Cursor, Copilot, etc.

These skills are designed to pair with the sibling `roles` repo:

- roles choose the work mode and delegation path
- skills provide the reusable working method

Current work modes:

- `directors/new-project` -> `project-kickoff`
- `directors/maintain-project` -> `maintenance-pass`
- `directors/learn-project` -> `project-reading`
- cross-cutting choices -> `tech-preferences`

## Installation

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
