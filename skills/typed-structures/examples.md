# 例子

下列例子按同一模块的依赖顺序排列；后文可以引用前文。合在一起应能被 [grammar.ohm](grammar.ohm) 识别。单节不是封闭编译单元。

`proof` 是写出来的证明项，不是类型检查器给出的核验。

## 01 Option / Either：普通 ADT

`type` 含 `case` 时是选择。构造器为 `Type.Case`。

```
/// 一个可能不存在的值。
type Option[A] {
    case None;
    case Some(value: A);
}

/// 两种可能之一，不预设成功或失败的含义。
type Either[A, B] {
    case Left(value: A);
    case Right(value: B);
}

let present: Option[Int] = Option.Some(3);
let absent: Option[Int] = Option.None;
let alternative: Either[Int, Str] = Either.Right("ready");
```

## 02 带 law 的记录：没有 concept，也不引入 trait

没有 `case` 的 `type` 是记录。`fn` / `law` 待提供；`def` / `proof` 固有。`fn pure[A](value: A) -> F[A];` 与 `pure[A]: A -> F[A];` 同一字段，主例只保留前者。

```
/// 把普通函数提升到 F 上，并保持恒等与复合。
type Functor[F: Type -> Type] {
    /// 需要由结构构造或子类型补全提供。
    fn map[A, B](
        value: F[A],
        transform: A -> B
    ) -> F[B];

    /// 固定派生定义，不是可覆盖的默认方法。
    def replace[A, B](
        value: F[A],
        replacement: B
    ) -> F[B] {
        map(value, _ => replacement)
    }

    /// 恒等映射不改变原值。
    law identity[A](value: F[A]) -> (
        map(value, x => x) ~= value
    );

    /// 连续映射，与先复合函数再映射一致。
    law composition[A, B, C](
        value: F[A],
        first: A -> B,
        second: B -> C
    ) -> (
        map(map(value, first), second)
        ~=
        map(value, x => second(first(x)))
    );
}

/// 提升纯值，并组合预先给出的结构。
/// 不要求组合可交换，也不规定必须并行执行。
type Applicative[F: Type -> Type] {
    fn pure[A](value: A) -> F[A];

    fn ap[A, B](
        function: F[A -> B],
        argument: F[A]
    ) -> F[B];

    /// 用普通二元函数组合两个结构。
    def map2[A, B, C](
        left: F[A],
        right: F[B],
        combine: (A, B) -> C
    ) -> F[C] {
        ap(
            ap(pure(a => b => combine(a, b)), left),
            right
        )
    }

    /// 丢弃左侧结果值，不擅自删除左侧的结构或效果。
    def keep_right[A, B](left: F[A], right: F[B]) -> F[B] {
        map2(left, right, (_, value) => value)
    }

    law ap_identity[A](value: F[A]) -> (
        ap(pure(x => x), value) ~= value
    );

    law ap_homomorphism[A, B](
        transform: A -> B,
        value: A
    ) -> (
        ap(pure(transform), pure(value))
        ~=
        pure(transform(value))
    );

    law ap_interchange[A, B](
        function: F[A -> B],
        value: A
    ) -> (
        ap(function, pure(value))
        ~=
        ap(pure(f => f(value)), function)
    );

    law ap_composition[A, B, C](
        outer: F[B -> C],
        inner: F[A -> B],
        value: F[A]
    ) -> (
        ap(
            ap(
                ap(pure(f => g => x => f(g(x))), outer),
                inner
            ),
            value
        )
        ~=
        ap(outer, ap(inner, value))
    );
}

/// 允许后续结构依赖前一步得到的值。
type Monad[F: Type -> Type] {
    fn pure[A](value: A) -> F[A];

    fn bind[A, B](
        value: F[A],
        next: A -> F[B]
    ) -> F[B];

    /// 固有派生定义：依赖本结构的 bind，但不允许独立重选 join。
    def join[A](nested: F[F[A]]) -> F[A] {
        bind(nested, inner => inner)
    }

    /// 从纯值开始再接续，等同于直接接续。
    law left_identity[A, B](
        value: A,
        next: A -> F[B]
    ) -> (
        bind(pure(value), next) ~= next(value)
    );

    /// 原样取出并放回，不改变原结构。
    law right_identity[A](value: F[A]) -> (
        bind(value, x => pure(x)) ~= value
    );

    /// 改变接续的分组方式，不改变含义。
    law associativity[A, B, C](
        value: F[A],
        first: A -> F[B],
        second: B -> F[C]
    ) -> (
        bind(bind(value, first), second)
        ~=
        bind(value, x => bind(first(x), second))
    );

    /// 由定义直接得到的固定证明，不是新的待提供字段。
    proof join_expansion[A](nested: F[F[A]]) -> (
        join(nested) ~= bind(nested, inner => inner)
    ) {
        refl
    }
}
```

