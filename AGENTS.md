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
- 需要从默认分支发布本地改动、为独立工作流选择 worktree、为依赖改动组织 branch/PR stack、使用 `gh stack`，或持续跟进 PR 冲突与 CI 时加载 `git-workstreams`。它直接读取本机 `gh stack --help`，不依赖或主动组合外部 `gh-stack` skill；后者若被用户明确加载，也不得拥有命令、权限、preflight、fallback、retry 或停止条件。先只读判断仓库是否规范化：默认分支禁推或必须走 PR 的规则、已发布 package/release，或由非占位版本号与 tag/发布配置/changelog/版本流水线共同证明的发布生命周期都属于证据。规范化仓库默认创建或复用 owning worktree，不再单独询问，也不把主工作区的当前 checkout 作为写入默认；创建 PR 的请求同样默认允许 worktree。仅在两者都不成立时，worktree 才要求用户明确选择，未选择则使用当前 checkout。任何默认 worktree 选择都不授权隐式切换主工作区分支、force-push、retarget、merge 或清理；用户明确选择当前 checkout 时，发布后应在安全条件满足时回到起始分支。所有 PR 创建都必须先发现并使用仓库 PR 模板，保留其章节和 checklist，按当前 diff 与验证证据填写；没有模板时不得用自由文本绕过，除非当前任务本身就是建立或恢复模板。PR follow-up 请求授权范围内修复、小步 commit 并及时 push 到确认过的 head branch。

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

- `pilot` 现为统一项目工作流与软件设计入口：内建需求澄清、简化的软件设计判断、按依赖组织的 brief 编排、CLI-first 工作法，并显式说明何时调用 `tech-preferences`、`get-api-docs`；非平凡经验沉淀迁移到 pi-spark 的 `spark-learnings` 工具链。
- `tech-preferences` 同时承载选型基线与 Python 工具链落地（原独立 `modern-python` 已合入）。
- `git-workstreams` 由 `git-worktrees` 更名并扩展而来：规范化仓库与创建 PR 的请求默认允许按需启用 worktree，其他情况才是显式 opt-in；启用后独立任务使用独立 worktree，同一依赖 review stack 在一个 owning worktree 内形成线性 branch chain。它拥有 workstream 拓扑、授权、PR 模板、fallback 和停止条件，并直接从本机 help 驱动可选 `gh stack` CLI；外部同名 skill 不再是 workflow 依赖。创建/发布阶段若 GitHub 明确不支持、仓库不在 GitHub 或用户明确退出，可回退普通 chained PR；official stack landing 不回退逐 PR merge。PR 创建必须使用仓库模板；PR follow-up 负责冲突、范围内 CI、及时 commit/push 和重新检查。
- 各 skill 的评测用例在 `skills/<skill-name>/evals/evals.json`。
- `zellij` 以能力与边界为主：精确命令从当前安装版本的 `zellij --help` 和子命令 help 获取，不维护易过期的 flags 清单。
