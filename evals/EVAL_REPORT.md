# Eval 效果对比与改进建议

## 一、Expectations 达成情况（当前 skill 集合）

| Skill | 期望 1 | 期望 2 | 期望 3 | 综合 |
|-------|-------|-------|-------|------|
| **project-workflows** | 🟡 覆盖统一 packet、需求澄清与最小下一步 | 🟡 覆盖内建并行与 CLI-first 边界 | 🟡 覆盖与专项 skill 的让位关系 | 见 `skills/project-workflows/evals/evals.json` |
| **tech-preferences** | ✅ 偏好分析流程 | ✅ 具体选型建议 | ✅ 偏好分析在建议前 | 3/3 |
| **unix-software-design** | ✅ 模块边界/接口设计 | ✅ 引用 Unix 原则 | ✅ 未仅工具选型 | 3/3 |
| **modern-python** | ✅ uv 初始化与 pyproject 方向 | ✅ ruff + ty 配置或片段 | ✅ 本地可执行检查命令 | 见 `skills/modern-python/evals/evals.json` |
| **get-api-docs** | 待补 | 待补 | 待补 | 见 `skills/get-api-docs/evals/evals.json` |
| **compound-learnings** | 待补 | 待补 | 待补 | 见 `skills/compound-learnings/evals/evals.json` |

**说明**：`project-workflows` 现为统一入口 skill，吸收了原 `project-kickoff`、`maintenance-pass`、`project-reading`、`work-mode-routing`，以及后续新增的需求澄清、专家编排和 CLI-first 工作法；其 eval 现改为验证统一工作流、专项 skill 边界，以及与 `roles` 当前 brief contract 的衔接（共 7 条）。

---

## 二、改进建议

### 1. Eval 设计层面

| 建议 | 说明 |
|------|------|
| **CLI-first 边界用例** | 既然 CLI 工作法已并入 `project-workflows`，后续可补「仓库搜索 / diff / JSON / GitHub / 性能」这几类触发样例，验证统一 skill 不会遗漏终端证据场景。 |
| **project-workflows 边界用例** | 现已改为统一工作流视角；后续可继续增加「应转给 get-api-docs / compound-learnings」的边界用例。 |
| **roles 契约衔接** | 现已补 `inspector / executor / verifier` + `verifier lens` 的适配用例；后续可再补 security / architecture lens。 |

### 2. Expectations 可校验化

可将 expectations 改为可机器校验的断言（grep/正则），便于 CI。

### 3. Baseline 对比

补跑 without-skill，对比输出结构是否更符合 packet 契约。

---

## 三、优先级排序

1. **高**：跑统一版 `project-workflows` baseline 对比，量化合并后的增益或退化
2. **中**：为 `get-api-docs` 与 `compound-learnings` 补齐 eval 和 expectations
3. **低**：expectations 机器可校验化

---

## 四、历史备注

- 曾独立存在的 `project-kickoff`、`maintenance-pass`、`project-reading`、`work-mode-routing` 已合并为 **`project-workflows`**（见 `skills/project-workflows/SKILL.md`）。