## 03 子类型：`Monad :> Applicative :> Functor`

这两条关系连接结构类型，不把 `Option` 本身当成 `Monad[Option]`。目标定律也必须有证据。较长证明在第 14 节，这里直接调用。

```
forall[F: Type -> Type] {
    /// 通过 pure、ap 补出 map，并满足 Functor 要求。
    Applicative[F] :> Functor[F] {
        def map[A, B](value: F[A], transform: A -> B) -> F[B] {
            self.ap(self.pure(transform), value)
        }

        proof identity(value) {
            self.ap_identity(value)
        }

        proof composition(value, first, second) {
            applicative_map_composition(self, value, first, second)
        }
    }

    /// 通过 bind 构造应用结构；操作与证明都来自同一份源结构。
    Monad[F] :> Applicative[F] {
        def pure[A](value: A) -> F[A] {
            self.pure(value)
        }

        def ap[A, B](
            function: F[A -> B],
            argument: F[A]
        ) -> F[B] {
            self.bind(function, f =>
                self.bind(argument, x => self.pure(f(x)))
            )
        }

        proof ap_identity(value) {
            trans(
                self.left_identity(
                    x => x,
                    f => self.bind(value, x => self.pure(f(x)))
                ),
                self.right_identity(value)
            )
        }

        proof ap_homomorphism(transform, value) {
            trans(
                self.left_identity(
                    transform,
                    f => self.bind(self.pure(value), x => self.pure(f(x)))
                ),
                self.left_identity(value, x => self.pure(transform(x)))
            )
        }

        proof ap_interchange(function, value) {
            monad_ap_interchange(self, function, value)
        }

        proof ap_composition(outer, inner, value) {
            monad_ap_composition(self, outer, inner, value)
        }
    }
}
```

## 04 Option 上的 Monad 结构值

`Monad[Option]` 来自 `Monad` 的唯一外层参数 `F = Option`。它是操作及证据的类型；`Option[Int]` 是可选整数，两者不同。不使用 `impl`，不登记全局实例。

```
let option_monad: Monad[Option] = {
    def pure[A](value: A) -> Option[A] {
        Option.Some(value)
    }

    def bind[A, B](
        value: Option[A],
        next: A -> Option[B]
    ) -> Option[B] {
        match value {
            Option.None => Option.None,
            Option.Some(x) => next(x)
        }
    }

    proof left_identity(value, next) {
        refl
    }

    proof right_identity(value) {
        match value {
            Option.None => refl,
            Option.Some(x) => refl
        }
    }

    proof associativity(value, first, second) {
        match value {
            Option.None => refl,
            Option.Some(x) => refl
        }
    }
};

// 这些是把已有值按已声明的父类型使用，不是从空上下文寻找实例。
let option_applicative: Applicative[Option] = option_monad;
let option_functor: Functor[Option] = option_applicative;

proof option_map_example() -> (
    option_functor.map(Option.Some(2), x => x + 1)
    ~=
    Option.Some(3)
) {
    refl
}

proof option_replace_example() -> (
    option_functor.replace(Option.Some(2), "done")
    ~=
    Option.Some("done")
) {
    refl
}

proof option_map2_example() -> (
    option_applicative.map2(Option.Some(2), Option.Some(3), (a, b) => a + b)
    ~=
    Option.Some(5)
) {
    refl
}

proof option_join_example() -> (
    option_monad.join(Option.Some(Option.Some(2)))
    ~=
    Option.Some(2)
) {
    refl
}

/// 从结构中取得 law 成员，就是取得对应的参数化证明。
proof option_identity_example() -> (
    option_functor.map(Option.Some(2), x => x) ~= Option.Some(2)
) {
    option_functor.identity(Option.Some(2))
}
```

## 05 公共字段 + case

构造时同时提供公共字段和分支字段。`Event :> HasId;` 是空补全：目标字段已在源结构中。数据为只读值，没有可变记录的宽度子类型规则。

