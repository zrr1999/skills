## 提交流程

- 小步提交，确保每个提交聚焦单一主题
- 优先保持 skill 职责单一；不要把 role 路由逻辑塞进 skill
- `skills/<name>/` 保持平铺以兼容发现和安装；在 README 中按「通用入口 / 横切工程能力 / 领域专用能力」说明职责，不用目录层级或非标准 YAML 字段表达分类
- Skill instruction 以结果、成功标准、权限边界、工具路由和停止条件为主；删除重复规则、静态命令百科和不改变行为的示例
- YAML `description` 说明主要结果、具体触发场景和最容易混淆的边界；混合请求允许组合 skill，但只指定一个结果所有者
- 对版本演进快的 CLI，说明它能完成什么，并要求从本机 `--help` 发现精确语法；只固化真正稳定的概念和安全边界

## Skill 路由与委派边界

- 需要统一「如何推进一个项目级任务、何时澄清、何时并行、何时调用其他 skill」，或需要把已明确的工作组织成可执行子代理 brief 时，加载 skill `pilot`；它是统一入口，不再先分 new-project / maintain-project / learn-project 三种模式。
- 委派子代理时，由编排层或宿主运行时根据目标、输入、范围、预期产物、验证和依赖关系组织工作，不在 skill 中固化角色体系。
- `unix-software-design` 已退役；通用的软件设计判断由 `pilot` 内建并继任，不重新添加独立 skill。pilot 负责结合项目现场判断模块、接口、数据、状态、失败恢复和复杂度边界；单一技术或工具取舍仍交给 `tech-preferences`。
- 需要横切技术选型、偏好基线或 Python 工程化落地（uv、ruff、ty、CI 等）时加载 `tech-preferences`；需要持久终端工作区、会话恢复、pane/tab/layout 或 Zellij 远程观察时加载 `zellij`。
- 混合请求中，结果所有权与副作用授权分开判断：专项 skill 可以收窄允许的动作，但加载另一个 skill 不能扩大授权；若多个 skill 的权限边界不同，采用更严格且更贴近当前领域的边界。`git-workstreams` 负责兑现已经允许的 Git/PR 交付，不用其默认交付规则覆盖 `ssh-fleet` 等专项 skill 明确要求的更严格授权。
- Git workstream 的详细拓扑、模板、验证与停止条件统一见 `skills/git-workstreams/SKILL.md`，不要在其他 skill 中复制。

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

- 始终用英文，与提交规范保持一致（同一套 type/scope），描述可更宏观
- 使用简洁的动宾短语

示例：

- `✨ feat(modern-tech): add modern-stack skill for tech-stack`
- `✨ feat(paddle-pull-request): support multi template`

## 验证

- 运行 `bash scripts/check-evals.sh`、适用的 `prek` 检查和 `git diff --check`。
- 各 skill 的评测用例位于 `skills/<skill-name>/evals/evals.json`；结构校验通过不等于模型行为评测通过。
- 用户当前指令优先于 skill 指南；沿用已明确的授权。若缺失决策影响行为或权限，只暂停依赖该决策的动作，并说明具体来源。
