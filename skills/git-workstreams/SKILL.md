---
name: git-workstreams
description: >
  使用标准 Git/GitHub 组织 change workstream：经用户明确选择后创建和管理隔离 worktree；安全地从默认分支发布本地改动；设计、发布和同步线性 branch/PR stack；跟进已有 PR 的冲突、CI 与本地 commit/push。适用于 worktree 创建、迁移、安全清理、“branch already checked out”，从 main/master 执行 commit+push 或创建 PR，stacked PR、依赖 PR、分层 review、PR merge conflict、checks failed、修到可合并、未提交或未推送修复等请求。worktree 是显式 opt-in；发布授权不等于允许隐式切换主工作区分支。默认不要求 gh-stack、Graphite 等专用工具。不要用于用户明确要求的普通短暂分支切换、只读 PR 摘要、纯 review comment 处理、release 编排，或未经确认丢弃/重写已发布工作。
---

# Git Workstreams

## Goal

在用户明确选择后为独立工作流启用隔离 worktree，为依赖改动选择线性 branch/PR stack，并把已有 PR 的冲突与 CI 跟到可合并或明确 blocker。发布过程中保持主工作区分支可预测；完成时应能给出实际拓扑、基准、验证结果、commit/push 状态和未获授权的动作。

## Choose the topology

- **当前 checkout**：默认选择；用户未明确启用 worktree 时在这里工作。
- **主工作区**：`git worktree list --porcelain` 的主 working tree。发布请求不得把它从默认分支隐式切到临时分支。
- **独立 workstream**：能独立修改、验证和交付的并行任务；用户启用后，每个 workstream 使用一个可写 worktree 和 branch。
- **依赖 stack**：后续改动依赖前一层、但每层都值得独立 review 时，在一个 owning checkout 内维护线性 branch chain；每个 PR 的 base 是下一层靠近 trunk 的 branch。stack 本身不要求 worktree。
- **多个独立 stacks**：用户启用后，每个 stack 使用不同 owning worktree；不要把同一 stack 的各层拆到多个可写 worktree。若用户不启用，保持当前 checkout 并串行推进。

## Directory policy

本 skill 创建的 worktree 统一放在 `~/.agents/worktrees/<forge>/<owner>/<repo>/<task>`。优先从规范化远端 URL 得到仓库命名空间；没有远端时使用 `local/<repo>-<common-dir-short-hash>`。目标必须解析到统一根目录内且不得覆盖现有路径。

Codex 等平台托管的 worktree 也可以使用这个根目录，不再按 app 划分子目录。管理权不能只靠路径判断：先结合当前平台能力、Git worktree 元数据和任务上下文识别所有者。平台托管 worktree 由平台负责快照和自动清理，skill 不手工移动、删除或 prune；原生 Git 创建的 worktree 则没有平台快照或自动清理保证。需要统一 Codex 路径时，通过 Codex 的 **Settings > Worktrees > Worktree root** 指向 `~/.agents/worktrees`。

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
```

只读取目标需要的 help 分支；不要凭记忆猜快速演进的 flags。若仓库已经使用专用 stack 工具，读取其本机 help 并遵守仓库约定；否则使用标准 Git branch/rebase/push 与 GitHub PR base/head，不为 stack 引入新工具。

## Workflow

1. **确认结果**：区分普通单线任务、独立 worktree、依赖 stack、PR follow-up、只读诊断、迁移或清理。
2. **检查现场**：解析 repo root、absolute/common git dir、superproject、主工作区路径及起始 branch/HEAD、当前 branch/HEAD、dirty 状态、remote、远端默认分支、`git worktree list --porcelain`，以及任务相关 PR 的 head/base、冲突、checks 和可写权限。普通本地任务不隐式 fetch；PR follow-up 本身依赖当前远端状态，可更新相关 refs 并读取 PR/check 状态。
3. **取得启用选择**：只读盘点不需要确认；创建 worktree、把它作为可写工作区复用、把任务迁入其中或交给另一个 agent 前，必须得到用户明确 opt-in。若当前请求已经明确要求创建或使用 worktree，视为已选择；否则简要说明收益、成本和拟议范围，并直接询问是否启用。在答案到来前保持当前 checkout，不执行 worktree 动作。
4. **选择并画出拓扑**：启用后将独立任务按 worktree 分开；依赖改动无论是否启用 worktree，都按 reviewable concern 从 trunk 向上排列。一个结果会改变上层设计时保持串行。
5. **执行最小动作**：按用户选择复用当前 checkout 或已有隔离环境；新实现从明确基准创建 branch，只有已 opt-in 才创建、进入或交接 worktree。发布前应用下方主工作区保护；不要把 `commit+push`、`提 PR` 或 `github:yeet` 当成隐式切换主工作区的授权。临时只读检查需要新 detached worktree 时也先取得选择。不要用 force 绕过 branch 占用或目标路径保护。
6. **准备和验证**：读取 `AGENTS.md` 和项目 setup，只运行相关检查；不自动复制 `.env`、凭据、ignored 文件或缓存，也不无条件安装依赖。
7. **处理 PR follow-up**：当前 workstream 已有确认过的 PR，且用户要求实现、修复、跟进或保持可合并时，按下方闭环处理范围内冲突与 CI，并把验证过的本地修复小步 commit、及时 push 到已解析的 PR head。只读诊断不获得这些写权限。
8. **处理其他远端动作**：只有用户要求发布、同步或落地 stack 时才 push、创建/修改 PR。force-push、retarget 和 merge 仍需明确授权；先解析精确 refs、PR base 和受影响层。
9. **报告并停止**：达到隔离、stack 或 PR-ready 目标后，报告拓扑、所有权、commit/push、checks 与剩余 blocker；不顺带清理、合并或改写其他 workstream。

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
- 不要求专用 stack CLI。若 `gh` 不可用，可用标准 Git 管 branch，并在 GitHub UI 创建或调整 PR；报告仍需保留 branch、base、PR 的映射。

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

- 本 skill 管 worktree 生命周期、依赖 branch/PR 拓扑，以及目标 PR 的冲突、范围内 CI 修复和 head branch 连续交付；不接管纯 review comment 处理、无关 CI、merge 决策或 release 编排。
- PR metadata、GitHub Actions logs 和 review threads 可路由到 GitHub 专项 workflow；标准 branch/PR stack 与本地 commit/push 不依赖专用 stack 工具。
- 依赖、端口、数据库和容器隔离属于项目环境。只有仓库已有明确 setup 机制时才复用，不在通用 worktree skill 中发明一套。
- Codex 托管 worktree 的 ignored 文件复制与快照由 Codex 处理；手工 Git worktree 不假设具有同样能力。

## Output

worktree 请求先报告用户是否已 opt-in；启用后报告管理者、绝对路径、基准 ref、branch/HEAD、setup 与验证。发布请求报告主工作区起始/结束 branch、owning checkout、commit、push 和 PR。stack 请求报告 owning checkout、worktree 启用状态、trunk、bottom-to-top branch 顺序和每层 PR base/head。PR follow-up 报告冲突状态、失败 checks 与判断、创建的 commit、push 目标、重新检查结果和 blocker。清理请求报告保留与可安全移除的精确目标。
