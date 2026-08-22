# Language-specific slop

按 diff 实际涉及的语言加载本节。通用清单见 `SKILL.md`；这里只补各语言特有、且通用清单盖不住的信号。

## Rust

- **Clone abuse**：为逃 borrow checker 到处 `.clone()`——最典型的 AI Rust 信号。先重新想所有权/借用设计，clone 是最后手段。
- **Error type proliferation**：每个模块自定义 error enum。应用层用 `anyhow`，库用 `thiserror`。
- **Trait bound 堆砌**：`T: Display + Debug + Clone + Send + Sync` 实际只用了 `Display`。
- **Verbose**：两臂 `match` 该用 `if let`；函数末尾显式 `return`；手动 match Option/Result 而不用 combinator。
- **Stale**：`extern crate`、`#[macro_use]`、`try!()`、`lazy_static`（1.80+ 用 `std::sync::LazyLock`）。

## Python

- **Class-for-everything**：无状态类应是函数或模块级代码。
- **Exception**：裸 `except:`（吞 KeyboardInterrupt/SystemExit）；`except Exception as e: logger.error(e); raise` 零信息；对签名已声明类型的参数做 None check。
- **Stale**：`os.path` 而非 `pathlib`；`.format()` 而非 f-string；`typing.Optional[X]` 而非 `X | None`（3.10+）。
- **Type hints**：用 `Any` 绕过类型错误；显然可推断处的冗余标注。
- **Dep creep**：为单个 GET 引入 `requests`。
- **Tells**：`dict.get(..., {})` 链式兜底洗 missing invariant；mock 重度测试无行为断言。

## TypeScript / JavaScript

- **Type abuse**：可推断处冗余标注；`any` 代替 `unknown`；enum 代替 const object/union。
- **Stale**：ESM 里 `require()`；`var`；`React.FC`；`.then()` 链代替 async/await。
- **Barrel files**：小目录里 `index.ts` 纯 re-export，徒增 import 间接层。
- **Dep creep**：`node-fetch`（fetch 已全局）、`uuid`（有 `crypto.randomUUID()`）、两个库干同一件事。
- **Tells**：确定性本地代码包 try/catch；`new Promise(async ...)`；必需 env/config 给兜底默认值。

## Shell

- 缺 `set -euo pipefail`；变量不加引号。
- `cat file | grep`；反引号代替 `$()`；解析 `ls` 输出。
- 每行 `if cmd; then ... fi` 代替 `set -e`；手动查 `$?`。
- `2>/dev/null || true` 掩盖不确定；幻觉 flag——一律对 `--help` 验证。

## 其他语言

Go 及未列出的语言：只套用 `SKILL.md` 通用清单，并在报告里注明语言专项检查已跳过。不要把某一语言的 idiom 套到另一语言上。
