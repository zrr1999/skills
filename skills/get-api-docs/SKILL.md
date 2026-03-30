---
name: get-api-docs
description: 应在需要第三方库、SDK 或 API 文档时使用——例如「用 OpenAI API」「调 Stripe 接口」「查 Anthropic SDK」等场景。先用 chub 获取策划文档再作答，不要依赖训练数据中的 API 知识。
---

## 目的

通过 `chub` CLI 获取社区维护的 API 文档，避免 agent 幻觉出错误的 API 用法。chub 提供 605+ 库的策划文档，支持多语言变体。

## 工作流程

### 查找文档

```bash
chub search "<库名>"            # 模糊搜索
chub search "<库名>" --json     # 机器可读格式
```

### 获取文档

```bash
chub get <id> --lang py         # Python 变体
chub get <id> --lang js         # JavaScript 变体
chub get <id>                   # 单语言自动选择
chub get <id> --full            # 含所有参考文件
```

### 使用文档

阅读获取的内容，基于文档编写代码。**不要依赖记忆中的 API 签名**——以文档为准。

### 标注经验

完成任务后，如果发现文档未覆盖的坑（环境特定、版本差异、项目特定细节），保存标注：

```bash
chub annotate <id> "Webhook 验证需要 raw body，不要在验证前解析 JSON"
```

标注持久化在本地（`~/.chub/annotations/`），下次 `chub get` 同一文档时自动附带。

## 快速参考

| 目标 | 命令 |
|------|------|
| 列出所有文档 | `chub search` |
| 搜索文档 | `chub search "stripe"` |
| 获取 Python 文档 | `chub get stripe/api --lang py` |
| 获取 JS 文档 | `chub get openai/chat --lang js` |
| 保存到文件 | `chub get anthropic/sdk --lang py -o docs.md` |
| 批量获取 | `chub get openai/chat stripe/api --lang py` |
| 标注经验 | `chub annotate stripe/api "需要 raw body"` |
| 查看所有标注 | `chub annotate --list` |

## 不适用

- 自己开发的项目文档——直接在项目内维护 `AGENTS.md` / `README.md` 更直接
- 需要最新未发布版本的文档——chub 内容由社区维护，可能滞后
- 纯内部 API——除非自己构建本地 chub content（参见 `chub build`）

## 与其他 skill 的关系

- 与 `tech-preferences` 正交：本 skill 解决「如何正确使用某库」，后者解决「该选哪个库」
- 与 `modern-python` 互补：当 Python 项目需要某个库的文档时，先用本 skill 获取
