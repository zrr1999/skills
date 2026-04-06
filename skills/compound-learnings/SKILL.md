---
name: compound-learnings
description: 应在解决了一个非平凡问题后使用——例如踩坑修复、架构决策、性能调优、集成调试等场景。将解决方案沉淀为结构化的 learning 文件，让后续 session 能检索复用。也可在新 session 开始时用来检索已有 learnings。
---

## 目的

每次工程工作应让后续工作更轻松。本 skill 提供一个**经验沉淀与检索机制**，将解决过的问题文档化为可检索的 learning 文件，避免重复踩坑。

借鉴自 compound engineering 理念：80% 的价值在规划和复盘，20% 在执行。

## 目录结构

在项目根目录维护 `.learnings/` 文件夹：

```
.learnings/
├── patterns/       # 可复用的模式和最佳实践
├── gotchas/        # 踩坑记录和解决方案
├── decisions/      # 架构和技术决策记录
└── README.md       # 索引（自动维护）
```

## Learning 文件格式

每个 learning 是一个 markdown 文件，带结构化 frontmatter：

```markdown
---
title: "Webhook 验证必须使用 raw body"
category: gotchas
tags: [stripe, webhook, python]
created: 2025-01-15
context: "集成 Stripe webhook 时验证始终失败"
---

## 问题

Stripe webhook 签名验证要求使用原始请求体（raw body），但 FastAPI 默认会解析 JSON。

## 解决方案

在验证前获取 raw body：

\```python
@app.post("/webhook")
async def webhook(request: Request):
    body = await request.body()  # raw bytes
    sig = request.headers.get("stripe-signature")
    event = stripe.Webhook.construct_event(body, sig, secret)
\```

## 关键点

- 必须在任何 JSON 解析之前获取 raw body
- `request.json()` 和 `request.body()` 不能同时调用（body 只能读一次）
```

## 沉淀流程（解决问题后）

1. **识别沉淀时机** — 刚解决了一个耗时 >15 分钟的问题、做了一个非显而易见的技术决策、发现了一个文档未记录的坑
2. **选择分类**：
   - `patterns/` — 可复用的模式（如「用 X 做 Y 的标准方式」）
   - `gotchas/` — 踩坑记录（如「X 在 Y 条件下会失败」）
   - `decisions/` — 决策记录（如「选 X 而非 Y，因为...」）
3. **撰写 learning** — 按上述文件格式写入 `.learnings/<category>/<slug>.md`
4. **更新索引** — 在 `.learnings/README.md` 中追加条目

## 检索流程（新 session 开始时）

1. **自动扫描** — 检查当前项目是否有 `.learnings/` 目录
2. **关键词匹配** — 根据当前任务的技术栈、库名、问题关键词搜索相关 learnings
3. **呈现相关经验** — 将匹配的 learnings 摘要展示给 agent，作为上下文

```bash
# 搜索相关 learnings
grep -rl "stripe" .learnings/
grep -rl "webhook" .learnings/

# 按 tag 搜索（在 frontmatter 中）
grep -rl "tags:.*stripe" .learnings/
```

## 索引文件格式

`.learnings/README.md` 作为索引：

```markdown
# Project Learnings

## Patterns
- [组件懒加载标准方式](patterns/lazy-loading.md) — React, performance

## Gotchas
- [Webhook 验证必须用 raw body](gotchas/stripe-webhook-raw-body.md) — stripe, webhook, python

## Decisions
- [选 FastAPI 而非 Flask](decisions/fastapi-over-flask.md) — python, web, framework
```

## 与其他 skill 的关系

- 与 `get-api-docs` 互补：chub annotation 解决 API 文档补丁，本 skill 解决项目级经验沉淀
- 与 `project-workflows` 互补：可作为统一工作流一次非平凡推进后的收尾步骤
- 与 `tech-preferences` 互补：decisions 分类中的选型决策可以反哺 tech-preferences 的偏好基线
