---
name: agent-cli-toolkit
description: 给 agent 的现代 CLI 工具使用指南；已安装工具：bun、uv、bat、fd、rg、sd、ast-grep、lsd、bottom、dust、procs、git-delta、difftastic、hyperfine、jq、fzf、duf、git-lfs、httpie。
---

## 目的

当任务需要在终端里浏览代码、改写文本、查看 diff、排查系统状态、调用 HTTP API 或管理大文件时，优先使用这组现代 CLI，而不是退回到更原始或更低效的命令。

## 工具总览

### 代码与文件

- `rg`：全文搜索首选；替代笨重的 `grep -R`。
- `fd`：按名字找文件/目录；替代 `find` 的常见场景。
- `bat`：带行号和高亮地查看文件；适合快速人工检查。
- `sd`：批量文本替换；比 `sed` 更适合简单改写。
- `ast-grep`（`sg`）：做结构化代码搜索或批量改写。
- `lsd`：更易读的目录列表和树形视图。

### Git 与 diff

- `git-delta`（`delta`）：更易读的 diff 输出。
- `difftastic`（`difft`）：语法感知 diff，适合看代码结构变化。
- `git-lfs`：仓库里有大文件或 LFS 指针时使用。

### API、数据与筛选

- `httpie`（`http`）：调试 HTTP API。
- `jq`：解析、过滤、格式化 JSON。
- `fzf`：在大量候选项里做交互式筛选。

### 性能与系统观测

- `hyperfine`：对两个或多个命令做基准对比。
- `bottom`（`btm`）：交互式看 CPU / 内存 / 进程。
- `procs`：更友好的进程查看。
- `dust`：看目录体积构成。
- `duf`：看磁盘占用。

### 语言工具链

- `bun`：安装或执行 JavaScript / TypeScript CLI。
- `uv`：Python 依赖、虚拟环境与工具安装首选。

## Agent 使用规则

1. 搜代码优先 `rg`，找文件优先 `fd`，不要默认回退到 `grep -R` 或复杂 `find`。
2. 做简单文本替换时优先 `sd`；需要理解语法树时切到 `sg`。
3. 看 JSON 响应时总是配合 `jq`，避免肉眼硬读一整行。
4. 比较实现差异时，先尝试 `delta` 或 `difft`，再决定是否需要更深入的人工阅读。
5. 涉及性能判断时，用 `hyperfine` 拿真实数据，不靠感觉。
6. 遇到大文件、磁盘或进程问题时，优先用 `dust`、`duf`、`procs`、`btm` 获取现场信息。
7. `fzf`、`btm` 这类交互式工具只在当前终端可交互时使用；自动化脚本里优先选非交互命令。

## 常用命令模板

### 搜索与浏览

```bash
rg "TODO|FIXME" .
fd "install" skills
bat --style=plain --paging=never install.sh
lsd -la
```

### 替换与结构化搜索

```bash
sd "old_value" "new_value" path/to/file
sg --lang python -p 'print($X)' src
```

### HTTP 与 JSON

```bash
http GET :3000/health
http POST :3000/api/tasks name=demo done:=false
http GET :3000/api/tasks | jq
```

### Diff 与大文件

```bash
git diff -- . ':(exclude)dist' | delta
difft path/to/old-file path/to/new-file
git lfs ls-files
```

### 观测与基准

```bash
hyperfine 'rg agent skills' 'fd agent skills'
procs rg
dust .
duf
```

## 选择建议

- 只改字面文本：`sd`
- 要按语法节点查/改代码：`sg`
- 查 API：`http` + `jq`
- 查性能：`hyperfine`
- 查磁盘和进程：`dust` / `duf` / `procs` / `btm`
- 查 Git 变更可读性：`delta` / `difft`
