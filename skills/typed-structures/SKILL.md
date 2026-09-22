---
name: typed-structures
description: >-
  编写、迁移或审阅 Spore Notation / typed-structures 的宇宙、范畴、分支类型、static 成员、
  构造、定律、方法、Self、精化、值索引与子类型示例；用 Ohm 识别设计稿的句法。
  适用于 Category、Functor/Applicative/Selective/Monad、Option 与 Sequence 的记法设计。
  不用于现有 Spore 编译器的工程实现；识别器不能核验类型、证明或结构归属。
---

# Typed structures

维护 Spore Notation 语言设计稿。理论结构与实际数据结构一起引入，并提供操作和 law 证据；没有对应的类型检查器或证明内核。

## 工作方式

- 从 [examples.md](examples.md) 选择相关章节：01 定义、宇宙与分支，02 子类型，03 精化，04 范畴与元组，05 计算结构与 Option，06 序列，07 映射，08 索引类型。按依赖顺序共享背景，不为小改动加载全部证明。
- 写程序时以以下规则为准，对照 [grammar.ohm](grammar.ohm) 检查表面形式。用户提出新设计时区分既有规则与提案，不为兼容旧例子恢复废弃语法。
- 新程序写入文件做句法检查，再审阅宇宙、态射起终点、泛型位置、Self、成员归属与 law。用户明确要求其他语言实现时遵从目标；该实现的运行结果不构成本稿的机器证明。

## 宇宙与参数

- 非累积宇宙与宇宙多态：`Universe<u>: Universe<next(u)>;`、`Prop = Universe<0>;`、`Type = Universe<1>;`。首行是背景规则模式，不是 Universe 属于自身的定义。
- 层级支持 next/max，数字是 next 迭代的简写；层级不是运行时 Nat。省略层级或 `_` 产生待推断变量；声明中独立且未固定的层级可以推广，调用时实例化。不把一次推断当成任意层级通用，不自动升层或降层。
- 数据的依赖函数层级按输入与结果的 max 计算；结果是命题 P: Prop 时，对任意宇宙量化仍属于 Prop。区分 `A -> P` 与返回命题类型的 `A -> Prop`。不引入证明无关、自动擦除或任意从 Prop 向数据消去。
- `<u>` 用于层级，`[A: Type, n: Nat]` 用于泛型或索引，`(x, y)` 用于普通实参。`[A]` 默认绑定 A: Type；结构参数也放在方括号，如 `F: Functor[C,D]`。
- 普通多参数函数不自动柯里化。`(A, B) -> C` 与 `A -> B -> C` 通过显式 curry / uncurry 对应。`(pair: (A,B)) -> C` 接收一个元组，调用写 `f((a,b))`，不自动拆包或引入 `<a,b>` 实参形式。

## 分支、路径与构造

- case 声明封闭、互斥的分支子类型；点号选择分支类型，花括号构造项。`Option[Int].Some` 是类型，不是数据值或构造函数；写 `Option[Int].Some { value: 1 }`，空分支写 `Option[Int].None {}`。传递构造行为时显式写 lambda。
- 参数跟随声明位置。`type X[A] { case L; }` 使用 `X[A].L`；`case C[B]` 使用 `X[A].C[B]`。不生成 `X.L[A] = X[A].L`，省略参数或 `_` 仅在原位置推断。
- Fin、Vec、Expr 的参数声明在 case 上时，保留 `Fin.Zero[n]`、`Vec.Cons[A,n]`、`Expr.If[A]`；返回索引决定父类型。`Vec.Cons[A,n]` 属于 `Vec[A, Nat.Succ { previous: n }]`。不能把参数移动成 `Vec[A,n].Cons`。
- case 声明和匹配都使用具名字段块：`case Some { value: A; }`，`Option[A].Some { value: item } => ...`。匹配支持同名绑定 `{ value }`、嵌套模式和剩余字段省略 `{ value, ... }`。
- 公共字段沿嵌套路径累计，一次填写全部要求；有子分支的节点不能直接构造。兄弟分支不因继承成为嵌套路径。同一路径、同一成员域内禁止遮蔽和重名；类型侧与实例侧是两个成员域。
- 所有构造块统一写 `T { field: expression, ... }`，包括记录、分支、范畴结构与泛型证据，例如 `identity[X]: refl`。构造中不写字段声明、static、def fn / def law 或字段等号；后续字段可引用此前补全的字段，不引入隐式 self。
- Unit 使用空记录 `type Unit {}` 与 `Unit {}`。Nat 的背景分支形状为 `case Zero; case Succ { previous: Nat; }`，项写 `Nat.Zero {}`、`Nat.Succ { previous: n }`；保留字面量、归约和结构归纳规则。

