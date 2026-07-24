# SVG basics

用于创建普通图标或检查基础 SVG 结构。Logo 概念、动画、优化和高级效果读取对应专项 reference。

## Minimal skeleton

```xml
<svg
  xmlns="http://www.w3.org/2000/svg"
  viewBox="0 0 24 24"
  fill="none"
  stroke="currentColor"
  stroke-width="2"
  stroke-linecap="round"
  stroke-linejoin="round"
>
  <!-- content -->
</svg>
```

根据实际画布调整 `viewBox`。默认省略 `width`/`height` 以允许容器缩放；只有目标环境需要固定 intrinsic size 时才添加。

## Canvas and stroke

| viewBox | Common use | Typical stroke |
|---|---|---|
| `0 0 16 16` | micro icon / favicon | `1.5` |
| `0 0 20 20` | small UI icon | `1.5`–`2` |
| `0 0 24 24` | standard UI icon | `2` |
| `0 0 32 32` | medium icon | `2`–`2.5` |
| `0 0 48 48` | display icon | `3` |
| custom | logo / illustration | follow natural aspect ratio |

`stroke-width` 使用 viewBox 单位，不是屏幕像素。选择与现有图标系统一致的视觉重量，不机械套默认值。

## Shape or path

优先使用 shape primitive：

- 圆、矩形、线等几何结构本身具有语义；
- 需要独立修改或动画化 `r`、`cx`、`width` 等属性；
- 可读性比最少节点更重要。

使用 `<path>`：

- 轮廓包含曲线或复合形状；
- 需要布尔组合或 compound path；
- 发布目标只接受 path；
- 减少节点确实改善发布或动画行为。

不要仅为“统一成 path”牺牲可读性。转换前保留可编辑源。

## Fill, stroke, and holes

- 主题化描边图标通常在根元素使用 `fill="none"`、`stroke="currentColor"`。
- 填充 Logo 的颜色取决于品牌 token；不要默认继承文本色。
- `stroke-linecap="round"` 和 `stroke-linejoin="round"` 适合多数小尺寸 outline icon，但应服从现有设计系统。
- compound path 有洞时，优先显式使用 `fill-rule="evenodd"`；使用默认 `nonzero` 时必须确保内外轮廓方向正确。

## Precision and structure

- 小图标通常保留 2 位小数，复杂曲线最多 3 位；在渲染检查前不要盲目降精度。
- flatten 深层 transform 能提高可移植性，但若动画或编辑依赖 transform 层级则应保留。
- 使用现代 `href`，不要新增已弃用的 `xlink:href`。
-  standalone SVG 保留 `xmlns`、稳定 `viewBox` 和有意义的 `title`/`desc`。

## Common failures

| Failure | Preferred behavior |
|---|---|
| 只有固定 `width`/`height` | 同时提供正确 `viewBox` |
| 在坐标中使用 `px` | 使用无单位 viewBox 坐标 |
| 保留 Inkscape/Sodipodi metadata | 发布产物删除编辑器 cruft |
| 分发字标仍使用 `<text>` | 转 path，另存可编辑源 |
| 多层 transform 难以检查 | 在不破坏语义时 flatten |
| 过多小数 | 按尺寸降低精度并重新渲染 |
| dark variant 使用 CSS filter 猜颜色 | 需要时提供设计过的明确颜色变体 |
