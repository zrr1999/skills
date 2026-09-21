# Zhan Rongrui 的个人代理技能合集

面向个人项目的代理技能合集，用于在 Cursor、Copilot 等工具中复用工作流程。

## 技能分层（共 10 个）

`skills/<name>/` 保持平铺，兼容现有 skill manager 的发现与安装；下面的分层用于选 skill，不改变目录或安装 ID。

### 通用入口

先决定任务是否需要一个总入口。只有项目级推进或委派编排需要这一层。

| 技能 | 主要结果 | 不负责 |
| --- | --- | --- |
| `pilot` | 基于项目现场澄清目标、做软件设计取舍、组织有边界的委派 brief 并推进下一步 | 单一技术选型、单点实现、领域工具细节 |

### 横切工程能力

这些 skill 可附着在许多项目上，但各自只拥有一种结果。

| 技能 | 主要结果 | 典型边界 |
| --- | --- | --- |
| `tech-preferences` | 技术栈/工具取舍与 Python 工具链落地 | 项目级模块、接口和状态边界仍由 `pilot` 统筹 |
| `vet` | diff 级 AI slop 清理，或全仓质量审计与公开发布就绪预检 | 不替代正确性调试或纯安全渗透测试 |
| `git-workstreams` | checkout/worktree、依赖 PR 拓扑与持续交付权限边界 | 规范化仓库或创建 PR 时可默认使用 owning worktree；其他场景显式 opt-in |

### 领域专用能力

任务目标已经明确落在某个领域时，可直接使用对应 skill，不必先经过 `pilot`。

| 技能 | 主要结果 |
| --- | --- |
| `get-api-docs` | 从当前第三方 SDK/API 文档取得可靠用法；OpenAI 文档走官方专用来源 |
| `zellij` | 组织、恢复、观察或分享持久终端工作区 |
| `ssh-fleet` | 管理私有 SSH 设备事实源、host key 信任和生成配置 |
| `skill-creator` | 创建、修改和验证可跨 Agent 宿主使用的 skill |
| `writing-style` | 起草、改写和审阅六个骨头的技术博客；其他文体仅在明确要求个人文风时应用 |
| `typed-structures` | 编写或审阅 Spore Notation 的宇宙、范畴、计算结构与 Self；结合具体数据结构和 law，并用 Ohm 识别句法 |

### 选择规则

1. 请求横跨目标、现场证据、设计和下一步，或主要结果是组织子代理 brief 与依赖时，以 `pilot` 为主；遇到明确专项再加载更窄的 skill。
2. 主要交付只是技术选择、审计、Git workstream 或领域产物时，直接使用对应 skill。
3. `pilot` 负责明确委派 brief 与依赖；实际调度由宿主编排层完成，不加载单独的 role skill。
4. 混合请求分三层所有权：`pilot` 管项目结论与顺序，领域 skill 管产物与领域权限，`git-workstreams` 管 Git 拓扑与交付；每层只有一个所有者，权限互不推导。
5. `gh stack` 请求统一由 `git-workstreams` 拥有结果并直接读取本机 help；外部 `gh-stack` skill 的静态命令、安装、配置、重试和权限规则不作为依赖或权威。
6. Git 交付以用户显式终点为先；未指定时，规范化仓库默认 Draft PR，非规范化仓库默认仅本地。审查、设计和咨询不触发实现或 Git 交付。

原 `unix-software-design` 已简化并内置进 `pilot`，原 `git-worktrees` 已更名为 `git-workstreams`，原 `roles` 已退役，原 `quality-audit` 已合入 `vet`（新增 diff 级轨道），原 `spark` 已更名为 `pilot`（避免与 Spark 产品仓库混淆）。

> `svg-design` 已从本仓库移除；安装脚本不会自动卸载已有副本，升级时请检查并移除来自本仓库的旧安装。通用 SVG 能力的外部替代需按任务单独选择，不随本次移除自动安装。

> 升级提示：安装流程不会自动删除用户级旧 skill。重新安装后若本机仍残留 `git-worktrees`、`roles`、`quality-audit` 或 `spark`，请先用当前 skill manager 检查来源，再移除旧条目，避免过期 description 继续触发。