## 成员声明与 Self

| 类型体中的形式 | 含义 |
| --- | --- |
| `field: T;` | 实例字段要求 |
| `fn f(x: A) -> B;` | 函数字段要求，核心为 `f: A -> B;` |
| `law p(x: A) -> (P);` | 证据函数要求，核心为 `p: A -> P;` |
| `law p[X] -> (P);` | 证据值族；有 `()` 才是零参数证据函数 |
| `static name: T = expression;` | 类型侧值定义 |
| `static def fn f(x: A) -> B { body }` | 类型侧普通函数定义 |
| `static def law p(x: A) -> (P) { evidence }` | 类型侧证明定义 |
| `method m(x: A) -> B { body }` | 实例侧绑定方法，必须有 body |

- 顶层定义不加 static；case 和嵌套 type 自身确定归属。类型体中的固定定义必须有 static，没有实例字段默认值。`static step: Int = 1` 不能在构造时覆盖；普通字段用冒号声明，不用等号给默认值。
- fn/law 是语法糖；def 只用于带大括号的 def fn / def law。拒绝裸 def、def method、无 body 的 method、`def law ... = ...`、独立 proof 声明、`:=` 和 `#` 方法调用。`=` 只定义名字，不表示可变赋值。
- `T.name` 取类型侧成员，`value.name` 取实例字段或绑定方法，两域不回退。可有 `SameName.value` 与 `same_name.value`；不自动生成占用静态名字的实例字段投影函数。同一实例域的字段与方法不能同名，不引入一般重载集合。
- `.` 先选成员，`()` 再应用。方法取值时保存一次求值后的接收者，调用时执行 body；不自动产生 `T.method` 普通函数入口。函数字段不额外绑定接收者。
- method 省略 `self: Self`，字段显式写 self.field；裸名字查参数、局部绑定和外层词法定义。普通函数没有隐式 self。实例 law 可依赖此前实例字段，证据按补全后的字段检查；static 不能暗中捕获实例字段。
- Self 是当前实例化的完整类型。在 Option[A] 中是 Option[A]，不能写 Self[B]；在 Functor[C,D] 中是完整的结构类型，不是 obj(A)。内层 type 建立自己的 Self，when 的 self 仅绑定基础值。
- 对抽象 Self 成立的定义和证明可在子类型下实例化。仅凭父字段不能构造任意 Self：Counter.make 返回 Counter，keep 原样返回输入 Self；next 不自动保持新增字段或约束。Self.make 不收窄父函数返回类型。
- 子类型项可以按父要求使用，但不组装新记录或恢复原始类型。需要父类型约束时显式绑定 `value: T = self;`；其方法的 Self 按已声明的 T 实例化。

## 类型项、结构与子类型

- `:` 表示归属，`<:` 表示保留父要求的类型细化，`=` 表示定义。类型、类型族和别名用大写，普通结构值用小写，泛型参数可沿用数学记号。名字不是子类型的证据；LargeCategory 和 Bifunctor 是透明别名。
- 普通结构值写 `identity_functor[C: Category]: Functor[C,C] = Functor[C,C] { ... };`。确实要定义新类型时，可用 `type Z: T { ... }`，让 Z 的 static 成员满足 T 的全部要求，另行声明 Z 实例的数据字段。
- 例如 `type Z: X[Int].L { static v: Int = 1; data: Str; }`：Z 本身属于 X[Int].L，但 `z: Z` 不因此属于 X[Int].L；`Z.v` 与 `z.data` 分层。`type Z <: T` 才是继承 T 的实例要求。01 的 ComplexUnit/TextUnit 展示类型项满足 Unit，而各自数据字段不同。
- 相等在确定的类型中判断。类型项同属 T 或在 T 中相等，不推出其数据类型相等或实例可互换。不要提供 type_of、运行时取类型、恢复原始类型或视图；泛型代码使用已声明的类型参数。
- 保留字段继承、四层计算结构继承与 case 包含。删除组装另一份结构的 `<:` 补全及专用 forall 声明；RoundTrip → Idempotent、LinkedList/VectorLayout → Sequence、BoolMap → FiniteMapping 均使用普通显式构造函数，携带操作与 law 证据，不自动插入调用。
- `type Positive = Int when self > 0` 表示基础值与条件证据，布尔条件 b 展开为 b ~= true；精化弱化使用显式函数，保留基础值。

