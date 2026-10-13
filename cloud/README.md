# 共享云开发环境

这套配置用于一个共享环境内协作 `zendev-lab/zendev`、`zrr1999/zrr.dev` 和 `spore-lang/spore-lang.dev`。工具和 skills 共用，各仓库的 `.venv`、`node_modules`、lockfile 与任务分支独立。

## 启动与维护

冷启动执行 `cloud/setup.sh`。它安装缺失的 Vite+、Python 3.12/3.13/3.14、ty、Ruff、Pyrefly、Just、prek、gh、gh-llm、fd、Zellij、ShellCheck、lychee 和 Chromium；恢复三个仓库，按各自 lockfile 安装依赖，并预热固定版本的 Typst 包。

任务开始或恢复时执行 `cloud/maintenance.sh`。它复用相同的幂等逻辑，修复缺失工具或依赖，并更新 skills。新版 Codex Cloud 的 Start skill 指示任务先执行维护，再重新读取本次需要的 SKILL.md；旧版使用维护脚本字段。不使用后台定时任务在活跃任务中替换指令。

运行时保存到以下位置：

| 内容 | 默认路径 |
| --- | --- |
| 三个仓库 | `/workspace/cloud-repos/<owner>/<repo>` |
| tools、repositories、skills 的验证状态与更新日志 | `~/.local/state/cloud-pilot` |
| 上游脚本和安装清单缓存 | `~/.cache/cloud-pilot` |
| 共用技能 | `~/.agents/skills` |
| 新 shell 的环境变量 | `~/.config/cloud-pilot/env.sh` |

`CLOUD_PILOT_ROOT`、`CLOUD_PILOT_STATE_DIR`、`CLOUD_PILOT_CACHE_DIR` 可改变前三项路径。脚本保留平台注入的代理、CA、认证和保护变量，不把凭据写入仓库。

## 自动更新范围

- 每次执行 setup 或 maintenance 查询 `zrr1999/skills` 的默认分支。安装清单变化时重新执行上游 `install.sh all`，补上新 core skills 和各可选组；随后用 skill manager 更新已登记的全局来源。
- 成功后记录安装清单的 commit SHA、skill 文件摘要和来源清单。失败时恢复此前的 skill 文件与来源 lock，保留失败副本及日志，并返回非零退出码；不会把失败标记为最新。
- 沿用上游安装器的边界：保留用户本地 skill，以及安装器已退役但未自动卸载的旧条目；不删除宿主或插件提供的技能。
- 仓库仅对干净的默认分支进行快进更新。未提交改动、任务分支和未推送提交均保留，并记录为跳过同步。依赖只在 lock/manifest 改变或缓存缺失时重新安装。
- 全局工具只安装缺失项；项目版本由仓库自己的 manifest 和 lockfile 决定。运行时脚本固定到已验证的 commit，skills 安装清单则继续跟随上游，二者可独立更新。

## 保存到平台

先将这份实现提交并推送，再生成绑定内容：

```bash
python3 cloud/render-hooks.py "$(git rev-parse HEAD)" /tmp/shared-dev-pilot
```

网页版或桌面版打开 **Settings → Codex Cloud → Environments**，点 **Create environment**；已有环境从 **… → Edit** 进入。也可在新任务中选择 **Work in → Cloud → Select environment → Create environment**。选择三个试点仓库，环境名称使用 `shared-dev-pilot`。

新版配置的 **Install script** 使用 `setup-hook.sh` 的完整内容；**Start skill** 使用 `start-skill.md` 的完整内容。Start skill 要求任务开始或恢复时先运行固定版本的维护入口、检查状态，然后重新读取更新后的技能。它是任务执行指令，不能当成平台保证执行的后台定时器。

设置 `NODE_USE_ENV_PROXY=1`、`SKILLS_AGENT=cline`、`CLOUD_PILOT_ROOT=/workspace/cloud-repos`。使用已有 GitHub 连接提供认证，不在这些文件中填写 token。

在准备会话内运行 Install script 并核对结果，保存修改后点 **Publish**；更新已发布环境则点 **Republish**。发布会捕获准备好的文件系统，新任务才能使用这份环境；已有任务继续使用自己的状态。平台的仓库后台刷新不会重新执行安装或启动命令，因而不能代替 skills 维护。

`configuration.json` 是供核对字段的清单，不是平台的导入格式，仓库里存在该文件不会自动绑定。配置保存和发布前，生成文件中的状态明确为 prepared。发布后启动一个新任务，核对维护执行记录、技能版本和三个仓库的状态，再确认平台生命周期接入成功。

新版入口、Install script / Start skill 和发布行为见[官方 Codex Cloud 文档](https://learn.chatgpt.com/docs/environments/cloud-environments)。[旧版文档](https://learn.chatgpt.com/docs/environments/cloud-environment)使用 setup 与 maintenance 脚本字段，对应生成文件中的 `setup-hook.sh` 与 `maintenance-hook.sh`。

## 验证

```bash
shellcheck -x cloud/*.sh
python3 -m unittest discover -s cloud/tests -v
prek run --all-files
```

单元测试使用真实临时 Git 仓库验证快进与工作保留，验证 skills 文件、来源 lock 和用户 symlink 的回滚，以及 Typst 的传递依赖预取和缓存复用。冷启动还需在包含 curl、git、Python 3.12+、flock 的 Linux 镜像中实际执行 setup，再执行 maintenance，并检查新登录 shell 能找到工具。Python 3.12+ 用于可靠的包解压和元数据校验。
