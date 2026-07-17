## 提交流程

- 小步提交，确保每个提交聚焦单一主题
- 优先保持 skill 职责单一；不要把 role 路由逻辑塞进 skill
- Skill instruction 以结果、成功标准、权限边界、工具路由和停止条件为主；删除重复规则、静态命令百科和不改变行为的示例
- 对版本演进快的 CLI，说明它能完成什么，并要求从本机 `--help` 发现精确语法；只固化真正稳定的概念和安全边界

## 与 `roles` skill 的配合

- skill `roles` 提供 **agent-first** 职责型角色：`inspector`（证据与阅读、现状与范围）、`executor`（有边界的实现与改动契约）、`verifier`（复现、回归、审查；专项审查在 brief 上使用 `lens: security | performance | architecture`）。不再通过 `new-project` / `maintain-project` / `learn-project` 等中间层路由；原独立仓库 `zrr1999/roles` 已归档。
- 需要统一「如何推进一个项目级任务、何时澄清、何时并行、何时调用其他 skill」时，加载 skill `spark`；它是统一入口，不再先分 new-project / maintain-project / learn-project 三种模式。委派子代理时加载 `roles`。
- 需要横切技术选型或偏好基线时加载 `tech-preferences`；需要 Python 工程化落地（uv、ruff、ty、CI 等）时加载 `modern-python`；需要持久终端工作区、会话恢复、pane/tab/layout 或 Zellij 远程观察时加载 `zellij`；与当前激活的 **role** 正交。

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

## Learned User Preferences

- 编写或维护 skill 的 YAML `description` 时，用具体场景词与边界说明，减少漏触发和误触发。

## Learned Workspace Facts

- `spark` 现为统一项目工作流入口：内建需求澄清、与 `roles` skill 一致的 brief 编排（职责并行）、CLI-first 工作法，并显式说明何时调用 `tech-preferences`、`modern-python`、`unix-software-design`、`get-api-docs`；非平凡经验沉淀迁移到 pi-spark 的 `spark-learnings` 工具链。
- `roles` 承载 inspector / executor / verifier 的提示词与分工契约；不把 role-forge / roles.toml 等独立仓结构迁入本仓库。
- 各 skill 的评测用例在 `skills/<skill-name>/evals/evals.json`。
- `zellij` 以能力与边界为主：精确命令从当前安装版本的 `zellij --help` 和子命令 help 获取，不维护易过期的 flags 清单。