## 范畴与计算结构

- Category<u,v> 要求 Obj: Universe<u>、Hom[X,Y]: Universe<v>，自身在 Universe<max(next(u),next(v))>。types.Obj = Type，types.Hom[X,Y] = X -> Y；对象层级为 2、态射层级为 1，因此 Functor[types,types] 在 Universe<2>。
- Functor 的 obj 是显式对象映射，不是类型反射。核对 map 的起终点与恒等、复合律。product_category 返回范畴值，pair_bifunctor 是双函子值，compose_functors 构造复合函子值。
- 自然变换 alpha 携带分量族 `alpha.app`，`alpha.app[X]` 是目标 Hom 中的一条态射；只有 Hom 确实为函数时才能写 `alpha.app[X](value)`。检查同构的正逆方向、自然性、五边形和三角形的起终点。
- `type Option[A: Type]: Monad` 同时建立数据族与全族结构：先生成数据族，再定义 static obj 对应该族，Option.obj(A) 与 Option[A] 定义相等，不循环展开或换成其他族。这是 Option 的全族规则，不把一般 `type Z: T` 限于带 obj 的结构。
- 结构操作和证据独立量化 X/Y，不捕获固定 A 或 self；Option: Monad，Option[A]: Type，但 Option[A] 和 Option[A] 的数据值都不是 Monad。全族 static 操作可经 Option 或 Option[A] 选择。
- 四层实际声明为 Applicative <: Functor[types,types]、Selective <: Applicative、Monad <: Selective，继承同一 obj/map；pure、ap、select、bind 使用该对象映射。不恢复 Option <: Functor、Functor[Option]、for F、Family 或 Self[B]。
- 核对全部证据：Functor 恒等/复合；Applicative 恒等/同态/交换/复合及 map_from_ap；Selective 恒等/分配/结合；Monad 左右单位元/结合及 ap_from_bind、select_from_bind。派生配对操作也需自然性、单位和结合证明，不写“laws 显然成立”。
- Option 的 method map 接收 A -> B，返回 Option[B]；Self.map 选择共享 static 操作，不把 Self 变成类型构造器。泛型辅助函数显式接收结构或操作，不查找隐式实例。参数逆变、结果协变不能凭 map 推导容器子类型。

## 验证

背景采用不可变值、纯全函数、数学 Int/Nat、元组与结构递减递归。`==` 返回 Bool，`~=` 构造命题。证明使用 refl、symm、trans、congr_arg、funext、match 和结构归纳；pair_congr 在 01 中定义，空 match 消去没有构造项的类型。仅写命题或跑有限输入不是证明。

使用可用的 @ohm-js/cli，从 `ohm --help` / `ohm match --help` 取得参数，对照本目录 grammar.ohm。缺失时优先用 pnpm 全局安装 CLI 及 ohm-js，不向目标项目添加依赖；用户指定临时运行或不安装时遵从。原样引用或只解释短名字，无需创建验证程序或安装工具。

识别单位是 Module，单独表达式需包进定义。修改文法或示例后运行 [scripts/check-syntax.mjs](scripts/check-syntax.mjs)，检查八组示例、顺序拼接及正反句法用例；OHM_BIN 可指定 CLI。错误保留 Line / Expected 诊断。

脚本另列能被识别、但必须语义拒绝的程序：未选分支、缺少公共字段、非法兄弟路径、泛型位置错误、分支类型当值或函数、实例回退到 static、类型项归属误用于实例、错误索引，以及自动升层、Self[B]、不完整 Self 构造、obj 错配、非函数态射应用、错误实参数量和错误 refl。它们必须另行审阅；Ohm 不决定成员解析、类型关系或证明有效性。

只报告实际完成的验证。Ohm 退出码 0、eval schema 检查或有限样例运行都不代表机器类型检查或证明核验。一般重载、类型推断算法、递归接受条件、模块、效果和存储模型仍待确定或实现。
