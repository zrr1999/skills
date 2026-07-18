# Zhan Rongrui 的个人代理技能合集

面向个人项目的代理技能合集，用于在 Cursor、Copilot 等工具中复用工作流程。

## 本仓库内的技能（共 8 个）

| 技能                   | 说明                                                                                                     |
| ---------------------- | -------------------------------------------------------------------------------------------------------- |
| `roles`                | 代理优先职责契约：`inspector` / `executor` / `verifier` 的 brief 分工与提示词；专项审查用 `lens`          |
| `tech-preferences`     | 技术栈与工具偏好 / 取舍；含 Python 工程化落地（uv、ruff、ty、pyproject、prek/CI）                        |
| `unix-software-design` | 模块边界、接口、简洁性                                                                                   |
| `get-api-docs`         | 第三方库 / API 文档                                                                                      |
| `spark`                | 默认项目级入口：澄清意图、检查现场、产出统一 packet、拆分任务、并在需要时创建/更新 SPARK.md              |
| `quality-audit`        | 统一质量检查与优化：技术债/架构健康/可维护性审计，以及公开发布前的 Scorecard、安全、许可证与仓库卫生预检 |
| `svg-design`           | 手写 SVG 图标/Logo：viewBox/描边约定、渐变/蒙版、优化、动效、无障碍；Logo 预览工作流                     |
| `zellij`               | 持久终端工作区：session 恢复、pane/tab/layout 组织、自动化取证、只读观察与安全远程访问                   |

### `roles` 职责一览

- **`inspector`** —— 有限的取证、阅读、结构、权衡、范围划定
- **`executor`** —— 聚焦实现，产出可合并的差异与校验契约
- **`verifier`** —— 针对明确主张做复现、回归与审查；可在 brief 上设置 **`lens`**（`security`、`performance`、`architecture`）

**典型搭配（示例）**

- **从零开发** —— 可行性可拆时并行多份 `inspector` 任务简报；再 `executor`；最后用 `verifier` 验证主张。
- **维护** —— 结构审查与复现彼此独立时，`inspector` 与 `verifier` 并行；再 `executor`；最后 `verifier` 做回归。
- **研读其他仓库** —— 按子系统或问题并行多份 `inspector` 任务简报；在一轮里综合或在编排层合并。
- **专项审查** —— 按需使用带 `lens: security` / `performance` / `architecture` 的 `verifier`。

**数量说明**：本仓库当前 **8** 个技能。角色契约在 `roles`；选型与 Python 工具链落地在 `tech-preferences`；统一项目工作流在 `spark`；质量检查与优化在 `quality-audit`；Zellij 持久工作区由 `zellij` 负责。原独立仓库 `zrr1999/roles` 与原 skill `modern-python` 已归档/合入。

## 评测用例格式

每个技能在 `skills/<skill-name>/evals/evals.json` 下有评测用例。本地快速校验 JSON 语法：`for f in skills/*/evals/evals.json; do jq empty "$f"; done`。结构校验：`bash scripts/check-evals.sh`。

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

## 常用技能（本仓库内）

```bash
# 添加全局可用的技能（只装到 ~/.agents/skills；推荐项目级入口使用 spark；委派子代理时加载 roles）
pnpx skills add zrr1999/skills -g --agent cline --skill spark \
  --skill roles \
  --skill tech-preferences \
  --skill unix-software-design \
  --skill get-api-docs \
  --skill quality-audit \
  --skill svg-design \
  --skill zellij

# 或按需单独添加示例
pnpx skills add zrr1999/skills -g --agent cline --skill spark
pnpx skills add zrr1999/skills -g --agent cline --skill roles
pnpx skills add zrr1999/skills -g --agent cline --skill tech-preferences
pnpx skills add zrr1999/skills -g --agent cline --skill unix-software-design
pnpx skills add zrr1999/skills -g --agent cline --skill get-api-docs
pnpx skills add zrr1999/skills -g --agent cline --skill quality-audit
pnpx skills add zrr1999/skills -g --agent cline --skill svg-design
pnpx skills add zrr1999/skills -g --agent cline --skill zellij
```

## 本地开发

```bash
# 默认安装远程已发布版本（含 Vite+ / pnpm / chub / skills）
bash install.sh

# 调试本地未发布改动时，覆盖技能来源
REPO_SOURCE=./skills bash install.sh

# 调试本地未发布改动时，直接从本地目录添加（同样只写入 ~/.agents/skills）
pnpx skills add ./skills -g --agent cline --skill unix-software-design

# 与 prek.toml 对齐的本地检查（需已执行 prek install）
prek run check-json check-yaml check-executables-have-shebangs --all-files
# 校验每个 skill eval 的结构
bash scripts/check-evals.sh
# 或运行全部已配置的钩子：
prek run --all-files
```
