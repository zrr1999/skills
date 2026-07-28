---
name: tech-preferences
description: >
  用个人偏好和项目证据完成技术栈、框架、工具、数据格式或仓库边界取舍，并落地 Python 工具链（uv、ruff、ty、pyproject、prek/CI）。当主要结果是“该选什么、为什么适合、何时偏离基线”，或用户要求新建/迁移 Python 工程化配置时使用。不要仅因请求出现“架构”或“重构”就触发：项目下一步、模块/接口/状态边界和多阶段推进由 spark 负责；本 skill 只处理其中真实存在的技术选择。
---

## 目的

用当前偏好基线和实际项目约束做一个明确选择；需要 Python 工程化时，交付可执行配置与验证步骤。完成时应说明推荐项、证据、关键取舍、偏离基线的理由，以及用户要求落地时的验证结果。

这是一个横切 skill：它可以附着在 `spark` 或其他项目工作流上，但不接管整体推进。

## Entry paths

- **Choice**：比较技术栈、框架、工具、数据格式或仓库边界，给出一个有条件的推荐。
- **Python toolchain**：初始化或迁移 uv、ruff、ty、pytest、pyproject、prek/CI；读取 `references/python-toolchain.md`。
- **Preference proposal**：判断一次选择是否值得成为长期个人基线；默认只在回复中提案。

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

## Decision workflow

1. 明确实际决策、硬约束和成功标准；若用户已选定技术且只要求项目设计，不把任务重新解释成选型。
2. 检查上方基线、`~/workspace` 中相关自研仓库和当前项目证据。基线是默认倾向，不是替代现场的绝对规则。
3. 只比较会改变结论的候选；围绕兼容性、成熟度、交付时限、维护成本、迁移与回滚给出一个推荐。
4. 用户要求实现时完成范围内配置并运行相关检查；Python 工具链读取 `references/python-toolchain.md`，不要只列工具名。
5. 发现值得长期固化的新偏好时，在回复中给出一份短提案，包含类别、替代项、理由和证据。只有用户明确要求持久化时才修改 skill、仓库或远端 Issue/PR。

## Output and stop rules

先给推荐，再给支持推荐的项目证据、关键取舍和偏离条件。实现类请求还要报告改动与验证；规划类请求保持在选择层，不扩写成完整项目路线。

已有证据足以做出有条件的选择时停止。若缺失版本、兼容性或项目约束会改变结论，获取最小必要资料；仍无法确认时明确缺口，不用偏好基线伪装成事实。
