---
name: git-workstreams
description: >
  使用 Git/GitHub 组织 change workstream 的 checkout/worktree 拓扑、默认 Draft PR 交付、依赖 branch/PR stack 和持续交付权限边界：经用户明确选择后管理隔离 worktree；从默认分支安全发布；完成仓库改动后默认创建可审阅的 Draft PR，真实依赖拆为 stacked Draft PR；跟进已有 PR 的冲突、CI 与本地 commit/push。适用于 worktree 创建、迁移、安全清理、“branch already checked out”，实现或修改完成后的 PR 交付，从 main/master 发布改动，拆分 stacked/dependent PR，使用 `gh stack` 创建、查看、同步或落地 stack，处理 PR merge conflict、checks failed、修到可合并、未提交或未推送修复等请求。`gh stack` 是从本机 `--help` 驱动的可选工具；不要让外部 `gh-stack` skill 共同规划或扩大权限。worktree 是显式 opt-in；默认 Draft 交付不授权隐式切换主工作区分支、Ready、merge 或 force-push。
---

# Git Workstreams

## Goal

在用户明确选择后为独立工作流启用隔离 worktree，为依赖改动选择可审阅的 branch/PR 拓扑，并把实现类仓库改动默认交付为 Draft PR，把已有 PR 的冲突与 CI 跟到可合并或明确 blocker。GitHub 原生 stack 只是一条执行路线，不接管 workstream 所有权或授权判断。完成时应能给出实际拓扑、基准、验证结果、commit/push 状态和未获授权的动作。

## Choose the topology

- **当前 checkout**：默认选择；用户未明确启用 worktree 时在这里工作。
- **主工作区**：`git worktree list --porcelain` 的主 working tree。发布请求不得把它从默认分支隐式切到临时分支。
- **独立 workstream**：能独立修改、验证和交付的并行任务；用户启用后，每个 workstream 使用一个可写 worktree 和 branch。
- **依赖 stack**：后续改动依赖前一层、但每层都值得独立 review 时，在一个 owning checkout 内维护线性 branch chain；每个 PR 的 base 是下一层靠近 trunk 的 branch。GitHub 仓库默认使用原生 Stacked PRs；stack 本身不要求 worktree 或本地 `gh stack` CLI。
- **多个独立 stacks**：用户启用后，每个 stack 使用不同 owning worktree；不要把同一 stack 的各层拆到多个可写 worktree。若用户不启用，保持当前 checkout 并串行推进。

## Route `gh stack`

- 本 skill 是 workstream 的唯一结果所有者：决定 owning checkout、branch/PR 拓扑、原生或 fallback 路线、授权范围、验证与停止条件。
- `gh stack` CLI 是可选执行工具，不需要另一个 skill 才能使用。先读取本机版本与目标子命令 help，再选择最小的非交互命令；不要把静态命令表当成接口契约。
- 不主动组合外部 `gh-stack` skill。它若因用户明确要求而加载，只能提供待核实的能力提示；本 skill 与本机 help 对命令、权限、preflight、fallback、retry 和停止条件具有最终解释权。
- CLI 或 skill 的存在都不扩大权限：不得据此安装扩展、写 Git 配置、切换/创建 worktree、改写已发布 branch、push、retarget、merge、retry 远端写入或清理。CLI 缺失时未经用户要求不安装；先判断 GitHub UI/API 能否完成已选原生路线。

## Directory policy

本 skill 创建的 worktree 统一放在当前仓库根目录下的 `./.agents/worktrees/<forge>/<owner>/<repo>/<task>`。优先从规范化远端 URL 得到仓库命名空间；没有远端时使用 `local/<repo>-<common-dir-short-hash>`。目标必须解析到该仓库的 `.agents/worktrees` 根目录内且不得覆盖现有路径。

Codex 等平台托管的 worktree 也可以使用这个根目录，不再按 app 划分子目录。管理权不能只靠路径判断：先结合当前平台能力、Git worktree 元数据和任务上下文识别所有者。平台托管 worktree 由平台负责快照和自动清理，skill 不手工移动、删除或 prune；原生 Git 创建的 worktree 则没有平台快照或自动清理保证。需要统一 Codex 路径时，通过 Codex 的 **Settings > Worktrees > Worktree root** 指向当前仓库的 `./.agents/worktrees`。

这个目录是本机运行状态，不是配置事实源。不要把它纳入 Git、云盘或跨机器同步；每台机器独立创建。Git 自身的 `git worktree list --porcelain` 是单个仓库的权威状态，不另建全局 registry。

