---
name: roles
description: >
  代理优先的职责型子代理契约：按 inspector / executor / verifier 拆 brief、定分工与并行边界，以及 verifier 的 security / performance / architecture lens。适用于“拆给子代理”“写 brief”“inspector 还是 executor”“专项安全/性能/架构审查怎么挂角色”等请求。不替代 spark 的项目推进，也不提供人类岗位式角色或独立协调者角色。
---

# Roles

## Goal

把可委派工作落到明确的职责契约上。完成时应满足：

- 只使用 `inspector` / `executor` / `verifier` 三类角色，不发明岗位名或中间层 director；
- 每个 brief 字段齐全且可执行，范围不漂移；
- 彼此独立的 brief 默认并行；有实质依赖时串行；
- 专项审查通过 `verifier` 的 `lens` 表达，不另开顶层角色。

## Brief contract

每个 brief 只保留会改变执行的字段：

| Field | Content |
|---|---|
| `goal` | 要产出或判定什么 |
| `inputs` | 路径、commit、日志、链接或已有证据 |
| `non_goals` | 明确不做的范围 |
| `expected_output` | 交付物与验证证据 |
| `blocking` | 是否阻塞其他工作 |
| `lens` | 仅 `verifier`：`security` / `performance` / `architecture` |

## Role division

| Role | Use for |
|---|---|
| `inspector` | 有边界的取证、阅读、结构、diff、日志、先例、权衡、划定下一步 |
| `executor` | 边界清晰的实现、窄重构、原型、证明——可合并 diff + 具名检查 |
| `verifier` | 复现、诊断、回归，以及针对具名主张的审查；用 `lens` 加深专项深度 |

包装或润色是编排层的正常输出；除非显式拆 brief，否则不需要单独的 `writer` 角色。

委派时读取对应提示词：

- `references/inspector.md`
- `references/executor.md`
- `references/verifier.md`

## When to route

- **从零 / 最小第一步**：可行性可拆成独立问题时，并行多份 `inspector`；再 `executor`；需要验证时用 `verifier`。
- **维护 / 修复**：结构审查与复现彼此独立时，`inspector` 与 `verifier` 并行；再 `executor`；最后 `verifier` 做回归。
- **研读其他项目**：按问题或子系统并行多份 `inspector`；需要时再做一轮综合。
- **专项审查**：`verifier` + `lens: security | performance | architecture`。

## Operating rules

1. 编排层（主代理或用户）负责拆 brief、合并结果与排序；角色本身不再二次委派。
2. 两个及以上 brief 无依赖时默认并行；一个结果会实质改变下一份 brief 时保持串行。
3. 不通过假协调者角色串联；顺序与合并留在编排层。
4. 方法类工作交给其他 skill（如 `spark`、`tech-preferences`），与当前激活的 role 正交。

## Stop conditions

brief 已可交给对应角色、或用户只需分工说明时停止。不要把 roles 扩写成完整项目路线图——那是 `spark` 的职责。
