# Eval 效果对比与改进建议

## 一、Expectations 达成情况（当前 skill 集合）

| Skill | 期望 1 | 期望 2 | 期望 3 | 综合 |
|-------|-------|-------|-------|------|
| **project-workflows** | ✅ 覆盖 kickoff / continuation / learning / 混合路由 | ✅ 各 eval 对应 packet 契约 | ✅ 反模式（全量重写等）受控 | 见 `skills/project-workflows/evals/evals.json` |
| **tech-preferences** | ✅ 偏好分析流程 | ✅ 具体选型建议 | ✅ 偏好分析在建议前 | 3/3 |
| **agent-cli-toolkit** | ✅ rg/fd 搜索 | ✅ delta/difft | ✅ jq + http/curl | 3/3 |
| **unix-software-design** | ✅ 模块边界/接口设计 | ✅ 引用 Unix 原则 | ✅ 未仅工具选型 | 3/3 |

**说明**：`project-workflows` 由原 `project-kickoff`、`maintenance-pass`、`project-reading`、`work-mode-routing` 合并；eval 用例已迁入 `project-workflows/evals/evals.json`（共 6 条）。

---

## 二、改进建议

### 1. Eval 设计层面

| 建议 | 说明 |
|------|------|
| **agent-cli-toolkit 换有 API 的上下文** | 本仓库以文档为主，无业务 API 调用。可：① 在 evals 下加 `fixtures/` 放示例代码；② 或指定一个含 API 的 repo 作为 eval 上下文。 |
| **project-workflows 边界用例** | 已含混合模式、具体方向 kickoff、抗拒全量重写等；可按需增加「纯 tech-preferences」边界，验证不与选型 skill 抢职责。 |

### 2. Expectations 可校验化

可将 expectations 改为可机器校验的断言（grep/正则），便于 CI。

### 3. Baseline 对比

补跑 without-skill，对比输出结构是否更符合 packet 契约。

---

## 三、优先级排序

1. **高**：跑 baseline 对比，量化 skill 增益
2. **中**：agent-cli-toolkit 增加 fixtures 或指定含 API 的 eval 上下文
3. **低**：expectations 机器可校验化

---

## 四、历史备注

- 曾独立存在的 `project-kickoff`、`maintenance-pass`、`project-reading`、`work-mode-routing` 已合并为 **`project-workflows`**（见 `skills/project-workflows/SKILL.md`）。
