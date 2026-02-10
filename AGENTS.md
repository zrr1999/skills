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