```
/// 每种事件都有 id；额外数据取决于所选分支。
type Event {
    id: Int;

    case Click {
        x: Int;
        y: Int;
    }

    case Key {
        code: Str;
    }

    /// 公共固定定义；分支字段只在对应匹配中可见。
    def label() -> Str {
        match self {
            Event.Click { ... } => "click",
            Event.Key { ... } => "key"
        }
    }
}

let click: Event = Event.Click {
    id: 1,
    x: 10,
    y: 20
};

let key: Event = Event.Key {
    id: 2,
    code: "Enter"
};

/// 只要求共同的 id 观察能力，不要求知道事件的分支。
type HasId {
    id: Int;
}

Event :> HasId;

let identified: HasId = click;

proof common_field_example() -> (
    identified.id ~= 1
) {
    refl
}

/// 只有 Click 分支才产生坐标。
def click_position(event: Event) -> Option[(Int, Int)] {
    match event {
        Event.Click { x, y, ... } => Option.Some((x, y)),
        Event.Key { ... } => Option.None
    }
}
```

## 06 和 / 积嵌套

选择可以出现在字段里，记录可以出现在分支里。两个字段是两次独立选择。构造这些值不发送网络请求，也不读写文件。

```
/// 一个地址本身有多种形态。
type Endpoint {
    case File {
        path: Str;
    }

    case Network {
        host: Str;
        port: Int;
    }
}

/// 同时具有一个主地址和一个可选的备用地址。
type Route {
    primary: Endpoint;
    fallback: Option[Endpoint];
}

/// 公共请求标识 + 分支各自的数据；Routed 内部又包含记录 Route。
type Delivery[A] {
    request_id: Int;

    case Direct {
        payload: A;
    }

    case Routed {
        route: Route;
        payload: A;
    }
}

let delivery: Delivery[Str] = Delivery.Routed {
    request_id: 7,
    route: Route {
        primary: Endpoint.Network {
            host: "example.invalid",
            port: 443
        },
        fallback: Option.Some(Endpoint.File { path: "./pending" })
    },
    payload: "hello"
};

/// 两个字段是两次独立选择，不是把所有 case 混为一次选择。
type RedundantRoute {
    first: Endpoint;
    second: Endpoint;
}
```

## 07 分支中的 law

普通数据与有证据的数据不是同一分支。只有匹配 `Verified` 后才取得 `matches`。

```
/// 公共数据只写一次；Verified 分支额外携带相等证据。
type Sample[A] {
    expected: A;
    actual: A;

    case Verified {
        law matches() -> (actual ~= expected);
    }

    case Unchecked {
        note: Str;
    }

    /// 固定定义对所有分支可用，不假设具有 matches 证据。
    def value() -> A {
        actual
    }
}

let verified: Sample[Int] = Sample.Verified {
    expected: 3,
    actual: 3,

    proof matches() {
        refl
    }
};

let unverified: Sample[Int] = Sample.Unchecked {
    expected: 3,
    actual: 5,
    note: "仅记录观察；没有声称 actual 与 expected 相等。"
};

/// 只有匹配 Verified 后才取得 matches；Unchecked 不会凭空产生证明。
def verified_value[A](sample: Sample[A]) -> Option[A] {
    match sample {
        Sample.Verified { actual, matches, ... } => {
            let evidence = matches();
            Option.Some(actual)
        },
        Sample.Unchecked { ... } => Option.None
    }
}
```

## 08 递归 ADT：List / Tree

这里规定逻辑构造，不规定机器上的链表内存布局。结构归纳处理更小的尾部，再把相等性放回 `Cons`。

```
/// 有限列表；这里规定逻辑构造，不规定机器上的链表内存布局。
type List[A] {
    case Nil;
    case Cons(head: A, tail: List[A]);
}

def list_map[A, B](values: List[A], transform: A -> B) -> List[B] {
    match values {
        List.Nil => List.Nil,
        List.Cons(head, tail) =>
            List.Cons(transform(head), list_map(tail, transform))
    }
}

/// 结构归纳：递归地处理更小的尾部，再把相等性放回 Cons。
proof list_map_identity[A](values: List[A]) -> (
    list_map(values, x => x) ~= values
) {
    match values {
        List.Nil => refl,
        List.Cons(head, tail) =>
            congr_arg(
                rest => List.Cons(head, rest),
                list_map_identity(tail)
            )
    }
}

/// 二叉树：分支载荷本身是左右子树和值构成的积。
type Tree[A] {
    case Empty;

    case Node {
        left: Tree[A];
        value: A;
        right: Tree[A];
    }
}

def tree_map[A, B](tree: Tree[A], transform: A -> B) -> Tree[B] {
    match tree {
        Tree.Empty => Tree.Empty,
        Tree.Node { left, value, right } => Tree.Node {
            left: tree_map(left, transform),
            value: transform(value),
            right: tree_map(right, transform)
        }
    }
}
```