## Discover the local interface

先确认本机版本并沿当前命令树发现精确语法：

```text
git --version
git worktree --help
git worktree list --porcelain
git branch --help
git rebase --help
gh pr --help  # 仅当任务需要 GitHub PR 且 gh 可用
gh stack --help  # GitHub stack 请求；用于发现本地扩展是否可用
```

只读取目标需要的 help 分支；不要凭记忆或外部 skill 的静态命令表猜快速演进的 flags。GitHub stack 请求默认走下方原生路径，不要求先从仓库配置证明支持。若 CLI 不可用，仍可用标准 Git 管 branch，并在服务端能力存在时通过 GitHub UI/API 建立原生 stack。未经用户要求不安装或升级扩展。

## Workflow

1. **确认结果**：区分普通单线任务、独立 worktree、依赖 stack、原生 stack CLI 操作、stack landing、PR follow-up、只读诊断、迁移或清理；先指定唯一结果所有者，并识别用户是否明确指定了仅本地、commit 或 commit+push 等交付终点。
2. **检查现场**：解析 repo root、absolute/common git dir、superproject、主工作区路径及起始 branch/HEAD、当前 branch/HEAD、dirty 状态、remote、远端默认分支、`git worktree list --porcelain`，以及任务相关 PR 的 head/base、冲突、checks 和可写权限。GitHub stack 请求同时检查 `gh stack` 本地能力和仓库返回的 feature 状态，但不因 CLI 缺失直接判定仓库不支持。普通本地任务不隐式 fetch；PR follow-up 本身依赖当前远端状态，可更新相关 refs 并读取 PR/check 状态。
3. **取得启用选择**：只读盘点不需要确认；创建 worktree、把它作为可写工作区复用、把任务迁入其中或交给另一个 agent 前，必须得到用户明确 opt-in。若当前请求已经明确要求创建或使用 worktree，视为已选择；否则简要说明收益、成本和拟议范围，并直接询问是否启用。在答案到来前保持当前 checkout，不执行 worktree 动作。
4. **选择并画出拓扑**：启用后将独立任务按 worktree 分开；依赖改动无论是否启用 worktree，都按 reviewable concern 从 trunk 向上排列。GitHub 仓库默认保留原生 stack 元数据；只有 GitHub 明确返回未启用/不支持、仓库不在 GitHub，或用户明确退出时才使用普通 chained PR fallback。原生 stack 已进入 landing 阶段时不再回退逐 PR 合并。一个结果会改变上层设计时保持串行。
5. **执行最小动作**：按用户选择复用当前 checkout 或已有隔离环境；新实现从明确基准创建 branch，只有已 opt-in 才创建、进入或交接 worktree。发布前应用下方主工作区保护；不要把 `commit+push`、`提 PR` 或 `github:yeet` 当成隐式切换主工作区的授权。临时只读检查需要新 detached worktree 时也先取得选择。不要用 force 绕过 branch 占用或目标路径保护。
6. **准备和验证**：读取 `AGENTS.md` 和项目 setup，只运行相关检查；不自动复制 `.env`、凭据、ignored 文件或缓存，也不无条件安装依赖。
7. **处理 PR follow-up**：当前 workstream 已有确认过的 PR，且用户要求实现、修复、跟进或保持可合并时，按下方闭环处理范围内冲突与 CI，并把验证过的本地修复小步 commit、及时 push 到已解析的 PR head。只读诊断不获得这些写权限。
8. **处理其他远端动作**：实现或修改仓库内容时，按下方默认交付规则 commit、push 并创建 Draft PR；用户明确指定较窄的交付终点或禁止其中某项时停在该边界。force-push、retarget、Ready 和 merge 仍需明确授权；先解析精确 refs、PR base 和受影响层，再从本机 help 选择所需原生命令。
9. **报告并停止**：达到隔离、stack 或 PR-ready 目标后，报告拓扑、所有权、commit/push、checks 与剩余 blocker；不顺带清理、合并或改写其他 workstream。

## Default Draft PR delivery

