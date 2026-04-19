---
name: modern-python
description: 用现代 Python 工具链（uv、ruff、ty）初始化或改造项目：生成/调整 pyproject.toml、本地检查命令、预提交与 CI 模板；按项目最低版本（默认 >=3.12，尽量用最新稳定小版本）从 3.12 起叠读各版 What's New 以利用新特性。应在「新建 Python 项目」「写独立脚本要可维护」「统一 lint/format/类型检查」或用户提到 uv/ruff/ty/Python 工程化时加载；与 tech-preferences 的 Python 基线一致，本 skill 负责落地步骤与文件内容。
---

## 目的

把 Python 仓库收敛到 **单一配置源（`pyproject.toml`）**、**快的 lint/format（ruff）**、**快的类型检查（ty）**、**统一的依赖与虚拟环境（uv）**，并把同样命令接到本地钩子与 CI，减少「每人一套命令」的摩擦。

## 不适用

- 仅改一两个文件且无意动工具链。
- 主要任务是业务/产品设计而非工程化（除非用户点名要工程化）。

## 与 `tech-preferences` 的关系

本仓库的横切偏好已约定：**uv**（包与虚拟环境）、**ruff**（lint + format）、**ty**（类型检查）、**prek**（预提交钩子，替代 pre-commit 的常见选型）。本 skill 给出**可执行的落地步骤**；若与 `tech-preferences` 冲突，以用户当次指令为准。

---

## Python 版本与新特性