## 09 GADT：构造器明确返回类型族的哪一部分

`Expr` 的外层签名只有 `Type -> Type`，没有隐含 `Self`。`Pair` / `If` 自己绑定类型参数。分支细化返回类型，不是运行时强制转换。

```
type Expr: Type -> Type {
    case IntLit(value: Int) -> Expr[Int];

    case BoolLit(value: Bool) -> Expr[Bool];

    case Add(
        left: Expr[Int],
        right: Expr[Int]
    ) -> Expr[Int];

    case If[A](
        condition: Expr[Bool],
        when_true: Expr[A],
        when_false: Expr[A]
    ) -> Expr[A];

    case Pair[A, B](
        left: Expr[A],
        right: Expr[B]
    ) -> Expr[(A, B)];
}

/// 分支细化返回类型：不是运行时强制类型转换。
def eval[A](expression: Expr[A]) -> A {
    match expression {
        Expr.IntLit(value) => value,
        Expr.BoolLit(value) => value,
        Expr.Add(left, right) => eval(left) + eval(right),
        Expr.If(condition, when_true, when_false) =>
            if eval(condition) {
                eval(when_true)
            } else {
                eval(when_false)
            },
        Expr.Pair(left, right) => (eval(left), eval(right))
    }
}

let expression: Expr[(Int, Bool)] = Expr.Pair(
    Expr.Add(Expr.IntLit(1), Expr.IntLit(2)),
    Expr.BoolLit(true)
);

proof evaluation_example() -> (
    eval(expression) ~= (3, true)
) {
    refl
}
```

## 10 值索引：长度写在类型里

`head` 的参数类型已经说明非空；`Nil` 无法满足该索引。

```
/// 显式自然数构造，避免本例依赖复杂算术归一化。
type Nat {
    case Zero;
    case Succ(previous: Nat);
}

type Vec: Type -> Nat -> Type {
    case Nil[A] -> Vec[A, Nat.Zero];

    case Cons[A, n: Nat](
        head: A,
        tail: Vec[A, n]
    ) -> Vec[A, Nat.Succ(n)];
}

/// 参数类型已经说明非空；Nil 无法满足该索引。
def head[A, n: Nat](values: Vec[A, Nat.Succ(n)]) -> A {
    match values {
        Vec.Cons(first, _) => first
    }
}

let two_values: Vec[Int, Nat.Succ(Nat.Succ(Nat.Zero))] =
    Vec.Cons(10, Vec.Cons(20, Vec.Nil));

proof nonempty_head_example() -> (
    head(two_values) ~= 10
) {
    refl
}
```

## 11 多参数子类型：`RoundTrip[A, B] :> Idempotent[B]`

`B` 进入目标参数；`A` 仍留在源结构里，没有自动重复填参。`twice` 固定，不属于可填写字段。

```
/// 一份幂等操作；twice 固定，不属于可填写字段。
type Idempotent[A] {
    fn run(value: A) -> A;

    law idempotent(value: A) -> (
        run(run(value)) ~= run(value)
    );

    def twice(value: A) -> A {
        run(run(value))
    }
}

/// A 编码到 B 后能够恢复 A；不要求任意 B 都由某个 A 编码得到。
type RoundTrip[A, B] {
    fn encode(value: A) -> B;
    fn decode(value: B) -> A;

    law round_trip(value: A) -> (
        decode(encode(value)) ~= value
    );
}

forall[A, B] {
    /// 从 A/B 往返结构获得 B 上的幂等归一化能力。
    RoundTrip[A, B] :> Idempotent[B] {
        def run(value: B) -> B {
            self.encode(self.decode(value))
        }

        proof idempotent(value) {
            congr_arg(
                self.encode,
                self.round_trip(self.decode(value))
            )
        }
    }
}

/// 编码附上标准标签 0；解码只读取 Bool。
let tagged_bool: RoundTrip[Bool, (Bool, Int)] = {
    def encode(value: Bool) -> (Bool, Int) {
        (value, 0)
    }

    def decode(value: (Bool, Int)) -> Bool {
        value.0
    }

    proof round_trip(value) {
        refl
    }
};

let normalize_tag: Idempotent[(Bool, Int)] = tagged_bool;

proof normalization_example() -> (
    normalize_tag.run((true, 42)) ~= (true, 0)
) {
    refl
}

proof normalization_is_idempotent(value: (Bool, Int)) -> (
    normalize_tag.twice(value) ~= normalize_tag.run(value)
) {
    normalize_tag.idempotent(value)
}
```

