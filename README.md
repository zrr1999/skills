# Zhan Rongrui 的个人代理技能合集

面向个人项目的代理技能合集，用于在 Cursor、Copilot 等工具中复用工作流程。

## 技能分层（共 9 个）

`skills/<name>/` 保持平铺，兼容现有 skill manager 的发现与安装；下面的分层用于选 skill，不改变目录或安装 ID。

### 通用入口

先决定任务是否需要一个总入口。只有项目级推进或实际委派需要这一层。

| 技能 | 主要结果 | 不负责 |
| --- | --- | --- |
| `spark` | 基于项目现场澄清目标、做软件设计取舍、选择最小可验证切片并推进下一步 | 单一技术选型、单点实现、领域工具细节 |
| `roles` | 把已决定委派的工作写成 `inspector` / `executor` / `verifier` brief | 项目路线、技术方法或独立协调者角色 |

### 横切工程能力

这些 skill 可附着在许多项目上，但各自只拥有一种结果。

| 技能 | 主要结果 | 典型边界 |
| --- | --- | --- |
| `tech-preferences` | 技术栈/工具取舍与 Python 工具链落地 | 项目级模块、接口和状态边界仍由 `spark` 统筹 |
| `quality-audit` | 有证据的维护质量或公开发布就绪审计 | 不替代普通 PR review、单点调试或纯安全渗透测试 |
| `git-workstreams` | 安全发布本地改动、worktree、GitHub 原生 stack 与目标 PR 跟进 | 原生 stack 默认启用、明确不支持时回退；worktree 显式 opt-in |

### 领域专用能力

任务目标已经明确落在某个领域时，可直接使用对应 skill，不必先经过 `spark`。

| 技能 | 主要结果 |
| --- | --- |
| `get-api-docs` | 从当前第三方 SDK/API 文档取得可靠用法；OpenAI 文档走官方专用来源 |
| `svg-design` | 创建、编辑、优化并渲染验证 SVG、图标或 Logo |
| `zellij` | 组织、恢复、观察或分享持久终端工作区 |
| `ssh-fleet` | 管理私有 SSH 设备事实源、host key 信任和生成配置 |

### 选择规则

1. 请求横跨目标、现场证据、设计和下一步时，以 `spark` 为主；遇到明确专项再加载更窄的 skill。
2. 主要交付只是技术选择、审计、Git workstream 或领域产物时，直接使用对应 skill。
3. `roles` 只在实际委派或编写 agent brief 时加载；它与当前方法型 skill 正交。
4. 混合请求可以加载多个 skill，但只指定一个结果所有者，避免两个 skill 同时规划整项工作。

原 `unix-software-design` 已简化并内置进 `spark`，原 `git-worktrees` 已更名为 `git-workstreams`。

> 升级提示：重新安装后若本机仍残留旧 `git-worktrees` skill，请先用当前 skill manager 检查来源，再移除旧条目，避免两个 description 同时触发。安装流程不会自动删除用户级旧 skill。

## 安装

### 一键安装

安装脚本会（按需）安装 **Vite+**（[`curl -fsSL https://vite.plus | bash`](https://vite.plus)）以获得托管的 **Node.js**，再安装 **pnpm**，升级或安装 **`gh-llm`** 扩展，全局安装 **`@aisuite/chub`**（供 `get-api-docs` 使用），最后用 **`pnpx skills add`** 安装本仓库全部技能。默认还会安装下列外仓技能集合。

外仓来源（与 `install.sh` 中 `pnpx skills add …` 一致）：

- `anthropics/skills`（`skill-creator`）
- `cloudflare/skills`（`workers-best-practices`、`durable-objects`、`cloudflare`、`wrangler`）
- `shigurelab/gh-llm`（`github-conversation`）
- `vibe-motion/skills`（`svg-assembly-animator`、`procedural-fish-render`、`ruler-progress-render`）
- `spore-lang/spore`（`spore-language`）

非交互场景可设置 `VP_NODE_MANAGER=yes`（安装 Vite+ 时跳过交互提示；`install.sh` 已默认导出）。

```bash
curl -fsSL https://raw.githubusercontent.com/zrr1999/skills/main/install.sh | bash
```

装齐本仓库全部技能（需已有 Node/pnpm 与 `skills` 命令行工具）。**不要用 `--all`**：它会展开成 `--agent '*'`，把 symlink 扇出到各 agent 目录。用 `--skill '*'` + `--agent cline` 只写入 `~/.agents/skills`：

```bash
pnpx skills add zrr1999/skills -g -y --agent cline --skill '*'
```

### 手动安装

不用安装脚本时，可直接用包运行器（与脚本一致推荐 **pnpm** / `pnpx`；若使用 Bun，可用 `bunx` 代替）：

```bash
pnpx skills add zrr1999/skills -g -y --agent cline --skill '*'
```

## 按层安装（本仓库内）

```bash
# 通用入口
pnpx skills add zrr1999/skills -g --agent cline --skill spark \
  --skill roles

# 横切工程能力
pnpx skills add zrr1999/skills -g --agent cline \
  --skill tech-preferences \
  --skill quality-audit \
  --skill git-workstreams

# 领域专用能力，按需选择
pnpx skills add zrr1999/skills -g --agent cline \
  --skill get-api-docs \
  --skill svg-design \
  --skill zellij \
  --skill ssh-fleet

# 全量安装仍可使用：
pnpx skills add zrr1999/skills -g -y --agent cline --skill '*'
```

## 本地开发

每个技能在 `skills/<skill-name>/evals/evals.json` 下有评测用例。本地快速校验 JSON 语法：`for f in skills/*/evals/evals.json; do jq empty "$f"; done`。结构校验：`bash scripts/check-evals.sh`。

```bash
# 默认安装远程已发布版本（含 Vite+ / pnpm / chub / skills）
bash install.sh

# 调试本地未发布改动时，覆盖技能来源
REPO_SOURCE=./skills bash install.sh

# 调试本地未发布改动时，直接从本地目录添加（同样只写入 ~/.agents/skills）
pnpx skills add ./skills -g --agent cline --skill spark

# 与 prek.toml 对齐的本地检查（需已执行 prek install）
prek run check-json check-yaml check-executables-have-shebangs --all-files
# 校验每个 skill eval 的结构
bash scripts/check-evals.sh
# 或运行全部已配置的钩子：
prek run --all-files
```
