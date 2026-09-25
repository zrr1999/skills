# Language-specific failure signals

按 diff 实际涉及的语言加载。这里的写法只是调查线索：只有能指出具体 failure mode、无效复杂度、已验证的兼容性问题，或违反目标仓库明确约定时，才形成 finding。单独出现某种语法、标准库选择或风格差异不是 slop。

## Rust

- `.clone()` 只有在造成可测的内存/性能问题、掩盖错误的所有权边界或违反仓库约定时才报告；先证明该借用关系可安全简化。
- 未使用的 trait bound、不可达 error variant 或纯转发抽象可以作为 `delete` / `consolidate`，但必须定位真实使用点。
- 旧 API 只有在违反仓库 MSRV、触发 warning、造成兼容问题或已有迁移约定时才是 finding。
- `anyhow`、`thiserror` 或自定义 error enum 是架构选择；没有传播、分类、恢复或公共 API 的具体问题时不评价偏好。

## Python

- 裸 `except:`、吞异常或 catch-log-reraise 只有在改变中断语义、丢失上下文或制造重复日志时报告。
- `Any`、默认 `{}` 链或额外 `None` 检查只有在绕过已声明 invariant、隐藏缺失配置或让类型错误逃逸时报告。
- 为一个小能力引入依赖、无状态 class 或重 mock 测试，按主清单证明维护成本或 test theater 后再报告。
- `os.path`、`.format()`、`typing.Optional` 等写法本身不是 finding；仅在违反项目最低版本与明确规范，或造成真实可读性、类型或平台错误时处理。

## TypeScript / JavaScript

- `any`、断言和 optional chaining 只有在绕过边界校验、掩盖不可能状态或让错误延迟到运行时才报告。
- `new Promise(async ...)` 在 executor 的异常/完成语义不正确时是 `fix`；确定性代码中的 try/catch 在确实吞错或伪造 fallback 时报告。
- 重复用途依赖、平台已有能力的冗余 polyfill，或无价值的 barrel 可以在能证明 bundle、版本或依赖边界成本时报告。
- `.then()`、`React.FC`、enum、barrel 或显式类型本身不是 finding；服从仓库约定和当前 API 语义。

## Shell

- 未引用变量只有在 word splitting、glob 展开或空值会改变命令目标时报告；给出具体输入或路径风险。
- pipeline 或子命令失败被忽略、错误码被重写、`|| true` 掩盖必需步骤时报告实际失败传播问题。
- 解析 `ls`、不受控 glob 或未核实 flag 只有在会产生歧义、错误目标或版本不兼容时形成 finding。
- 未使用 `set -euo pipefail` 本身不是 finding；是否需要严格模式取决于脚本预期的失败与恢复语义。

## 其他语言

只使用主 skill 的通用清单和目标仓库约定。没有具体 failure mode 时不把另一种 idiom 当成自动 finding。
