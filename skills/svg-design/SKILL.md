---
name: svg-design
description: >
  手写或编辑独立 SVG、图标系统、Logo 概念与预览工作流；路径/形状、stroke 与 viewBox 约定、渐变遮罩剪切、优化（SVGO）、动效与无障碍。
  Use when creating SVG files, designing logos or icons, writing path data, optimizing SVGs, building icon systems,
  animating SVG elements, or modifying vector graphics.
  Skip for pure raster workflows, non-vector diagram specs-only tasks, or general page layout/CSS unrelated to SVG assets.
---

# SVG Creation and Editing

## Goal

交付结构清楚、可缩放、可渲染验证并适合目标环境的 SVG。编辑现有资产时保留其设计系统和用途；创建新资产时只引入完成请求需要的结构、变体与预览。

## Topic routing

只读取当前任务需要的 reference：

| Task | Load reference |
|---|---|
| SVG 骨架、viewBox、stroke、shape/path、fill rule、常见反模式 | `references/svg-basics.md` |
| Arc flags 与常用 path | `references/path-patterns.md` |
| Logo、字标、负空间与概念多样性 | `references/logo-techniques.md` |
| 图标网格与像素对齐 | `references/icon-design.md` |
| 渐变、mask、clip、filter、transform | `references/advanced-techniques.md` |
| CSS/SVG 动效 | `references/animation.md` |
| SVGO、sprite 与发布优化 | `references/optimization.md` |
| 无障碍与浏览器兼容 | `references/accessibility-and-pitfalls.md` |
| 编辑、布尔操作、组合与预览 | `references/editing-workflow.md` |

## Workflow

1. **确认交付物**：区分单个图标、Logo/字标、图标系统、现有 SVG 编辑、动画或优化；确认目标尺寸、主题、使用环境和必须保留的结构。
2. **只补关键缺口**：若缺失信息会改变图形语言、具体 imagery、变体或文件结构，提出最少的定向问题。用户已给出具体视觉风格和 imagery 时直接推进，不为流程而重复澄清。
3. **检查现场**：编辑项目资产时先读已有 token、图标、命名、viewBox、stroke/fill 和构建方式。不要把个人默认覆盖到现有系统。
4. **创建最小结构**：选择语义清楚的 shape 或 path，保持稳定 viewBox；需要主题继承时使用 `currentColor`。只在交付环境需要时生成 dark、filled、responsive 或其他变体。
5. **验证后再交付**：解析 XML，渲染并检查裁切、留白、对齐、stroke、主题背景和目标尺寸；优化不能破坏语义、可访问性或动画 target。

## Logo decisions

- 当用户只有模糊方向且请求多方案时，用少量结构化选择收敛 mood、focus 和行业相关 inspiration；不要先生成十几个同质成稿。
- 多方案应覆盖不同 metaphor 和结构类别，而不是同一图形的排版变体。需要五个以上概念时，至少覆盖字标、具象符号、抽象几何和字母混合方向。
- 技术或系统型品牌优先从生成单元、网格、重复、镜像或旋转关系解释结构；有意打破对称时说明识别目的。
- 完整 lockup、横向字标和头像裁切应共享同一识别骨架。头像使用独立 square mark，不直接缩小横向 lockup。
- 用户需要比较多个方案或视觉 QA 时，复用 `assets/preview.html` 和 editing reference 的数据格式。使用当前环境允许的文件操作；只有预览有助于任务时才打开浏览器，并在新增方案后更新同一预览。

## Quality and safety

- 独立 SVG 必须有 `xmlns` 和 `viewBox`；不要只写固定像素宽高而失去缩放语义。
- 分发用字标不要依赖目标机器字体；需要可移植时将最终文字转换为 path，同时保留可编辑源或说明字体。
- 删除编辑器 metadata、无效节点和多余精度，但保留有意义的 ID、title/desc、animation target 和引用关系。
- 外部图片、字体、filter 或脚本会改变可移植性和安全面，只在需求明确且目标环境支持时使用。
- 不把未知 SVG 当作可信代码直接执行或嵌入页面；先检查脚本、事件属性、外链和 data URL。

## Output and stop rules

执行类请求交付 SVG 文件、必要变体、预览或集成说明，并报告渲染/优化验证。规划类请求给出视觉方向、结构和最小下一步。产物满足目标尺寸、背景、可访问性与结构要求后停止；不要额外扩展品牌系统或生成未请求的变体。
