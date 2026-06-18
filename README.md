# Zhan Rongrui 的个人代理技能合集

面向个人项目的代理技能合集，用于在 Cursor、Copilot 等工具中复用工作流程。

## 关联：`roles` 仓库

兄弟仓库 [`zrr1999/roles`](https://github.com/zrr1999/roles) 仅定义 **代理优先** 的子代理角色：

- **`inspector`** —— 有限的取证、阅读、结构、权衡、范围划定
- **`executor`** —— 聚焦实现，产出可合并的差异与校验契约
- **`verifier`** —— 针对明确主张做复现、回归与审查；可在任务简报上设置可选审视角度 **`lens`**（`security`、`performance`、`architecture`）以加深专项审查

**本仓库内的技能（共 7 个）**

| 技能                   | 说明                                                                                                     |
| ---------------------- | -------------------------------------------------------------------------------------------------------- |
| `tech-preferences`     | 技术栈与工具偏好 / 取舍                                                                                  |
| `unix-software-design` | 模块边界、接口、简洁性                                                                                   |
| `modern-python`        | uv、ruff、ty、Python 工程卫生                                                                            |
| `get-api-docs`         | 第三方库 / API 文档                                                                                      |
| `spark`                | 默认项目级入口：澄清意图、检查现场、产出统一 packet、拆分任务、并在需要时创建/更新 SPARK.md              |
| `quality-audit`        | 统一质量检查与优化：技术债/架构健康/可维护性审计，以及公开发布前的 Scorecard、安全、许可证与仓库卫生预检 |
| `svg-design`           | 手写 SVG 图标/Logo：viewBox/描边约定、渐变/蒙版、优化、动效、无障碍；Logo 预览工作流                     |

**与 `roles` 的典型搭配（示例）**

- **从零开发** —— 可行性可拆时并行多份 `inspector` 任务简报；再 `executor`；最后用 `verifier` 验证主张。
- **维护** —— 结构审查与复现彼此独立时，`inspector` 与 `verifier` 并行；再 `executor`；最后 `verifier` 做回归。
- **研读其他仓库** —— 按子系统或问题并行多份 `inspector` 任务简报；在一轮里综合或在编排层合并；没有单独的「写稿」角色——除非显式拆分任务简报，否则包装结果由编排输出。
- **专项审查** —— 按需使用带 `lens: security` / `performance` / `architecture` 的 `verifier`。

**数量说明**：本仓库当前 **7** 个技能。统一项目工作流已收敛到 `spark`；质量检查与优化已收敛到 `quality-audit`；不单独提供额外的 workflow/router/toolkit 类技能，如 `requirements-shaping`、`expert-orchestration` 或 `agent-cli-toolkit`。

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

装齐本仓库全部技能（需已有 Node/pnpm 与 `skills` 命令行工具）：

```bash
pnpx skills add zrr1999/skills --all -g -y
```

### 手动安装

不用安装脚本时，可直接用包运行器（与脚本一致推荐 **pnpm** / `pnpx`；若使用 Bun，可用 `bunx` 代替）：

```bash
pnpx skills add zrr1999/skills --all -g -y
```

## 常用技能（本仓库内）

```bash
# 添加全局可用的技能（推荐项目级入口使用 spark）
pnpx skills add zrr1999/skills -g --skill spark \
  --skill tech-preferences \
  --skill unix-software-design \
  --skill modern-python \
  --skill get-api-docs \
  --skill quality-audit

# 或按需单独添加示例
pnpx skills add zrr1999/skills -g --skill spark
pnpx skills add zrr1999/skills -g --skill tech-preferences
pnpx skills add zrr1999/skills -g --skill unix-software-design
pnpx skills add zrr1999/skills -g --skill modern-python
pnpx skills add zrr1999/skills -g --skill get-api-docs
pnpx skills add zrr1999/skills -g --skill quality-audit
pnpx skills add zrr1999/skills -g --skill svg-design
```

## 本地开发

```bash
# 默认安装远程已发布版本（含 Vite+ / pnpm / chub / skills）
bash install.sh

# 调试本地未发布改动时，覆盖技能来源
REPO_SOURCE=./skills bash install.sh

# 调试本地未发布改动时，直接从本地目录添加
pnpx skills add ./skills -g --skill unix-software-design

# 与 prek.toml 对齐的本地检查（需已执行 prek install）
prek run check-json check-yaml check-executables-have-shebangs --all-files
# 校验每个 skill eval 的结构
bash scripts/check-evals.sh
# 或运行全部已配置的钩子：
prek run --all-files
```
