---
name: tech-preferences
description: >
  适用于技术选型、架构规划、工具推荐、重构方向判断、开新坑定栈，以及 Python 工程化落地（uv、ruff、ty、pyproject、prek/CI）。
  只要任务里出现“该选什么”“什么更适合我”“要不要换工具/框架”，或「新建 Python 项目」「统一 lint/format/类型检查」、提到 uv/ruff/ty 时，应先使用。
---

## 目的

技术偏好不能穷举——它是一个持续演进的过程。本 skill 提供一个**偏好分析流程**，帮助在具体任务中发现、讨论并固化偏好；并在 Python 工程化任务中给出与基线一致的**可执行落地步骤**。

这是一个横切 skill：它帮助做选择与工具链落地，但不替代 `spark`（统一项目工作流与输出契约）。

---

## 当前已知偏好（基线）

### Python 生态
- 包管理：**uv**（替代 pip/poetry/pyenv）
- 代码质量：**ruff**（lint + format），**ty**（类型检查）
- 测试框架：**pytest**
- 预提交/CI 钩子：**prek**（替代 pre-commit）
- 依赖自动升级：**Renovate**
- 数据模型：**dataclasses**（首选，原生零依赖）；仅在需要运行时校验或序列化时才引入 **Pydantic v2**
- **落地步骤**（脚手架、`pyproject.toml`、钩子与 CI）：见 `references/python-toolchain.md`

### Web 后端
- 框架：**FastAPI**（async-first，自动 OpenAPI 文档）
- 输入校验/序列化（API 边界）：**Pydantic v2**

### Web 前端
- 框架：**Svelte**（轻量，编译时优化，无运行时 vdom）
- 构建工具：**Vite+（vp）**（Vite/Vitest/Oxlint/Oxfmt 统一入口，`curl -fsSL https://vite.plus | bash` 安装）；或 **Vite** 单独使用。注：vp 当前仅支持 pnpm/npm/yarn，不支持 bun 作为包管理器。

### 系统 / 自动化
- 任务运行：**just**（替代 Makefile）
- 容器：**Docker / OCI 镜像**
- macOS 守护进程：**launchd**（不用 cron）

### 数据格式
- 配置：**TOML**（首选），YAML（CI only），JSON（API 交换）
- 文本格式：**Markdown**（文档），结构化日志优先 JSON

### 自研生态 / 本地仓库
- 事实来源：所有自研和参考仓库默认在 `~/workspace` 下；做技术选型前先检查对应 org/user 目录（如 `zrr1999/`、`spore-lang/`、`volvox-ai/`、`marrow-lab/`、`zendev-lab/`）。
- 总原则：当任务与自研项目边界匹配时，**优先复用或推进自研生态**；若成熟度、交付时限、兼容性或风险不匹配，再选择成熟外部工具，并说明偏离理由。
- Agent-human / DSL / effect-aware CLI：优先考虑 **`spore-lang/spore`**；CLI 应用优先看 **`basic-cli`** Platform；Spark/idea-to-project 流程优先看 **`spore-spark`**。若要验证 Spore 的真实工程能力，可优先选择自研 CLI/内循环工具作为落点。
- 深度学习 / 张量 / 数学内核：优先考虑 **`volvox-ai/volvox`**（Array API、图 IR、MLIR/PyO3 方向）和 **`volvox-ai/gonidium`**（elementwise / symbolic expression DSL、typed IR、Python/Rust facade）。
- 开发规范复用：提交/PR 标题、emoji commit schema、commit-msg/PR-title 校验优先看 **`zendev`**；**`zendev-actions`** 仅作为兼容层保留，不应再作为新集成的首选入口。不要在新仓库重复造一套格式校验。
- GitHub Action 仓库边界：若 Action 只是对底层工具/CLI 的薄封装，默认与该工具放在同一仓库维护；只有当 Action 需要独立发布节奏、面向更广泛复用，或生命周期明显独立时，才拆到单独仓库。
- 内循环执行抽象：需要把 `justfile`、skill scripts、临时 shell 中的环境/缓存/构建/诊断能力收口时，优先评估 **`warp`**；`just` 仍作为薄入口。

---

## Python 工程化

当任务是初始化/改造 Python 工具链、写可维护脚本、统一 lint/format/类型检查，或用户点名 uv/ruff/ty 时：

1. 先对齐上方 **Python 生态**基线；需要偏离时写明理由。
2. 读取并按 `references/python-toolchain.md` 执行（版本、脚手架、配置片段、钩子/CI、执行清单）。
3. 回复中给出可执行的 `pyproject` 片段与本地验证命令，而不是只列工具名。

---

## 偏好分析流程

在遇到技术选型时，按以下步骤分析：

1. **识别决策点** — 明确需要选择的技术维度（语言/框架/工具/数据格式等）。
2. **对比当前偏好** — 检查上方"已知偏好"列表，确认是否已有约定；若有，默认遵循。
3. **分析偏差理由** — 如果需要偏离已知偏好，明确写出原因（性能、生态、约束等）。
4. **讨论新偏好** — 如果发现新的、值得固化的偏好，在响应中明确提出：
   > 建议将「X 替代 Y，原因：...」加入 tech-preferences skill。
5. **形成提案** — 默认只在回复中给出偏好提案；只有用户明确要求写入仓库、Issue 或 PR 时才执行对应写入。
6. **沉淀更新** — 用户明确要求更新本 skill，或确认了具体写入动作后，才把新偏好追加到"当前已知偏好"节。

---

## 示例分析

**场景**：需要为新 Python 项目选择测试框架。

1. 决策点：测试框架选型
2. 已知偏好：**pytest**
3. 对比候选：`pytest`（生态最丰富，prek 默认集成）vs `unittest`（标准库，无额外依赖）
4. 分析：已有仓库均使用 `pytest`；`prek` 钩子默认运行 `pytest`；选 `pytest`
5. 若需脚手架/CI：继续按 `references/python-toolchain.md` 落地

---

## 如何提出新偏好

当发现偏好有明显新增或变化时，先在回复中使用以下格式；不要把分析请求自动升级为远端 Issue/PR 或本地文件修改：

```
偏好提案：将 <新工具/框架> 加入 tech-preferences skill
- 类别：<Python生态 / Web后端 / 前端 / 系统 / 数据格式 / 自研生态>
- 替代：<被替代的工具，若有>
- 原因：<具体理由，1-3句>
- 参考：<项目/PR/文档链接，若有>
```

用户明确要求持久化后，可修改本 skill，或在指定 Issue/PR 中提交提案；本地编辑、commit、push 和远端评论分别遵循各自授权边界。