- 用户要求实现、修复或修改仓库内容，且没有明确指定更窄的交付终点时，把经过仓库要求验证的改动 commit、push，并创建 Draft PR；不再为“是否提 PR”单独等待一次确认。用户明确要求仅本地、commit 或 commit+push 时停在该终点；只读、诊断、评审、规划和回答类请求不触发该默认。
- 一个可独立 review 的 concern 默认对应一个 Draft PR。只有后续 concern 真实依赖前层、且每层都值得独立 review 时才创建 stacked Draft PR；互不依赖的 concern 使用独立 PR，不为展示 stack 而制造依赖。
- 默认交付只覆盖当前任务确认范围内的非破坏性 commit、push 和 Draft PR 创建。它不授权改变未确认的 checkout/worktree 拓扑，也不授权 force-push、retarget、标记 Ready、merge、清理、deploy 或 release。
- 发布前仍需满足主工作区保护、仓库贡献规范和本地验证。无法安全取得 owning branch/checkout、远端写权限或合规 PR base 时停止并报告具体 blocker，不把默认交付当成绕过权限与拓扑边界的理由。
- PR 创建后回读 head/base、Draft 状态和 CI。用户明确要求推进 Ready 时，只在 exact head 未漂移、required checks 处于仓库允许的终态且没有仓库定义的 Ready blocker 后标记；review approval 与最终 mergeability 留给 Ready 后的 review 或 merge preflight。CI 仍在运行或 head 漂移时继续等待或处理范围内失败。

## Worktree boundaries

- worktree 默认关闭。建议使用时明确询问用户是否启用；没有肯定答复就保留当前 checkout。列出现有 worktree 和检查占用属于只读发现，不等于启用。
- 如果平台已经把当前任务放在 worktree，而用户未在对话中选择它，先说明当前环境和管理者，并询问是否继续在该 worktree 工作，再开始任务改动。
- 一个可写 worktree 同时只交给一个 agent 或一个明确任务；多个 agent 不共享同一个可变 checkout。
- Git refs 和对象库在 worktree 间共享。创建、重置或删除分支会影响同仓库的其他工作区，因此分支动作必须属于用户请求。
- 如果目标分支已在另一个 worktree，先返回其路径；用户明确选择后再复用为可写环境。确需独立只读验证时可从同一提交创建 detached worktree，但创建前同样先询问是否启用，不强制重复 checkout 该分支。
- 主工作区的未提交和 ignored 文件不会由原生 Git 自动进入新 worktree。若任务依赖这些内容，先说明缺口并取得明确处理方式；不自动 stash、复制秘密或伪装成相同环境。
- 创建失败且隔离是任务前提时停止并报告 blocker；不要悄悄退回用户当前 checkout 开始修改。

## Primary checkout publish guard

发布授权只覆盖已确认范围内的 stage、commit、push 和 PR；它不自动授权改变主工作区当前分支。

1. 发布前记录主工作区绝对路径、起始 branch/HEAD、dirty 状态和远端默认分支。不要根据目录名猜主工作区或默认分支。
2. 如果当前位于主工作区的默认分支，且用户没有明确选择“在当前 checkout 切分支”，不得执行 `git switch -c`、`git checkout -b` 或等价 branch-changing 命令。说明现有 WIP 不能安全地隐式迁移，并询问是启用 owning worktree，还是明确允许当前 checkout 的临时分支流程。
3. 如果用户明确选择当前 checkout，可以从确认过的基准创建分支，但必须记录返回点；发布完成且工作树干净后，默认回到起始分支并核对 HEAD/upstream。无法安全返回时停止并报告，不 stash、reset 或覆盖文件。
4. 如果主工作区已经位于目标非默认分支，或当前是已确认的 linked worktree，留在原 branch 完成发布；不要为了符合命名约定再次切分支。
5. `github:yeet` 等发布 workflow 可以负责 stage/commit/push/PR，但 checkout/worktree 拓扑先由本 skill 解析；发布 workflow 不得覆盖这里的主工作区保护。
6. 最终报告主工作区的起始与结束 branch、当前 dirty 状态，以及创建或复用的 owning checkout。主工作区分支变化若未经明确选择，任务不得标记完成。

## Branch and PR stacks

线性 stack 的稳定表示是：

```text
main <- data-model <- api <- ui

PR head       PR base
data-model -> main
api        -> data-model
ui         -> api
```

