## 提交流程

- 小步提交，确保每个提交聚焦单一主题
- 优先保持 skill 职责单一；不要把 role 路由逻辑塞进 skill

## Commit message 规范

格式：`<emoji> <type>(<scope>): <subject>`，与 [Conventional Commits](https://www.conventionalcommits.org/) 兼容。  
围绕 **skill 的新增/修改/修复/文档** 写 subject；与 skill 无关的改动用 `docs` / `chore`，可不写 scope。**emoji 必须写**，放在 type 前。

**type（够用即可）**：

| type   | emoji | 含义           | scope 说明        |
|--------|-------|----------------|-------------------|
| `feat` | ✨    | 新增/增强 skill | 必填，skill 名     |
| `fix`  | 🐛    | 修复 skill 问题 | 必填，skill 名     |
| `docs` | 📝    | 文档/示例/README 等 | 可选              |
| `chore`| 🔧    | 构建/依赖/杂项  | 可选              |

- **scope**：与具体 skill 相关时写 `(skill-name)`，如 `feat(paddle-trace)`；全局文档、配置等可不写。

示例：

- `✨ feat(paddle-trace): initial version`
- `✨ feat(paddle-pull-request): support multi template`
- `🐛 fix(paddle-debug): handle empty log path`
- `📝 docs: update contributing.md`
- `🔧 chore: upgrade actions dependencies`

## PR 标题规范

- 与提交规范保持一致（同一套 type/scope），描述可更宏观
- 使用简洁的动宾短语

示例：

- `✨ feat(modern-tech): add modern-stack skill for tech-stack`
- `✨ feat(paddle-pull-request): support multi template`