## 12 抽象依赖：不必展开底层实现

外层和内层只需满足 `Functor`。两个 `Monad[Option]` 参数在期望 `Functor[Option]` 的位置通过子类型链使用。

```
/// 只声明处理能力，不要求此处知道算法或内部表示。
type Stage[A, B] {
    fn run(value: A) -> B;
}

/// A -> B -> C 的组合。共享的 B 显式写在类型参数中。
type Pipeline[A, B, C] {
    first: Stage[A, B];
    second: Stage[B, C];

    def run(value: A) -> C {
        second.run(first.run(value))
    }
}

/// 外层和内层只需满足 Functor；不要求展开它们的内部结构。
def map_nested[
    F: Type -> Type,
    G: Type -> Type,
    A,
    B
](
    outer: Functor[F],
    inner: Functor[G],
    value: F[G[A]],
    transform: A -> B
) -> F[G[B]] {
    outer.map(
        value,
        nested => inner.map(nested, transform)
    )
}

let nested_result: Option[Option[Int]] =
    map_nested[Option, Option, Int, Int](
        option_monad,
        option_monad,
        Option.Some(Option.Some(2)),
        x => x + 1
    );

proof nested_result_example() -> (
    nested_result ~= Option.Some(Option.Some(3))
) {
    refl
}
```

## 13 应当拒绝的反例

以下**不是**模块里的声明。有的能被文法识别，仍应按语义拒绝。

角色错误：`fn join(...) { ... }`。`fn` 没有定义体；已有定义必须使用 `def`。

覆盖错误：在 `Monad` 记录构造中重新提供 `def join(...) { ... }`。`join` 已由类型固定定义，不属于构造时可以填写的字段。

证据错误：`proof identity(value) { map(value, x => x) ~= value }`。这里只返回了命题，没有提供该命题的证明。

分支错误：直接读取 `event.x`。`Event` 的公共接口没有 `x`；应先匹配 `Click`，或明确提供一个可选坐标操作。

字段错误：`Event.Key { id: 1, x: 0, y: 0 }`。`Key` 需要 `code`，不接受 `Click` 的专有字段。

同名覆盖：`case` 内重声明已有公共字段 `id`。不静默遮蔽公共字段；重名必须报告，不能按最后一个声明解释。

虚假证明：`Sample.Verified { expected: 1, actual: 2, proof matches() { refl } }`。`1` 和 `2` 不会通过定义展开变为相同项。

GADT 错误：`let bad: Expr[Bool] = Expr.IntLit(1);`。`IntLit` 的返回类型是 `Expr[Int]`。

索引错误：`head(Vec.Nil)`。空向量的索引无法成为 `Nat.Succ(n)`。

参数错误：把 `RoundTrip[A, B]` 的子类型目标擅自改为 `Idempotent[A]`。现有 `run` 定义接收 `B`、返回 `B`；必须另作明确且有效的构造，不能猜测参数。

层次错误：`Option :> Monad[Option]`。`Option` 是类型构造器；`Monad[Option]` 是操作与证明构成的结构类型。没有授权从类型名字或 `Option[A]` 数据值凭空生成这份结构。

路径错误：同一源值到同一目标类型存在两个含义不同的隐式补全。必须暴露歧义或证明路径一致；不得按声明顺序悄悄选择。

证据失效：换掉结构的函数字段，直接复制原 `law` 的证明。证明类型依赖具体字段；只有仍然匹配或有明确转移证明时才可复用。

## 14 泛型子类型证明展开

日常阅读可以跳过，但证据不能凭空省略。只使用 `SKILL.md` 中的相等规则，以及源结构真实提供的 `law` 成员。没有把要证明的目标 `law` 当作前提，也没有新增 `law` 充当全局公理。

