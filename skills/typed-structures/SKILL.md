---
name: typed-structures
description: >-
  编写、迁移或审阅 Spore Notation / typed-structures 的 ADT、定律、方法、Self、
  精化、值索引示例与子类型命题；用 Ohm 检查这份设计稿的句法。
  适用于 def fn、def law、method、Functor/Applicative/Selective/Monad 与 Sequence 的记法设计。
  不用于现有 Spore 编译器的工程实现；类型、证明与契约实例化尚不能由本识别器核验。
---

# Typed structures

维护这份语言设计稿的程序与说明。它采用 `type`、`case`、`fn`、`law`、`def fn`、`def law`、`method` 和 `<:`。没有与本稿对应的类型检查器或证明内核。

## 工作方式

- 写程序前读取 [grammar.ohm](grammar.ohm) 和 [examples.md](examples.md) 的相关主题；示例按依赖顺序共享背景，不必为一个小改动加载所有证明。
- 沿用下列已确定规则。用户提出新设计时区分现有规则与提案；不要为了迎合旧例子恢复已废弃的语法。
- 新写或改写的程序先写入文件并通过 Ohm 识别，再交付。审阅还须检查成员域、Self、law 与子类型观察；识别器不负责这些义务。
- 报告实际完成的检查和仍未确定的语义。用户明确要求其他语言实现时遵从目标，不能以本 skill 阻止转换，也不能把该实现的测试结果算成本稿的机器证明。

## 声明与补全

| 类型体中的形式 | 含义 |
| --- | --- |
| `field: T;` | 实例数据字段要求 |
| `fn f(x: A) -> B;` | 实例函数字段要求，只有签名 |
| `law p(x: A) -> (P);` | 实例证据字段要求 |
| `name[: T] = expression;` | 固定的类型预定义 |
| `def fn f(x: A) -> B { body }` | 固定的普通类型函数 |
| `def law p(x: A) -> (P) { evidence }` | 固定的类型侧证明 |
| `method m(x: A) -> B { body }` | 实例侧绑定方法，必须有 body |

- `method` 已隐含提供定义，不写 `def method`，也不允许无 body 的方法声明。普通函数和方法可以省略返回标注以推断结果；law 明确写出证明目标。
- 不使用 `static`、独立的 `proof` 声明、裸 `def f`、`:=` 或 `#` 方法调用。定义与构造补全统一用 `=`；本稿没有可变赋值。
- 没有实例字段默认值：`step: Int = 1;` 是类型预定义，不能在构造时覆盖。
- 记录构造 `T { field = expression, ... }` 与关系补全只填写实例要求。函数与证据用 lambda 提供，不在补全块里重新声明 `def fn` / `def law`。
- 没有 case 的 type 是记录；有 case 时选择一个分支。构造时提供公共实例字段和所选分支的字段。分支专有字段只能在匹配后使用；固定预定义和方法不参与构造补全。

## 成员与 Self

- `T.name` 查找类型预定义；`value.name` 查找实例字段或绑定方法。两域各自查找，不回退。允许 `T.map` 与 `value.map` 同名；同一实例域的字段与方法不能同名，类型域也没有一般重载集合。
- `.` 先选择成员，`()` 再应用所得函数；`x.map(f)`、`(x.map)(f)` 与先保存 `bound = x.map;` 再调用的绑定规则一致。
- 函数字段直接给出保存的函数，不额外绑定接收者。方法取值时保存一次求值后的接收者，调用时才执行 body。method 不自动产生一个 `T.m` 普通函数入口。
- 方法参数表省略 `self: Self`。字段显式写 `self.field`；裸名字只查参数、局部绑定与外层词法定义。普通函数没有隐式 self，但 lambda 可以捕获已有 self。
- `Self: Type` 是当前完整类型：Counter 中为 Counter，Option[A] 中为 Option[A]。禁止 `Self[A]` / `Self[B]`；变参结果仍写 Option[B]。`Self.member` 访问类型预定义。
- 对抽象 Self 成立的固定方法与证明可在子类型实例化复用；返回 Self 必须保持子类型全部要求。不得把任意 `T -> T` 自动收窄为 `S -> S`。向上按 T 视图使用后，Self 按 T 实例化，不恢复隐藏的源类型。
- 内层类型建立自己的 Self；类型体外的关系补全和 when 不因出现 self 就引入 Self。关系块的 self 是源值，when 的 self 是基础值。
- law 可依赖此前声明的字段，构造证据按最终填写的字段实例化；这不为证据字段调用添加接收者。

