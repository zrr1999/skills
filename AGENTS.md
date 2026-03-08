## 提交流程

- 小步提交，确保每个提交聚焦单一主题

## Commit message 规范

围绕 **skill 的新增/修改/修复/文档** 来写 message，格式统一为：

`<type>: <subject>`

推荐 `type`（够用即可，不必分得太细）：

- `✨ add(<skill-name>)` 新增 skill
- `⬆️ update(<skill-name>)` 修改/增强已有 skill
- `🐛 fix(<skill-name>)` 修复 skill 问题
- `📝 docs` 文档或示例调整
- `🔧 chore` 杂项

示例：

- `✨ add(paddle-trace): initial version`
- `⬆️ update(paddle-pull-request): support multi template`
- `🐛 fix(paddle-debug): handle empty log path`
- `📝 docs: update contributing.md`
- `🔧 chore: upgrade actions dependencies`

## PR 标题规范

- 与提交规范保持一致，但描述要更宏观
- 使用简洁的动宾短语

示例：

- `✨ add(modern-tech): add modern-stack skill for my tech-stack`
- `⬆️ update(paddle-pull-request): support multi template`

## Cursor Cloud specific instructions

This is a **content-only** repository of AI Agent Skills (Markdown files under `skills/`). There is no application code, build system, or test suite.

### Key tool

- The `skills` CLI (via `bunx skills`) is the only runtime tooling. It installs skill files into `~/.agents/skills/` for use by AI coding agents.
- Bun must be installed (`~/.bun/bin/bun`). The update script handles this automatically.

### Development workflow

- Skills are authored as `skills/<skill-name>/SKILL.md` files with YAML front-matter (`name`, `description`) followed by Markdown content.
- To test a skill locally: `bunx skills add ./skills -g -y --skill <skill-name>`
- To install all skills from the local directory: `bunx skills add ./skills -g -y --skill "*"`
- Always use `-y` flag to avoid interactive prompts in non-TTY environments.

### No lint/test/build

There are no lint, test, or build commands. Validation is limited to verifying that the `skills` CLI can parse and install the Markdown skill files.
