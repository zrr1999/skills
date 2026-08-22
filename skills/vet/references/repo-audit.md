# Repo audit（vet 的仓库级轨道）

仅在 repo 范围时加载：全仓技术债/架构/质量审计，或公开发布/开源/v1.0/package publish 前的 release readiness 预检。diff 级审查回 `../SKILL.md` 的 diff 轨道。

## Goal

把"这个仓库哪里有风险、先修什么、哪些只是长期债务"变成可决策的证据。结论必须区分真实风险、用户决策、低风险修复和 backlog，不把工具分数直接当 gate，也不把长期 polish 伪装成发布 blocker。

## Mode and boundary

先从用户目标判断模式：

- **maintenance**：技术债、架构健康、复杂度、重复、测试、依赖、配置、文档漂移或长期可维护性。
- **public-release**：公开仓库、开源、v1.0、package publish、Scorecard、license/REUSE、security posture 或 public-ready。
- **mixed**：同时存在公开发布和内部质量问题时，先 release readiness，再 maintenance priorities。
- **portfolio**：用户明确要求多个相关仓库；先确定纳入/排除集合，每个仓库都必须有本地可读路径才能给 `file:line` 证据。

内部 CI/tag 检查只走普通维护或 release 调试，不启动 public-release preflight。不要替用户公开仓库、选择许可证、重写历史、轮换密钥、删除数据或做高风险升级。

## Inspect first

冻结证据点：仓库路径、分支/commit、remote、dirty status、用户指定范围和排除项。然后建立 1-2 段实际 mental model，至少检查：

- README/quickstart、贡献和安全文档、主要目录与入口；
- manifest/lockfile、脚本、测试、CI、发布配置、package metadata；
- 最近提交/churn、最大或最常改文件，以及它们与测试覆盖的关系；
- public-release 时的 LICENSE/NOTICE、公开 URL、示例、私密笔记、生成文件、二进制和大文件。

先运行仓库已有的 lint、typecheck、test、build、package 或 smoke 命令。额外工具只在本地已有或明确值得安装时使用；工具缺失要记录原因，不能静默跳过或全局安装。

## Evidence pass

按问题选择检查，不要全量堆命令：

| Category | Useful signals |
|---|---|
| Release posture | `scorecard --repo=... --format=json`、具体 Scorecard checks、`reuse lint`、license/package metadata |
| Secrets and CI | `gitleaks detect --source . --redact`、`zizmor .github/workflows`、workflow permissions、第三方 action pinning |
| Dependencies | 项目原生 audit、`osv-scanner`、`pip-audit`、`npm/pnpm audit`、`cargo audit`、`knip` 等 |
| Duplication | `jscpd` 或语言原生 clone 检查，记录 clone group 与文件位置 |
| Complexity | `lizard` 或语言原生复杂度工具，记录函数、NLOC、CCN、参数数 |
| Architecture | `madge`、`pydeps`、`go list`、`cargo metadata` 等依赖图；关注环、跨层调用和 god module |
| Static and tests | `tsc`、`ruff`、`ty`、`clippy`、`go vet`、仓库测试与 coverage；关注高 churn 无测试、skip/flaky |
| Documentation drift | README 命令与真实 install/build/run/release 路径是否一致 |

工具输出只是线索。一个根因合并为一个 finding，工具结果和代码阅读作为同一条 evidence；每个 finding 要有 `file:line`、具体工具结果或明确说明"未能取得证据"。

## Semantic lenses

维护审计按实际相关维度取证：

- architecture decay：依赖环、god file/function、跨边界调用、重复状态机；
- contract/type debt：松散 dict、`any`/`ignore`、trust boundary 缺 schema、错误 shape 不一致；
- test/dependency/config debt：关键路径缺测试、依赖和 env 漂移、默认值不一致；
- resource/observability/security hygiene：N+1、阻塞 I/O、句柄泄漏、吞异常、硬编码 secret、弱 auth 或未校验输入；
- documentation drift：文档、命令、API 和代码现实冲突。

用户明确要求抽象结构视角时，可使用 **Structural / algebraic lens**，但每条观察都必须翻译成维护风险，并给出 `file:line` 和修复方向：

- symmetry：同一状态/权限/undo 在多个模块分别实现，新增状态容易漏改；
- algebraic：merge/reduce/pipeline/配置叠加缺少 identity、结合性或清晰的 zero-like 行为；
- composition：adapter、跨层调用或共享全局状态让组合顺序改变语义；
- representation：规则散落在 if/else，数据表示没有承载足够的业务约束。

没有代码证据的数学术语不是 finding。

## Release triage

public-release 或 mixed 必须先给：

- **Blocker**：确认的 secret/私密数据、缺失而且无法确认的 license、坏掉的公开安装路径、已知可利用漏洞等；
- **User Decision**：许可证、是否延后公开、是否 rewrite history/rotate secret、branch protection、签名 release、接受哪些 Scorecard 缺口；
- **Fix Now**：低风险 README/链接/`.gitignore`/quickstart 清理；
- **Backlog**：不影响此次公开的 polish、额外 examples、低收益 Scorecard 改善。

公开 readiness 至少覆盖 secrets/history、license/REUSE、README/quickstart、CI/test/build/release path、public surface、workflow 权限和依赖漏洞。聚合分数只能作背景，优先具体高风险 check。

## Synthesis

维护 finding 使用 `Critical/High/Medium/Low` 和 `S/M/L` 工作量；按影响、证据强度和修复顺序排序，去重后通常不超过 50 条。输出默认在对话中完成，不创建 `QUALITY_AUDIT.md` 或其他报告文件。

输出至少保留与当前模式相关的：结论、模式/范围/基线、mental model、关键证据、findings（带定位）、Top priorities、quick wins、误报排除、开放问题和未运行命令。仅 public-release 或 mixed 时加入 Readiness、发布分类和 Decisions needed；maintenance-only 不要凭模板生成发布结论。

mixed 模式按 release readiness、maintenance findings、发布后 backlog 分段。portfolio 额外给 repo scope、基线、排除项、跨仓 mental model、每仓 roll-up 和组合级优先级。若用户明确要求保存，再按指定路径生成报告。

## Stop rules

当核心请求已有足够证据、每个高优先级 finding 都能定位且建议可验证时停止。只有在缺少必需事实、用户要求穷尽比较或重要主张无支撑时才追加一次有目的的检查；仍缺失就报告缺口，不用猜测填充。