```
/// 标准映射构造满足复合要求。
proof applicative_map_composition[
    F: Type -> Type,
    A,
    B,
    C
](
    app: Applicative[F],
    value: F[A],
    first: A -> B,
    second: B -> C
) -> (
    app.ap(app.pure(second), app.ap(app.pure(first), value))
    ~=
    app.ap(app.pure(x => second(first(x))), value)
) {
    let compose = f => g => x => f(g(x));

    trans(
        symm(app.ap_composition(app.pure(second), app.pure(first), value)),
        trans(
            congr_arg(
                lifted => app.ap(app.ap(lifted, app.pure(first)), value),
                app.ap_homomorphism(compose, second)
            ),
            congr_arg(
                lifted => app.ap(lifted, value),
                app.ap_homomorphism(compose(second), first)
            )
        )
    )
}

/// 证明辅助的固定定义；不登记新的子类型路径，不给 Monad 增加可覆盖成员。
def monadic_ap[F: Type -> Type, A, B](
    monad: Monad[F],
    function: F[A -> B],
    argument: F[A]
) -> F[B] {
    monad.bind(function, f =>
        monad.bind(argument, x => monad.pure(f(x)))
    )
}

/// 先作一次纯映射再 bind，可以把普通转换移进后续函数。
proof bind_after_pure_map[F: Type -> Type, A, B, C](
    monad: Monad[F],
    value: F[A],
    transform: A -> B,
    next: B -> F[C]
) -> (
    monad.bind(
        monad.bind(value, x => monad.pure(transform(x))),
        next
    )
    ~=
    monad.bind(value, x => next(transform(x)))
) {
    trans(
        monad.associativity(value, x => monad.pure(transform(x)), next),
        congr_arg(
            continuation => monad.bind(value, continuation),
            funext(x => monad.left_identity(transform(x), next))
        )
    )
}

/// 单子构造的 ap 满足交换要求。
proof monad_ap_interchange[F: Type -> Type, A, B](
    monad: Monad[F],
    function: F[A -> B],
    value: A
) -> (
    monadic_ap(monad, function, monad.pure(value))
    ~=
    monadic_ap(monad, monad.pure(f => f(value)), function)
) {
    let left_to_common = congr_arg(
        continuation => monad.bind(function, continuation),
        funext(f =>
            monad.left_identity(value, x => monad.pure(f(x)))
        )
    );

    let right_to_common = monad.left_identity(
        f => f(value),
        apply => monad.bind(function, f => monad.pure(apply(f)))
    );

    trans(left_to_common, symm(right_to_common))
}

/// 单子构造的 ap 满足复合要求。
/// 两侧分别化为：先 outer，再 inner，再 value，最后返回 f(g(x))。
proof monad_ap_composition[F: Type -> Type, A, B, C](
    monad: Monad[F],
    outer: F[B -> C],
    inner: F[A -> B],
    value: F[A]
) -> (
    monadic_ap(
        monad,
        monadic_ap(
            monad,
            monadic_ap(monad, monad.pure(f => g => x => f(g(x))), outer),
            inner
        ),
        value
    )
    ~=
    monadic_ap(monad, outer, monadic_ap(monad, inner, value))
) {
    let compose = f => g => x => f(g(x));
    let with_inner = h => monad.bind(inner, g => monad.pure(h(g)));
    let with_value = h => monad.bind(value, x => monad.pure(h(x)));

    let left_expand = congr_arg(
        intermediate => monad.bind(
            monad.bind(intermediate, with_inner),
            with_value
        ),
        monad.left_identity(
            compose,
            k => monad.bind(outer, f => monad.pure(k(f)))
        )
    );

    let left_flatten = congr_arg(
        intermediate => monad.bind(intermediate, with_value),
        bind_after_pure_map(monad, outer, compose, with_inner)
    );

    let left_associate = monad.associativity(
        outer,
        f => with_inner(compose(f)),
        with_value
    );

    let left_normalize = congr_arg(
        continuation => monad.bind(outer, continuation),
        funext(f => bind_after_pure_map(monad, inner, compose(f), with_value))
    );

    let right_associate = congr_arg(
        continuation => monad.bind(outer, continuation),
        funext(f =>
            monad.associativity(
                inner,
                g => monad.bind(value, x => monad.pure(g(x))),
                y => monad.pure(f(y))
            )
        )
    );

    let right_normalize = congr_arg(
        continuation => monad.bind(outer, continuation),
        funext(f =>
            congr_arg(
                continuation => monad.bind(inner, continuation),
                funext(g =>
                    bind_after_pure_map(
                        monad,
                        value,
                        g,
                        y => monad.pure(f(y))
                    )
                )
            )
        )
    );

    trans(
        left_expand,
        trans(
            left_flatten,
            trans(
                left_associate,
                trans(
                    left_normalize,
                    symm(trans(right_associate, right_normalize))
                )
            )
        )
    )
}
```