- **默认下限**：`project.requires-python` 宜为 **`>=3.12`**（除非用户或上游约束更旧）。
- **尽量用新**：在兼容依赖的前提下，本地与 CI 优先使用**当前目标范围内的最新稳定小版本**（例如下限 3.12 时可用 3.12.x 最新；若项目明确以 3.13 为下限，则用 3.13.x 最新），并与 `uv python pin`、测试镜像一致。
- **按下限叠读 What's New**：设项目支持的最低版本为 **N**（如 3.12、3.13），写代码与评审时应对 **3.12 起至 N 的每个小版本** 阅读官方 *What's New*，以便主动用上该范围内的新语法与标准库变化。
  - 例：仅支持到 **3.12** → 至少读 [3.12](https://docs.python.org/zh-cn/3.12/whatsnew/3.12.html)。
  - 例：最低 **3.13** → 读 [3.12](https://docs.python.org/zh-cn/3.12/whatsnew/3.12.html) 与 [3.13](https://docs.python.org/zh-cn/3.13/whatsnew/3.13.html)。
  - 例：最低 **3.14** → 依次读 3.12、3.13、3.14（依此类推）。
- **与工具对齐**：`[tool.ruff]` 的 `target-version`（及 ty 的 Python 目标）应与**实际检查的版本**一致，通常取 `requires-python` 的下界或团队统一的目标特性版本，避免 lint/类型与运行时假设脱节。

---

## 工具分工（简表）

| 能力 | 工具 | 备注 |
|------|------|------|
| 依赖解析、锁文件、`venv`、运行工具 | **uv** | 替代 `pip install` / `poetry` 的日常路径 |
| Lint + format | **ruff** | 替代 `flake8` + `black` + 大量 isort 等拼盘 |
| 类型检查 | **ty** | 与 ruff 同属 Astral 生态；替代多数 `p'y'ri'g'h't` 场景前先评估边界 |
| 测试 | **pytest** | 与仓库偏好一致；本 skill 不展开测试写法 |

---

## 新项目 / 空目录脚手架

1. **初始化**（在目标目录执行）：
   ```bash
   uv init
   ```
   需要应用模板时可用 `uv init --lib` 等；以 `uv init --help` 为准。

2. **把 Python 版本写死**（推荐）：在 `pyproject.toml` 的 `project.requires-python` 写明范围（默认下限 **3.12**，见上节），并用 `uv python pin` 固定本机/CI 解释器版本，避免漂移。

3. **依赖**：
   ```bash
   uv add <runtime-dep>
   uv add --dev ruff pytest
   # ty：按 Astral 文档选择包名/版本；通常作为 dev 依赖
   ```

4. **在 `pyproject.toml` 配置 ruff 与 ty**（见下节「配置片段」）。

5. **脚本入口**：优先用 `project.scripts` 或 `uvx`；单文件脚本可配合 `uv run` 与显式 `requires-python`。

6. **本地一键检查**（在 `[tool.uv]` 或 README/just 里固化）：
   ```bash
   uvx ruff check .
   uvx ruff format --check .
   uvx ty check .
   uvx pytest
   ```

---

## 独立脚本（单文件或小型目录）

- 用 `uv init` 在脚本目录生成最小 `pyproject.toml`，或手写 `[project]` + `[dependency-groups]` / dev deps。
- 用 `uv run script.py` 保证使用项目解释器与依赖；避免「系统 python + 随手 pip」。
- 需要可复现时：提交 `uv.lock`（团队/CI 场景），并在 README 写 `uv sync` + `uv run …`。

---

## 配置片段（放入 `pyproject.toml`）

以下数值为**起点**；按项目调整 `target-version`、规则集与排除路径。`target-version` 须与「Python 版本与新特性」一节一致（通常对齐 `requires-python` 下界或团队统一目标版本）。

### Ruff（示例）

```toml
[tool.ruff]
line-length = 100
src = ["src", "packages", "tests"]
target-version = "py313"  # 与 requires-python / 团队目标版本一致；默认下限 3.12 时可改为 "py312"

[tool.ruff.lint]
select = [
  "F",
  "SIM",
  "UP",
  "FA",  # flake8-annotations
  "I",  # isort
  "B",  # flake8-bugbear
  "C4",  # flake8-comprehensions
  "PGH",  # pygrep-hooks
  "RUF",
  "E",  # pycodestyle
  "W",  # pycodestyle
  "YTT",  # flake8-2020
  "D",  # pydocstyle
]
ignore = ["D100", "D104", "D105", "D107"]

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.ruff.lint.isort]
known-first-party = ["volvox"]

[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]
"tests/**" = ["D"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "auto"
```

常用命令：

```bash
uvx ruff check . --fix
uvx ruff format .
```

### ty（示例）

键名与规则以 [Astral ty 文档](https://docs.astral.sh/ty/) 为准。常用两段：**检查范围**（`[tool.ty.src]`）与**规则级别**（`[tool.ty.rules]`）；也可使用独立 `ty.toml` 或用户级配置。

```toml
[tool.ty.src]
include = ["src", "tests"]
exclude = ["src/generated"]

[tool.ty.rules]
# unused-ignore-comment = "warn"
# all = "error"
```

命令：

```bash
uvx ty check .
```

若 ty 与项目布局不兼容，在响应中**明确写出**保留 pyright 的原因与配置位置。

---

## 预提交与 CI

### 预提交（本仓库偏好：prek）

与 `tech-preferences` 对齐时：用 **prek** 配置在提交前跑 `ruff`、`ty`、`pytest` 中与团队约定的子集。若用户环境无 prek，可暂用 **pre-commit** 或直接依赖 CI，并在文档中说明差异。

最小思路：**同一组命令**在本地钩子与 GitHub Actions 中各跑一遍，避免「本地绿、CI 红」。

### GitHub Actions（示例骨架）

```yaml
# .github/workflows/python-check.yml
name: python-check
on:
  push:
    branches: [main]
  pull_request:

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
      - run: uv sync --all-groups
      - run: uvx ruff check .
      - run: uvx ruff format --check .
      - run: uvx ty check .
      - run: uv run pytest
```

按项目替换分支名、是否 `--all-groups`、是否缓存 uv 等。

---

## Agent 执行清单

接到相关任务时，按顺序完成并能在回复中**逐条对应**：

1. 确认目标：新仓库 / 脚本 / 迁移 / 仅 CI。
2. 读现有 `pyproject.toml` 与锁文件；识别旧工具残留配置。
3. 确认 `requires-python` 下限（默认 **>=3.12**）与是否采用最新稳定小版本；按「Python 版本与新特性」列出应阅读的 What's New 版本区间（3.12 起至该下限）。
4. 给出或修改 `pyproject.toml` 片段（`[project]`、`[tool.ruff]`、`[tool.ty]`、可选 `[tool.pytest.ini_options]`），保证 ruff/ty 的目标版本与上一致。
5. 给出本地验证命令（`uv sync`、`ruff`、`ty`、`pytest`）。
6. 若需 CI：添加或更新 workflow；若需钩子：prek 或等价方案。
7. 若存在类型检查迁移或双工具并行，说明**临时双跑**策略及退出条件。

---

## 参考链接

- [uv](https://docs.astral.sh/uv/)
- [ruff](https://docs.astral.sh/ruff/)
- [ty](https://docs.astral.sh/ty/)
- What's New（中文）：自 [3.12](https://docs.python.org/zh-cn/3.12/whatsnew/3.12.html) 起按小版本叠读至项目下限，例如 [3.13](https://docs.python.org/zh-cn/3.13/whatsnew/3.13.html)；更高版本用 `https://docs.python.org/zh-cn/3.x/whatsnew/3.x.html` 替换 `3.x`。