> `gh stack` CLI 与同名 skill 是两件事。保留 CLI 即可；若已安装外部 `gh-stack` skill，建议用当前 skill manager 检查并移除该 skill，避免它与 `git-workstreams` 重复触发。仓库不会自动删除用户级 skill。

## 安装

### 一键安装

安装脚本按需准备 [Vite+](https://viteplus.dev/guide/vpx)、`gh-llm` 扩展和 `chub`，统一通过 `vpx skills add` 安装并登记来源。已有工具不会例行升级；日常更新 skills 使用下方的更新命令。

```bash
curl -fsSL https://raw.githubusercontent.com/zrr1999/skills/main/install.sh | bash
```

默认集合包括本仓库 10 个 skills，以及以下外仓能力：

| 来源 | 默认安装 |
| --- | --- |
| `vercel-labs/skills` | `find-skills` |
| `emilkowalski/skills` | `write-swift` |
| `pbakaus/impeccable` | `impeccable` |
| `cloudflare/skills` | `cloudflare`、`wrangler` |
| `shigurelab/gh-llm` | `github-conversation` |
| `spore-lang/spore` | `spore-language` |

其他能力按用途选择；每次安装都会包含默认集合：

| 参数 | 额外安装 |
| --- | --- |
| `web` | `animate`、`apple-design`、`review-animations`、`prototype`、`pick-ui-library`、`ask-sonner`、`animation-vocabulary`、`find-animation-opportunities`、`improve-animations`（`emilkowalski/skills`） |
| `expo` | `animate-expo`（`emilkowalski/skills`） |
| `cloudflare` | `workers-best-practices`、`durable-objects`（`cloudflare/skills`） |
| `mail` | `agently-mail`（`agent.qq.com` 的 well-known skill） |
| `video` | `procedural-fish-render`、`ruler-progress-render`（`vibe-motion/skills`） |
| `all` | 上述全部可选组 |

```bash
bash install.sh web cloudflare
```

脚本不再安装 Anthropic 同名 `skill-creator`、失效的 `svg-assembly-animator`、重复的 `gh-stack` 和 `emil-design-eng`。`skill-creator` 只使用本仓库通用版；宿主 `.system` 和插件提供的 skills 仍由宿主管理。

`hatch-pet` 是本地 Codex 专用 skill，尚无登记的远端来源，保留其本地副本与备份，不纳入通用安装或自动更新。补充可信远端来源后再通过管理器登记，不从未知来源安装同名替代品。

### 本地管理

已有安装统一使用 `vpx skills` 管理。更新会修改已登记来源的 skills，不会自动补装脚本新增的条目：

```bash
vpx skills list -g
vpx skills update -g
```

手工复制的 skill 需要先用 `add` 登记来源；不直接编辑管理器的 lock 文件。仅安装或重新登记本仓库时：

```bash
vpx skills add zrr1999/skills -g -y --agent cline --skill '*'
```

`--agent cline` 默认只写入共享的 `~/.agents/skills`，可用 `SKILLS_AGENT` 覆盖。不要使用管理器的 `--all`，它会向所有 agent 目录分发；本脚本的 `all` 参数仅选择可选组。管理器更新可能保留或恢复已检测到的 agent 链接，不保证只改一个目录。

清理旧 skill 前确认来源并备份，再使用 `vpx skills remove <name> -g`；不删除同名 CLI。安装脚本不会自动卸载已有 skills。具体参数以当前 `vpx skills --help` 为准。

## 本地开发

评测用例位于 `skills/<skill-name>/evals/evals.json` 或 `evals/<skill-name>/evals.json`，两者不能同时存在。结构与完整性由 `check-evals` prek hook 校验。

```bash
bash scripts/check-evals.sh
bash scripts/test-install.sh
prek run --all-files
```

本地试用可用 `vpx skills add ./skills -g --agent cline --skill pilot`，本地路径安装不支持远端自动更新。要跟踪尚未合并的远端分支，可用 `REPO_SOURCE='zrr1999/skills#branch-name' bash install.sh`；更新会保留该 ref。分支合并后重新从默认来源安装，恢复跟踪 main。
