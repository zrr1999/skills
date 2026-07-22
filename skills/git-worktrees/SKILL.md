---
name: git-worktrees
description: >
  使用 Git worktree 为并行开发、PR/分支验证、多个 agent 或长任务创建和管理隔离工作区，并把 worktree 统一放在 `~/.agents/worktrees`。适用于创建、查找、进入、迁移、修复或安全清理 worktree，以及处理“branch already checked out”问题。先识别 Codex 等平台托管的 worktree，避免重复创建或越权清理；不要用于普通分支切换、复制仓库、合并编排，或未经确认丢弃脏工作区。
---

# Git Worktrees

## Goal

为并行任务提供可定位、可验证、所有者清晰的 Git 工作区。完成时应说明 worktree 的绝对路径、分支或 detached 状态、管理者、基准提交、验证结果，以及仍需人工处理的改动或清理条件。

## Directory policy

统一根目录是 `~/.agents/worktrees`。本 skill 创建的路径使用 `<forge>/<owner>/<repo>/<task>`；优先从规范化后的远端 URL 得到 `forge/owner/repo`，没有远端时使用 `local/<repo>-<common-dir-short-hash>`。`task` 使用短而稳定的任务或分支 slug；斜杠等路径分隔符改为连字符。目标路径必须解析到统一根目录内，且不得覆盖现有路径。

Codex 等平台托管的 worktree 也可以使用这个根目录，不再按 app 划分子目录。管理权不能只靠路径判断：先结合当前平台能力、Git worktree 元数据和任务上下文识别所有者。平台托管 worktree 由平台负责快照和自动清理，skill 不手工移动、删除或 prune；原生 Git 创建的 worktree 则没有平台快照或自动清理保证。需要统一 Codex 路径时，通过 Codex 的 **Settings > Worktrees > Worktree root** 指向 `~/.agents/worktrees`。

这个目录是本机运行状态，不是配置事实源。不要把它纳入 Git、云盘或跨机器同步；每台机器独立创建。Git 自身的 `git worktree list --porcelain` 是单个仓库的权威状态，不另建全局 registry。

## Discover the local interface

先确认本机 Git 版本，并从当前版本发现与目标相关的语法：

```text
git --version
git worktree --help
git worktree list --porcelain
```

需要 add、remove、move、lock、prune 或 repair 时，继续读取对应 help；不要凭记忆猜本机 flags。脚本或解析场景优先使用稳定的 porcelain 输出。

## Workflow

1. **确认目标**：区分新任务、既有分支或 PR 的隔离验证、只读实验、查找现有 worktree、迁移、修复或清理。普通单分支工作不主动创建 worktree。
2. **检查仓库现场**：解析 repo root、absolute git dir、common git dir、superproject、当前 branch/HEAD、工作区状态和 `git worktree list --porcelain`。在 submodule 中不要只根据 git dir 不同就误判为 linked worktree。
3. **识别管理者**：如果已经位于 linked worktree，默认复用当前隔离环境。平台提供了原生 worktree/handoff 能力时，遵守平台生命周期，不在背后再建、搬或删一个 Git worktree；不要根据统一根目录下的路径名猜管理者。
4. **解析目标路径和 ref**：先检查目标分支是否已被其他 worktree 占用，再确定基准 ref、是否创建新分支，以及统一根目录下的唯一目标路径。不要隐式 fetch；只有用户要求最新远端状态或当前任务确实依赖它时才更新远端引用。
5. **执行最小动作**：新实现通常从明确的基准创建有意义的新分支；临时检查可使用 detached HEAD。不要用 force 绕过同一分支只允许一个 worktree 或目标路径已占用的保护。
6. **准备和验证**：读取仓库内 `AGENTS.md` 和项目说明，只运行当前任务需要的 setup 与基线检查。不要自动复制 `.env`、凭据、ignored 文件或本地缓存，也不要无条件安装依赖。
7. **报告并停止**：验证路径、branch/HEAD、工作区状态和必要的项目基线。达到隔离目标后停止，不顺带合并、提交、推送或清理其他 worktree。

## Creation boundaries

- 一个可写 worktree 同时只交给一个 agent 或一个明确任务；多个 agent 不共享同一个可变 checkout。
- Git refs 和对象库在 worktree 间共享。创建、重置或删除分支会影响同仓库的其他工作区，因此分支动作必须属于用户请求。
- 如果目标分支已在另一个 worktree，优先返回其路径并复用；确需独立只读验证时可从同一提交创建 detached worktree，不强制重复 checkout 该分支。
- 主工作区的未提交和 ignored 文件不会由原生 Git 自动进入新 worktree。若任务依赖这些内容，先说明缺口并取得明确处理方式；不自动 stash、复制秘密或伪装成相同环境。
- 创建失败且隔离是任务前提时停止并报告 blocker；不要悄悄退回用户当前 checkout 开始修改。

## Cleanup and migration

清理和迁移是独立的破坏性流程，先只读盘点，再执行单个明确目标：

1. 确认目标不是 main worktree、当前工作目录、平台托管目录或仍被运行中任务使用的目录。
2. 检查 tracked、untracked、ignored 相关风险，以及分支相对 upstream/目标分支的未推送或未合并提交。无法证明可丢弃时停止。
3. 正常清理使用 Git 的 worktree remove 机制；不使用 `rm -rf`，不默认 force，也不顺带删除分支。
4. prune 只清理已经缺失的 worktree 元数据；先 dry-run，再针对当前仓库执行。它不是删除活跃 worktree 的工具。
5. 已有 worktree 不因目录规范而自动搬迁。用户明确要求迁移时，逐个检查 dirty、locked、submodule 和平台所有权，再使用 Git 的 move/repair 能力并验证两端链接。

如果用户确实要求丢弃 dirty worktree 或未合并分支，应再次解析精确路径和 ref，明确说明不可恢复内容，并取得针对该目标的确认后才使用 force 或删除分支。

## Boundaries

- 本 skill 管隔离 checkout 与其生命周期，不承担 branch/PR stack、merge、rebase、cherry-pick、发布或 CI 编排；这些动作使用 Git/GitHub 对应工作流。
- 依赖、端口、数据库和容器隔离属于项目环境。只有仓库已有明确 setup 机制时才复用，不在通用 worktree skill 中发明一套。
- Codex 托管 worktree 的 ignored 文件复制与快照由 Codex 处理；手工 Git worktree 不假设具有同样能力。

## Output

创建或迁移请求报告：管理者、绝对路径、源仓库、基准 ref、branch/HEAD、setup 与验证结果。盘点或清理请求报告：候选路径、dirty/locked/branch 状态、是否安全移除，以及因未推送改动、平台所有权或运行中任务而保留的目标。
