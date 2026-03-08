# Zhan Rongrui's Agent Skills

An Agent Skills collection for my own projects, to provide reusable workflows in tools like Cursor, Copilot, etc.

## Installation

### One-click install

Run the installer directly:

```bash
curl -fsSL https://raw.githubusercontent.com/zrr1999/skills/main/install.sh | bash
```

The script installs `bun` automatically when needed, then installs all skills from this repo.

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
```

## 本地开发

```bash
# install.sh 总是安装已发布的 GitHub 仓库版本
bash install.sh

# 调试本地未发布改动时，直接从本地目录添加
bunx skills add ./skills -g --skill unix-software-design
```
