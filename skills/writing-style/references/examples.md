# 样文、编辑建议与参考来源

## 证据状态

样文读取于 2026-09-07，来自博客提交 `6a5e45460e665fd1ace39a10eba9e8b6d40fb77c`。以下引用保留原文；所有“建议改写”都是本次编辑提案，尚未经过用户逐句认可。主要样文的人工比例判断来自用户；其他文章不据措辞判断来源。

源码链接固定在该提交，避免改写后的文章反过来成为本次提炼的证据：

- [高考数学](https://github.com/zrr1999/zrr.dev/blob/6a5e45460e665fd1ace39a10eba9e8b6d40fb77c/apps/blog/data/blog/_math/gaokao-math-formulas.md)
- [Linux 网关](https://github.com/zrr1999/zrr.dev/blob/6a5e45460e665fd1ace39a10eba9e8b6d40fb77c/apps/blog/data/blog/_homelab/linux-gateway.md)
- [Incus 操作笔记](https://github.com/zrr1999/zrr.dev/blob/6a5e45460e665fd1ace39a10eba9e8b6d40fb77c/apps/blog/data/blog/_homelab/incus-qcow2.md)
- [__eq__ 的返回类型与里氏替换原则](https://github.com/zrr1999/zrr.dev/blob/6a5e45460e665fd1ace39a10eba9e8b6d40fb77c/apps/blog/data/blog/_language/eq-type-lsp.md)
- [有理分式：改写前版本](https://github.com/zrr1999/zrr.dev/blob/6a5e45460e665fd1ace39a10eba9e8b6d40fb77c/apps/blog/data/blog/_math/rational-decomposition.md)

## 围绕用途判断，避免给读者贴标签

高考数学原文：

> 推荐高手学习的公式定理方法

> 高考一般用不到。

观察：作者关注投入学习后是否实际有用，愿意直接作取舍。问题：读者标签没有说明所需知识；考试适用性也受年份和地区影响。

建议改写章节标题为“需要额外知识的方法”，并在具体方法下说明前置知识和用途。对考试风险只保留有依据、限定时地的说法；本次未核查当前考试评分要求，不提供替代性的评分保证。

原文还将帕德逼近引用为“第14条”，实际位于第 13 项。应直接引用方法名称，避免手写序号漂移。这是维护缺陷，不是文风。

## 由真实需求说明个人取舍

Linux 网关原文：

> 一方面是各种插件的配置文件散落在系统的各个位置，不利于维护和备份，
> 另一方面是 OpenWRT 本身阉割了很多 Linux 的功能，比如我一直没有找到方法用 VSCode 连接 OpenWRT 的方法。

观察：选择来自可说明的维护需求，值得保留。问题：个人未找到连接方式不能证明系统普遍缺失某项能力，句子也重复“方法”。

建议改写：

> 当时我主要遇到两个问题：插件配置分散，不方便维护和备份；我也没有找到用 VS Code 连接 OpenWRT 的合适方法。因此，我想把这些服务迁到自己熟悉的 Linux 环境中。

保留过去体验与动机，不声称 OpenWRT 无法连接 VS Code。原文关于 iKuai 与 OpenWRT 性能、稳定性的宽泛比较需要另行证据，不在风格示例中补造结论。

## 把前提放到使用处

Linux 网关先给出了 `makepkg -si`，随后才写：

> 由于 paru 需要使用非 root 用户，所以需要创建一个非 root 用户，然后使用这个用户安装其他所需要的包：

建议：将构建 paru 的用户前提移到对应操作之前，并区分系统安装步骤与普通用户构建步骤。这里指出顺序问题，不把原命令块当作已在当前系统验证的安装方案。

## 允许短笔记直接进入操作

Incus 原文：

> 许多系统官方只给了 qcow2 镜像的格式，我们需要一些处理才能导入 incus，以下以 Home Assistant OS 为例。

随后是下载镜像、创建元数据和导入三个步骤。值得保留的是目标与例子相邻、步骤围绕任务组织。改进时补确有必要的环境前提或检查，不为凑教程结构添加“优势”“应用场景”“总结”。这不能作为数学推导也应如此简短的依据。

## 比较写清代价，避免多次重述

`__eq__` 文章分别设置“三种类型标注的取舍”“object.__eq__ -> Any 的问题”“结论”。观察：作者通过替代方案讨论代价。问题：表格、其后解释与结论重复了多次相同取舍。

建议：表格承担比较索引；正文只展开需要推理的差异；结尾保留适用条件或作者判断。不把该文关于当前类型生态的陈述当作已核实事实，本例只分析组织方式。

## 完整改写验证：有理分式

此文作为应用案例，不参与正面风格提炼；原文明示的 AI 辅助段落不能反过来定义作者声音。

### 开篇：明确要解决的计算问题

原文：

> 然而，对于分母含有二次式的情况，教科书上却鲜有提及。

建议改写：

> 遇到二次因子时，我更关心的是：能不能也少解一些联立方程？

依据：原文已经表达寻找快捷方法的动机。修改去掉无法由本文支持的教科书覆盖率断言，将问题落到计算方法；不增加经历或原创性声明。

### 推导：删除重复算术，保留决定结论的步骤

原稿反复区分 `c=0` 与 `c≠0`，求 A 时建议再选值代入。建议先列通分后的系数关系，得到 `A=d-C`、`B=e+cA-aC`；原来的 `B=(Cb-f)/c` 保留为 `c≠0` 时的另一条关系。

这减少了重复，同时补上理由。不能只删掉分类却不给统一方法，也不能保留原稿中从无 A 的等式“求出 A”的错误。

### 结尾：以可验证的应用结果结束

原文：

> 所有方法都有严格的数学证明支持

> 特别是情况二的快捷公式可以显著提高计算效率。

建议以修正后的拉普拉斯反变换和回代检查结束正文，再列参考资料。删掉没有完整证明或效率比较支持的总结，不添加“工具箱更完备”等收尾。

## 外部资料的采用与取舍

以下原始文件均在 2026-09-07 实际读取。只借鉴编辑判断与资料组织，不复制原文、不加载它们的仓库专用流程，也不把它们设为运行依赖。

| 原始资料 | 本版采用 | 本版不采用 |
| --- | --- | --- |
| [writing-style-skill / SKILL.md](https://github.com/lout33/writing-style-skill/blob/main/SKILL.md) | 入口与风格档案分开，示例帮助理解偏好 | 泛化到所有文本；无论请求如何都不解释修改 |
| [dsh-prose-standard / SKILL.md](https://github.com/deepseek-ai/deepseek-harness/blob/master/.agents/skills/dsh-prose-standard/SKILL.md) | 编辑前辨认命题，保留条件、时序、例外和后果，必要时补充解释 | 仓库排除目录、专有工作流；把博客教学背景一律外链。默认分支为 master，最初尝试 main 返回 404，已纠正 |
| [blog-style / SKILL.md](https://github.com/AgriciDaniel/claude-blog/blob/main/skills/blog-style/SKILL.md) | 通过一组代表性文章维护风格档案 | 以平均句长、第一人称率和触发词频作为写作目标；不引入该项目的运营系统 |
| [digital-brain / identity/voice.md](https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering/blob/main/examples/digital-brain-skill/identity/voice.md) | 共同行为、文体适配、样例与反例分开 | 人格数字评分、固定钩子与 CTA；原文件是模板，不是已有作者风格 |
| [humanizer / SKILL.md](https://github.com/blader/humanizer/blob/main/SKILL.md) | 检查机械结构、无信息收尾、夸张断言；保留真实的个人选择 | 添加作者反应；把句式当 AI 来源鉴定；仅允许改 prose 而冻结已证实错误的公式或代码 |

本地 skill-creator 用于范围、引用和结构校验；git-workstreams 用于本次仓库交付。它们不是个人文风的证据，也不是使用本 skill 时必须加载的依赖。