- 每层只包含一个可独立理解和验证的 concern；依赖必须位于同层或更靠近 trunk 的层。
- 一个 stack 由一个可写 checkout 拥有；启用 worktree 时，整个 stack 只使用一个 owning worktree。不要为每个 PR layer 创建 worktree；Git 的 branch 占用规则和跨层 rebase 会使这种布局互相阻塞。
- 从 bottom 到 top 创建和提交 branch；发布时先确保对应 base branch 已在远端，再逐层核对 PR `head -> base`，bottom 指向 trunk，其余指向下层 branch。
- 修改较低层后，从该层向上按依赖顺序重放后继 branch，并在每层运行相关验证。若 branch 已发布，重写和 force-push 前必须明确受影响的 refs/PR；用户明确要求同步该远端 stack 时才执行。
- 落地顺序是 bottom-up。下层合并后，重新解析剩余 branch 的 base、trunk 差异和 PR 状态，再决定 retarget/rebase；不要假设托管平台会自动修复。

### GitHub native stack route

- 默认尝试 GitHub 原生 Stacked PRs。优先复用本地 `gh stack`；CLI 不可用但服务端能力存在时，用标准 Git 管 branch，并通过 GitHub UI/API 创建或连接原生 stack。
- `gh stack` 的能力包括初始化/扩展 stack、推送、提交或更新 PR、查看、同步、重排和级联 rebase。精确命令与 flags 必须从本机 `gh stack --help` 及相关子命令 help 获取。
- `sync`、`rebase`、`push`、`submit`、`link`、`merge` 或重排可能 fetch、改写 branch、push、更新 PR、合并或清理本地分支；按实际 help 和用户授权拆开，不把组合命令当成只读操作。
- 不机械串联组合命令。每个改变状态的命令后先重新读取 branch/PR/stack；例如 `sync` 已完成 push 或 PR 同步时，只在仍有目标状态缺口且用户授权覆盖时再 `submit`，避免重复远端写入。
- 只有 GitHub 明确返回 feature 未启用/不支持、仓库不在 GitHub，或用户明确要求不用原生 stack 时，才回退到标准 Git branch/rebase/push 与普通 PR `head -> base` 链。fallback 仍需报告完整映射。

### Landing an official GitHub stack

用户必须明确要求 merge/land；“跟到可合并”、修 CI 或发布 stack 都不授权合并。获得授权后：

1. 重新读取每个目标 PR 的 live base/head、exact head OID、draft/review/check/merge 状态，并查询服务端 official stack object。base chain 只用于建立预期，官方 stack 的 number、trunk、entries 和 position 才是 membership/order 权威。
2. 要求所有 head branch 位于同一仓库，目标形成唯一的 bottom-to-top chain，且官方 stack 不含意外成员或顺序。cross-fork、多个 stack number、未知成员或顺序冲突时停止并请求用户决定。
3. 如果预期成员尚未全部链接，`link` 是独立的远端修改。只有用户的 landing 请求明确覆盖该完整 chain、所有 PR 作者相同且现有 official stack 是顺序一致的子集时才可补链；否则先询问。补链后必须重新查询并验证完整 stack。
4. 合并前要求选定范围内每个 PR 都 open、non-draft，并分别满足仓库 review、required checks 与 mergeability 规则；ready 的上层不能证明下层 ready。整 stack landing 选择全部层；partial landing 必须有明确 boundary，并包含 bottom 到 boundary 的连续前缀。
5. 从本机 help 选择官方 stack merge 命令。CLI/服务端能力不可用或 native merge 报 blocker 时停止；远端写入结果不明时先只读回查，不自动 retry。不要退回 `gh pr merge`、逐层 retarget 或手工模拟原子 merge。
6. 等待每个选定 PR 的 live state 为 `MERGED`；queued 不是完成。partial landing 后重新验证剩余层仍属于预期 official stack，并重新检查可能被 GitHub 改写的 head、review 和 CI。branch 删除是后续独立动作，先确认没有 open PR 仍以它为 base。

按任务读取官方资料：

