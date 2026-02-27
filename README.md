# Zhan Rongrui's Agent Skills

An Agent Skills collection for my own projects, to provide reusable workflows in tools like Cursor, Copilot, etc.

## Installation

After you have the `skills` CLI installed locally or globally, you can install all skills from this repo:

```bash
bunx skills add zrr1999/skills --skill "*"
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
