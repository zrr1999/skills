# Zhan Rongrui's Agent Skills

An Agent Skills collection for my own projects, to provide reusable workflows in tools like Cursor, Copilot, etc.

## Installation

Prerequisite: install `bun` first.

### One-click install

Run the installer directly:

```bash
curl -fsSL https://raw.githubusercontent.com/zrr1999/skills/main/install.sh | bash
```

The script checks `bun` and installs all skills from this repo.

```bash
bunx skills add zrr1999/skills -g --skill "*" -y
```

### Manual install

If you do not want to use the script, run the equivalent command directly:

```bash
bunx skills add zrr1999/skills -g --skill "*" -y
```

## 常用 Skills

```bash
# 添加全局可用的 skill
bunx skills add anthropics/skills -g --skill skill-creator
```

## 本地开发

```bash
# 在本地 clone 中执行安装脚本，脚本会自动使用仓库内的 ./skills
bash install.sh

# 或直接从本地目录添加 skill（用于调试）
bunx skills add ./skills -g --skill unix-software-design
```
