# Zhan Rongrui's Agent Skills

An Agent Skills collection for my own projects, to provide reusable workflows in tools like Cursor, Copilot, etc.

## Installation

Prerequisite: install `bun` first.

### One-click install

Clone this repo locally, then run the installer:

```bash
git clone https://github.com/zrr1999/skills.git
cd skills
bash install.sh
```

The script checks `bun`, resolves the repo-local `skills/` directory automatically, and then runs:

```bash
bunx skills add ./skills -g --skill "*" -y
```

### Manual install

If you do not want to use the script, run the equivalent command directly from this repo:

```bash
bunx skills add ./skills -g --skill "*" -y
```

## 常用 Skills

```bash
# 添加全局可用的 skill
bunx skills add anthropics/skills -g --skill skill-creator
```

## 本地开发

```bash
# 从本地目录添加 skill（用于调试）
bunx skills add ./skills -g --skill unix-software-design
```