## 函数、定律与子类型

- `[A, B]` 默认绑定类型；值索引标注 `n: Nat`。`Type` 不意味着 `Type : Type`。
- 多参数函数不自动柯里化；`(A, B) -> C` 与右结合的 `A -> B -> C` 用显式 curry / uncurry 对应，不自动拆包元组。`map` 的类型侧先接收变换函数，实例侧先绑定被映射值；两者都叫 map。
- 背景采用不可变值、纯全函数、数学 Int/Nat 与结构递减递归。`==` 返回 Bool，`~=` 构造命题。
- 证明只使用已说明的背景：定义归约的 refl、symm、trans、congr_arg、funext、match 与结构归纳；空 match 消去无构造器类型。仅写命题或跑有限测试不是证明。
- `S <: T` 在命题位置表达关系；关系声明可用块补全目标字段与 law，或在证据充分时写 `S <: T;`。泛型关系用 `forall[...] { ... }`；`type S <: T { ... }` 继承要求与固定成员。
- 值类型关系需要保持源观察的规范视图。目标 law 成立与保持源观察是两项义务；普通转换函数不足以建立子类型。多路径必须有一致的计算解释，不能按名字或导入顺序选择不同实现。
- 参数逆变、结果协变；嵌套箭头逐层算方向。先按相同实现实例化 Self，才能比较相关签名。map 的结果协变不授权 ap 缩窄容器输入，也不授权 bind 缩窄回调允许返回的计算结构。
- `type Positive = Int when self > 0;` 表示基础值及条件证据；布尔条件 b 展开为 `b ~= true`。精化弱化须保持基础值。

## 句法验证

用全局 `@ohm-js/cli` 的 `ohm match` 对照本目录的 grammar.ohm。精确参数从当前 `ohm --help` 和 `ohm match --help` 获取。缺失时优先用 pnpm 全局安装 `@ohm-js/cli`；报告缺少 ohm-js 时再补同名依赖。默认不向目标项目或 skill 加依赖；用户明确指定其他运行方式时按其选择。

验证单位是 Module，即一串顶层声明；单独表达式需包进值定义。原样引用已有示例和只解释短名字不要求重新运行。修改文法或示例后，把所有 `spore` 围栏代码块按顺序抽出并拼接，交给识别器；运行 [scripts/check-syntax.mjs](scripts/check-syntax.mjs) 同时验证示例和语法反例。脚本直接调用 Ohm CLI，可用 OHM_BIN 指定可执行文件路径。

Ohm 的退出码 0 只表示句法符合文法。报告错误时保留 Line / Expected 诊断；未通过的程序不能作为已验证结果。`Self[B]`、同名成员冲突、覆盖预定义、错误 refl、GADT 索引不符等即使被识别也要在语义审阅中拒绝。

## 仍未确定

`:>` 暂不使用。`Monad <: Selective <: Applicative <: Functor` 表达同一类型族上的契约增强方向；Option 示例给出各层操作和 law。如何实际声明这四份泛型契约，以及 `Option <: Monad` 如何绑定整份契约的类型族，仍在讨论。不要恢复 `Functor[Option]` 证书模型，也不要自行加入 `for F`、Family 或 Self[B] 来补这个缺口。

完整宇宙系统、类型推断、递归接受条件、规范视图的核心展开与跨模块一致性、一般重载、效果和存储模型也未确定。识别文法不替这些设计问题作决定。