- [Overview](https://github.github.com/gh-stack/introduction/overview/)：stack 语义、CI/rules、merge 与 rebase。
- [Quick Start](https://github.github.com/gh-stack/getting-started/quick-start/)：前置条件、CLI/agent setup 与首个 stack。
- [Working with Stacked PRs](https://github.github.com/gh-stack/guides/stacked-prs/)：push、submit、review、merge 与 sync。
- [Typical Workflows](https://github.github.com/gh-stack/guides/workflows/)：日常提交、review feedback、sync、rebase 与既有 branch。
- [Restructuring Stacks](https://github.github.com/gh-stack/guides/modify/)：重排、fold、drop、insert 与 rename。
- [CLI reference](https://github.github.com/gh-stack/reference/cli/)：命令能力；实际执行仍以本机 help 为准。
- [GitHub UI](https://github.github.com/gh-stack/guides/ui/) 与 [FAQ](https://github.github.com/gh-stack/faq/)：UI 操作、限制和故障判断。

## PR follow-up loop

“检查/总结/解释 PR”是只读请求；对已有 PR 的实现、修复、跟进、解决冲突或做到可合并，授权范围内本地编辑、commit，并 push 到该 PR 已确认的 head branch。它不授权 force-push、修改其他分支、retarget 或 merge。

1. **解析目标与所有权**：确认精确 PR、head repo/branch、base、当前 checkout/worktree 管理者、dirty 内容、冲突、checks 和 push 权限。不要把用户或其他任务的未提交改动混入 PR。
2. **解决冲突**：按仓库约定选择 merge 或 rebase，逐项理解冲突双方意图并运行相关验证。stack 从 bottom 向 top 处理；低层变化重放到后继层后分别验证。已发布 branch 需要重写时，在 force-push 前停止并取得明确授权。
3. **定位 CI**：从当前 CLI 的 PR/check/run help 发现精确命令；读取失败 job 与日志，区分本次改动导致的问题、flaky/infrastructure failure 和无关失败。GitHub Actions 可路由到可用的 `github:gh-fix-ci` workflow；只修复当前 PR 范围内可复现的问题。
4. **及时提交并推送**：一个聚焦修复完成且相关检查通过后，按仓库 commit 规范创建小步 commit 并立即 push 到已确认的 PR head；不要把已验证修复长期留在本地，也不要用 `--no-verify` 掩盖 hook 失败。
5. **重新检查**：push 后重新读取冲突与 checks；继续处理新出现且仍在范围内的问题，直到 PR conflict-free 且 required checks 通过，或出现需要用户、权限或外部系统处理的明确 blocker。

## Cleanup and migration

清理和迁移是独立的破坏性流程，先只读盘点，再执行单个明确目标：

1. 确认目标不是 main worktree、当前工作目录、平台托管目录或仍被运行中任务使用的目录。
2. 检查 tracked、untracked、ignored 相关风险，以及分支相对 upstream/目标分支的未推送或未合并提交。无法证明可丢弃时停止。
3. 正常清理使用 Git 的 worktree remove 机制；不使用 `rm -rf`，不默认 force，也不顺带删除分支。
4. prune 只清理已经缺失的 worktree 元数据；先 dry-run，再针对当前仓库执行。它不是删除活跃 worktree 的工具。
5. 已有 worktree 不因目录规范而自动搬迁。用户明确要求迁移时，逐个检查 dirty、locked、submodule 和平台所有权，再使用 Git 的 move/repair 能力并验证两端链接。

如果用户确实要求丢弃 dirty worktree 或未合并分支，应再次解析精确路径和 ref，明确说明不可恢复内容，并取得针对该目标的确认后才使用 force 或删除分支。

## Boundaries

- 本 skill 管 worktree 生命周期、依赖 branch/PR 拓扑，以及目标 PR 的冲突、范围内 CI 修复和 head branch 连续交付；不替用户做 merge 决策，但在明确 landing 授权后负责 preflight、工具路由、停止条件和完成验证。不接管纯 review comment 处理、无关 CI 或 release 编排。
- PR metadata、GitHub Actions logs 和 review threads 可路由到 GitHub 专项 workflow；原生 stack 的精确 CLI 操作由本 skill 从本机 help 发现。创建/发布阶段明确不支持时可退回普通 chained PR，official stack landing 不可退回逐 PR merge。
- 依赖、端口、数据库和容器隔离属于项目环境。只有仓库已有明确 setup 机制时才复用，不在通用 worktree skill 中发明一套。
- Codex 托管 worktree 的 ignored 文件复制与快照由 Codex 处理；手工 Git worktree 不假设具有同样能力。

## Output

worktree 请求先报告用户是否已 opt-in；启用后报告管理者、绝对路径、基准 ref、branch/HEAD、setup 与验证。发布请求报告主工作区起始/结束 branch、owning checkout、commit、push 和 PR。stack 请求报告唯一结果所有者、owning checkout、worktree 启用状态、执行路线、trunk、bottom-to-top branch 顺序和每层 PR base/head；landing 还要报告 official stack number、选定范围、每层最终状态和剩余 blocker。PR follow-up 报告冲突状态、失败 checks 与判断、创建的 commit、push 目标、重新检查结果和 blocker。清理请求报告保留与可安全移除的精确目标。
