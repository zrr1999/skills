# 示例

按以下顺序共享背景，所有 spore 代码块拼接为一个识别单元。后文可以引用前文；单节不一定独立。证明项尚未经过类型检查器或证明内核核验。

| 顺序 | 内容 |
| --- | --- |
| 01 | 定义、方法与 curry / uncurry |
| 02 | 往返、幂等与子类型复用 |
| 03 | 精化与谓词弱化 |
| 04 | Functor → Applicative → Selective → Monad：Option |
| 05 | Sequence → LinkedList / VectorLayout |
| 06 | Mapping、有限枚举与更新：BoolMap |
| 07 | Fin / Vec 与 Expr |

共同背景：Type、Prop、Int、Nat、Bool、Str、元组及其基本运算；Nat 按 Zero / Succ 归纳定义，数字是简写，加法与比较按构造器归约。采用纯全函数与结构递减递归、函数外延性及 SKILL.md 列出的证明组合子。`def law` 给出证明项，`law` 声明待补全的证据字段。

## 01 定义、方法与 curry / uncurry

区分实例字段、固定的类型预定义和绑定方法。Self 是当前完整类型。

```spore
// 定义、成员选择与函数应用。共享背景见本页开头；这些文件是待机器核验的设计稿。

type Counter {
    value: Int;
    step: Int = 1;

    def fn make(value: Int) -> Self {
        Self { value = value }
    }

    method next() -> Self {
        Self.make(self.value + step)
    }
}

counter: Counter = Counter.make(41);
advance: () -> Counter = counter.next;

def law bound_method() -> (advance().value ~= 42) {
    refl
}

type Mapper[A, B] {
    fn transform(value: A) -> B;

    method apply(value: A) -> B {
        self.transform(value)
    }
}

increment: Mapper[Int, Int] = Mapper {
    transform = (value: Int) => value + 1
};

def law function_field() -> (increment.transform(41) ~= increment.apply(41)) {
    refl
}

def law member_selection() -> ((increment.apply)(41) ~= increment.apply(41)) {
    refl
}

type Either[A, B] {
    case Left(value: A);
    case Right(value: B);

    def fn fold[C](on_left: A -> C, on_right: B -> C) -> (Self -> C) {
        choice => match choice {
            Self.Left(value) => on_left(value),
            Self.Right(value) => on_right(value)
        }
    }
}

def fn identity[A](value: A) -> A {
    value
}

def fn curry[A, B, C](function: (A, B) -> C) -> (A -> B -> C) {
    a => b => function(a, b)
}

def fn uncurry[A, B, C](function: A -> B -> C) -> ((A, B) -> C) {
    (a, b) => function(a)(b)
}

def law curry_uncurry[A, B, C](function: A -> B -> C) -> (
    curry(uncurry(function)) ~= function
) {
    funext(a => funext(b => refl))
}

def law uncurry_curry[A, B, C](function: (A, B) -> C, a: A, b: B) -> (
    uncurry(curry(function))(a, b) ~= function(a, b)
) {
    refl
}

// 应拒绝：Counter { value = 1, step = 2 }；预定义不是可覆盖的字段默认值。
// 应拒绝：counter.step；普通类型预定义通过 Counter.step 访问。
// 应拒绝：无 body 的 method、同一实例域的 transform 字段与同名 method。
// 类型域的 map 与实例域的 map 可以同名，见 04-computation.sp。
// Self 只表示当前完整类型；Option[A] 的作用域里 Self[A] / Self[B] 都应拒绝。
```

## 02 往返、幂等与子类型复用

从往返定律推导幂等；带标签子类型复用返回 Self 的方法与定律。

```spore
// 从幂等投影与往返定律出发，为编码/解码构造规范化操作。
type Idempotent[A] {
    fn run(value: A) -> A;

    law idempotent(value: A) -> (
        run(run(value)) ~= run(value)
    );

    method twice(value: A) -> A {
        self.run(self.run(value))
    }

    method unchanged() -> Self {
        self
    }

    def law unchanged_identity(value: Self) -> (value.unchanged() ~= value) {
        refl
    }
}

// 只增加数据要求；两个方法和 unchanged_identity 都直接复用父定义。
type TaggedIdempotent[A] <: Idempotent[A] {
    tag: Str;
}

tagged_identity: TaggedIdempotent[Int] = TaggedIdempotent {
    run = value => value,
    idempotent = value => refl,
    tag = "identity"
};

retained: TaggedIdempotent[Int] = tagged_identity.unchanged();

def law inherited_self() -> (retained ~= tagged_identity) {
    TaggedIdempotent[Int].unchanged_identity(tagged_identity)
}

identity_view: Idempotent[Int] = tagged_identity;
retained_view: Idempotent[Int] = identity_view.unchanged();

// 视图按 Idempotent[Int] 实例化 Self，不根据隐藏的源值动态恢复子类型。
// 应拒绝：wrong: TaggedIdempotent[Int] = identity_view.unchanged();

type RoundTrip[A, B] {
    fn encode(value: A) -> B;
    fn decode(value: B) -> A;

    law round_trip(value: A) -> (
        decode(encode(value)) ~= value
    );
}

forall[A, B] {
    // 关系补全以源值 self 为参数，目标的 run 保持 encode/decode 观察。
    RoundTrip[A, B] <: Idempotent[B] {
        run = (value: B) => self.encode(self.decode(value)),
        idempotent = value =>
            congr_arg(self.encode, self.round_trip(self.decode(value)))
    }
}

tagged_bool: RoundTrip[Bool, (Bool, Int)] = RoundTrip {
    encode = (value: Bool) => (value, 0),
    decode = (pair: (Bool, Int)) => pair.0,
    round_trip = value => refl
};

// 此处插入规范视图；只得到 Idempotent 接口，不改写 tagged_bool。
normalize_tag: Idempotent[(Bool, Int)] = tagged_bool;

def law normalized_tag() -> (
    normalize_tag.run((true, 42)) ~= (true, 0)
) {
    refl
}

def law normalize_twice(value: (Bool, Int)) -> (
    normalize_tag.twice(value) ~= normalize_tag.run(value)
) {
    normalize_tag.idempotent(value)
}

// 重复证明该关系不能再选择另一套 run，也不把目标擅自改成 Idempotent[A]。
// 应拒绝：在补全块里重新提供 twice，或把一个相等命题直接当作证明体。
```

## 03 精化与谓词弱化

补全基础值与证据；弱化条件时保留原值。

```spore
// 精化是基础值与谓词证据；谓词弱化应保留基础值。
type Refined[A, P: A -> Prop] {
    value: A;
    law valid() -> (P(value));
}

// when 的 self 绑定基础值；布尔条件展开为相等命题。
type Positive = Int when self > 0;

three: Positive = Positive {
    value = 3,
    valid = () => refl
};

type PredicateImplication[A, P: A -> Prop, Q: A -> Prop] {
    law entails(value: A, evidence: P(value)) -> (Q(value));
}

def fn weaken[A, P: A -> Prop, Q: A -> Prop](
    implication: PredicateImplication[A, P, Q],
    refined: Refined[A, P]
) -> Refined[A, Q] {
    Refined[A, Q] {
        value = refined.value,
        valid = () => implication.entails(refined.value, refined.valid())
    }
}

def law weakening_preserves_value[A, P: A -> Prop, Q: A -> Prop](
    implication: PredicateImplication[A, P, Q],
    refined: Refined[A, P]
) -> (
    weaken(implication, refined).value ~= refined.value
) {
    refl
}

// weaken 是显式函数，尚未据此登记全局泛型子类型规则。
// 任意 Int 不能直接当作 Positive；-3 取绝对值得到 3 也不是保持原值的精化投影。
// 应拒绝：Positive { value = 0, valid = () => refl }。
// PositiveEven -> Positive -> Int 与经 Even 的路径可以共存的前提，
// 是两条路径最终都保留同一个基础整数，而非按导入顺序选择解释。
```

## 04 Functor → Applicative → Selective → Monad：Option

逐层定义具体操作并给出基本定律与相容性证明。四份抽象契约的源码声明仍未确定；这些具体定义不等于已经登记 Option <: Monad。

```spore
// 从 Functor → Applicative → Selective → Monad 的契约逐层构造 Option。
// 每层先给操作，再给对任意参数成立的 law；具体计算放在文件末尾。
// 抽象契约的声明与类型族实例化规则见 SKILL.md 的未定部分。

// Selective 结合律需要同时保存中间上下文与最初的输入。
// 用一个单参数记录，避免把单个二元组参数混同于两个函数参数。
type SelectInput[C, A] {
    context: C;
    value: A;
}

def fn select_lift_right[A, B, C](
    choice: Either[A, B]
) -> Either[A, Either[SelectInput[C, A], B]] {
    match choice {
        Either.Left(value) => Either.Left(value),
        Either.Right(value) => Either.Right(Either.Right(value))
    }
}

def fn select_route[A, B, C](
    choice: Either[C, A -> B]
) -> (A -> Either[SelectInput[C, A], B]) {
    value => match choice {
        Either.Left(context) => Either.Left(SelectInput { context = context, value = value }),
        Either.Right(function) => Either.Right(function(value))
    }
}

def fn select_apply_pair[A, B, C](function: C -> A -> B) -> (SelectInput[C, A] -> B) {
    input => function(input.context)(input.value)
}

type Option[A] {
    case None;
    case Some(value: A);

    // 此处 Self = Option[A]；改变参数后的 Option[B] 保留显式类型。
    def fn map[B](function: A -> B) -> (Self -> Option[B]) {
        value => match value {
            Self.None => Option[B].None,
            Self.Some(item) => Option[B].Some(function(item))
        }
    }

    method map[B](function: A -> B) -> Option[B] {
        Self.map(function)(self)
    }

    method is_some() -> Bool {
        match self {
            Option.None => false,
            Option.Some(_) => true
        }
    }

    def law map_identity() -> (
        Self.map(identity[A]) ~= identity[Self]
    ) {
        funext(value => match value {
            Option.None => refl,
            Option.Some(_) => refl
        })
    }

    def law map_composition[B, C](first: A -> B, second: B -> C) -> (
        Self.map(value => second(first(value)))
        ~= (value => Option[B].map(second)(Self.map(first)(value)))
    ) {
        funext(value => match value {
            Option.None => refl,
            Option.Some(_) => refl
        })
    }

    def law map_binding[B](value: Self, function: A -> B) -> (
        value.map(function) ~= Self.map(function)(value)
    ) {
        refl
    }

    // Applicative：pure 嵌入值，ap 组合两个已给定的 Option；不依赖 bind。
    def fn pure(value: A) -> Self {
        Self.Some(value)
    }

    def fn ap[B](function: Option[A -> B], value: Self) -> Option[B] {
        match function {
            Option.None => Option.None,
            Option.Some(f) => Self.map(f)(value)
        }
    }

    def fn map2[B, C](
        left: Self, right: Option[B], combine: (A, B) -> C
    ) -> Option[C] {
        Option[B].ap(left.map(a => b => combine(a, b)), right)
    }

    def fn keep_right[B](left: Self, right: Option[B]) -> Option[B] {
        Option[B].ap(left.map(_ => identity[B]), right)
    }

    def law map_from_ap[B](function: A -> B, value: Self) -> (
        value.map(function) ~= Self.ap(Option[A -> B].pure(function), value)
    ) {
        refl
    }

    def law ap_identity(value: Self) -> (
        Self.ap(Option[A -> A].pure(identity[A]), value) ~= value
    ) {
        match value {
            Option.None => refl,
            Option.Some(_) => refl
        }
    }

    def law ap_homomorphism[B](function: A -> B, value: A) -> (
        Self.ap(Option[A -> B].pure(function), Self.pure(value))
        ~= Option[B].pure(function(value))
    ) {
        refl
    }

    def law ap_interchange[B](function: Option[A -> B], value: A) -> (
        Self.ap(function, Self.pure(value))
        ~= Option[A -> B].ap(
            Option[(A -> B) -> B].pure(f => f(value)), function
        )
    ) {
        match function {
            Option.None => refl,
            Option.Some(_) => refl
        }
    }

    // 用 map 写组合律；map_from_ap 已证明它对应 ap(pure(compose), ...)。
    def law ap_composition[B, C](
        outer: Option[B -> C], inner: Option[A -> B], value: Self
    ) -> (
        Self.ap(
            Option[A -> B].ap(outer.map(f => g => a => f(g(a))), inner),
            value
        )
        ~= Option[B].ap(outer, Self.ap(inner, value))
    ) {
        match outer {
            Option.None => refl,
            Option.Some(_) => match inner {
                Option.None => refl,
                Option.Some(_) => match value {
                    Option.None => refl,
                    Option.Some(_) => refl
                }
            }
        }
    }

    // Selective：Left 必须使用已给定 handler；Right 已携带最终结果。
    def fn select[B](choice: Option[Either[A, B]], handler: Option[A -> B]) -> Option[B] {
        match choice {
            Option.None => Option.None,
            Option.Some(result) => match result {
                Either.Left(value) => handler.map(f => f(value)),
                Either.Right(value) => Option[B].pure(value)
            }
        }
    }

    def law select_identity(choice: Option[Either[A, A]]) -> (
        Self.select(choice, Option[A -> A].pure(identity[A]))
        ~= choice.map(Either[A, A].fold(identity[A], identity[A]))
    ) {
        match choice {
            Option.None => refl,
            Option.Some(result) => match result {
                Either.Left(_) => refl,
                Either.Right(_) => refl
            }
        }
    }

    def law select_distributivity[B](
        choice: Either[A, B], first: Option[A -> B], second: Option[A -> B]
    ) -> (
        Self.select(
            Option[Either[A, B]].pure(choice),
            Option[A -> B].keep_right(first, second)
        )
        ~= Option[B].keep_right(
            Self.select(Option[Either[A, B]].pure(choice), first),
            Self.select(Option[Either[A, B]].pure(choice), second)
        )
    ) {
        match choice {
            Either.Right(_) => refl,
            Either.Left(_) => match first {
                Option.None => refl,
                Option.Some(_) => match second {
                    Option.None => refl,
                    Option.Some(_) => refl
                }
            }
        }
    }

    def law select_associativity[B, C](
        choice: Option[Either[A, B]],
        route: Option[Either[C, A -> B]],
        handler: Option[C -> A -> B]
    ) -> (
        Self.select(choice, Option[C].select(route, handler))
        ~= Option[SelectInput[C, A]].select(
            Self.select(
                choice.map(select_lift_right[A, B, C]),
                route.map(select_route[A, B, C])
            ),
            handler.map(select_apply_pair[A, B, C])
        )
    ) {
        match choice {
            Option.None => refl,
            Option.Some(result) => match result {
                Either.Right(_) => refl,
                Either.Left(_) => match route {
                    Option.None => refl,
                    Option.Some(next) => match next {
                        Either.Right(_) => refl,
                        Either.Left(_) => match handler {
                            Option.None => refl,
                            Option.Some(_) => refl
                        }
                    }
                }
            }
        }
    }

    // Monad：next 可以根据已有结果产生后续 Option。
    def fn bind[B](next: A -> Option[B]) -> (Self -> Option[B]) {
        value => match value {
            Option.None => Option.None,
            Option.Some(item) => next(item)
        }
    }

    method bind[B](next: A -> Option[B]) -> Option[B] {
        Self.bind(next)(self)
    }

    def law bind_left_identity[B](value: A, next: A -> Option[B]) -> (
        Self.pure(value).bind(next) ~= next(value)
    ) {
        refl
    }

    def law bind_right_identity(value: Self) -> (
        value.bind(Self.pure) ~= value
    ) {
        match value {
            Option.None => refl,
            Option.Some(_) => refl
        }
    }

    def law bind_associativity[B, C](
        value: Self, first: A -> Option[B], second: B -> Option[C]
    ) -> (
        value.bind(first).bind(second) ~= value.bind(a => first(a).bind(second))
    ) {
        match value {
            Option.None => refl,
            Option.Some(_) => refl
        }
    }

    def law ap_from_bind[B](function: Option[A -> B], value: Self) -> (
        Self.ap(function, value)
        ~= function.bind(f => value.bind(a => Option[B].pure(f(a))))
    ) {
        match function {
            Option.None => refl,
            Option.Some(_) => match value {
                Option.None => refl,
                Option.Some(_) => refl
            }
        }
    }

    def law select_from_bind[B](
        choice: Option[Either[A, B]], handler: Option[A -> B]
    ) -> (
        Self.select(choice, handler)
        ~= choice.bind(Either[A, B].fold(
            a => handler.map(f => f(a)),
            Option[B].pure
        ))
    ) {
        match choice {
            Option.None => refl,
            Option.Some(result) => match result {
                Either.Left(_) => refl,
                Either.Right(_) => refl
            }
        }
    }
}

inc: Int -> Int = value => value + 1;
lifted_inc: Option[Int] -> Option[Int] = Option[Int].map(inc);
sample: Option[Int] = Option.Some(41);
apply_to_sample: (Int -> Int) -> Option[Int] = sample.map;

def law mapping_two_directions() -> (
    (lifted_inc(sample), apply_to_sample(inc)) ~= (Option.Some(42), Option.Some(42))
) {
    refl
}

def law applicative_pair() -> (
    Option[Int].map2(Option.Some(20), Option.Some(22), (a, b) => a + b)
    ~= Option.Some(42)
) {
    refl
}

def law selective_ready_result() -> (
    Option[Int].select[Int](Option.Some(Either.Right(7)), Option.None) ~= Option.Some(7)
) {
    refl
}

def law selective_missing_handler() -> (
    Option[Int].select[Int](Option.Some(Either.Left(7)), Option.None) ~= Option.None
) {
    refl
}

def law dependent_next_step() -> (
    Option.Some(21).bind(value =>
        if value > 0 { Option.Some(value * 2) } else { Option.None }
    ) ~= Option.Some(42)
) {
    refl
}

// Option <: Monad，以及它经 Selective、Applicative 到 Functor 的契约细化，
// 在本文件有逐项操作和相容性证明稿；尚未登记未定语法的构造器关系。
// Right 不需要 handler 的内容，不意味着严格求值会跳过 handler 实参表达式。
```

## 05 Sequence → LinkedList / VectorLayout

用 len/get 观察与范围定律统一接口，分别检查归纳表示和缓冲区布局模型。

```spore
// Sequence 是有限密集序列的观察契约：索引恰好在 [0, len) 内时有值。
// 从契约选择表示，再证明表示的观察满足它；依赖 04 的 Option。

type Sequence[A] {
    fn len() -> Nat;
    fn get(index: Nat) -> Option[A];

    law bounds(index: Nat) -> (get(index).is_some() ~= (index < len()));

    method is_empty() -> Bool {
        self.len() == 0
    }
}

type LinkedList[A] {
    case Nil;
    case Cons(head: A, tail: Self);

    empty: Self = Self.Nil;

    def fn singleton(value: A) -> Self {
        Self.Cons(value, empty)
    }

    method len() -> Nat {
        match self {
            Self.Nil => 0,
            Self.Cons(_, tail) => Nat.Succ(tail.len())
        }
    }

    method get(index: Nat) -> Option[A] {
        match self {
            Self.Nil => Option.None,
            Self.Cons(head, tail) => match index {
                Nat.Zero => Option.Some(head),
                Nat.Succ(previous) => tail.get(previous)
            }
        }
    }

    method prepend(value: A) -> Self {
        Self.Cons(value, self)
    }

    method append(value: A) -> Self {
        match self {
            Self.Nil => Self.singleton(value),
            Self.Cons(head, tail) => Self.Cons(head, tail.append(value))
        }
    }

    // 与 Option 相同的 Functor 操作形状，数据表示改为递归节点。
    def fn map[B](function: A -> B) -> (Self -> LinkedList[B]) {
        values => match values {
            Self.Nil => LinkedList[B].Nil,
            Self.Cons(head, tail) =>
                LinkedList[B].Cons(function(head), Self.map(function)(tail))
        }
    }

    method map[B](function: A -> B) -> LinkedList[B] {
        Self.map(function)(self)
    }
}

def law linked_bounds[A](values: LinkedList[A], index: Nat) -> (
    values.get(index).is_some() ~= (index < values.len())
) {
    match values {
        LinkedList.Nil => refl,
        LinkedList.Cons(_, tail) => match index {
            Nat.Zero => refl,
            Nat.Succ(previous) => linked_bounds(tail, previous)
        }
    }
}

def law linked_map_identity[A](values: LinkedList[A]) -> (
    values.map(identity[A]) ~= values
) {
    match values {
        LinkedList.Nil => refl,
        LinkedList.Cons(head, tail) =>
            congr_arg(rest => LinkedList.Cons(head, rest), linked_map_identity(tail))
    }
}

def law linked_map_composition[A, B, C](
    values: LinkedList[A], first: A -> B, second: B -> C
) -> (
    values.map(first).map(second) ~= values.map(a => second(first(a)))
) {
    match values {
        LinkedList.Nil => refl,
        LinkedList.Cons(head, tail) => congr_arg(
            rest => LinkedList.Cons(second(first(head)), rest),
            linked_map_composition(tail, first, second)
        )
    }
}

def law linked_map_length[A, B](values: LinkedList[A], function: A -> B) -> (
    values.map(function).len() ~= values.len()
) {
    match values {
        LinkedList.Nil => refl,
        LinkedList.Cons(_, tail) =>
            congr_arg(Nat.Succ, linked_map_length(tail, function))
    }
}

def law linked_map_get[A, B](
    values: LinkedList[A], function: A -> B, index: Nat
) -> (
    values.map(function).get(index) ~= values.get(index).map(function)
) {
    match values {
        LinkedList.Nil => refl,
        LinkedList.Cons(_, tail) => match index {
            Nat.Zero => refl,
            Nat.Succ(previous) => linked_map_get(tail, function, previous)
        }
    }
}

def law linked_append_length[A](values: LinkedList[A], value: A) -> (
    values.append(value).len() ~= Nat.Succ(values.len())
) {
    match values {
        LinkedList.Nil => refl,
        LinkedList.Cons(_, tail) =>
            congr_arg(Nat.Succ, linked_append_length(tail, value))
    }
}

def law linked_append_lookup[A](values: LinkedList[A], value: A, index: Nat) -> (
    values.append(value).get(index)
    ~= if index == values.len() { Option.Some(value) } else { values.get(index) }
) {
    match values {
        LinkedList.Nil => match index {
            Nat.Zero => refl,
            Nat.Succ(_) => refl
        },
        LinkedList.Cons(_, tail) => match index {
            Nat.Zero => refl,
            Nat.Succ(previous) => linked_append_lookup(tail, value, previous)
        }
    }
}

forall[A] {
    LinkedList[A] <: Sequence[A] {
        len = self.len,
        get = self.get,
        bounds = index => linked_bounds(self, index)
    }
}

numbers: LinkedList[Int] = LinkedList[Int].singleton(10).append(20).prepend(0);
number_view: Sequence[Int] = numbers;

// 源方法绑定后填入视图的函数字段；两边都使用 .，但没有重复绑定接收者。
def law sequence_observation() -> (
    (number_view.len(), number_view.get(2)) ~= (numbers.len(), numbers.get(2))
) {
    refl
}

// 另一种表示：容量与序列内容分别建模，未暴露的槽位不算序列元素。
// slot 仍是数学观察函数，本文件没有实现连续内存或分配器。
type VectorLayout[A] {
    size: Nat;
    capacity: Nat;
    fn slot(index: Nat) -> Option[A];

    law fits() -> ((size <= capacity) ~= true);
    law initialized(index: Nat) -> (slot(index).is_some() ~= (index < size));

    method len() -> Nat {
        self.size
    }

    method get(index: Nat) -> Option[A] {
        self.slot(index)
    }
}

forall[A] {
    VectorLayout[A] <: Sequence[A] {
        len = self.len,
        get = self.get,
        bounds = index => self.initialized(index)
    }
}

pair_layout: VectorLayout[Int] = VectorLayout {
    size = 2,
    capacity = 4,
    slot = index => match index {
        Nat.Zero => Option.Some(10),
        Nat.Succ(previous) => match previous {
            Nat.Zero => Option.Some(20),
            Nat.Succ(_) => Option.None
        }
    },
    fits = () => refl,
    initialized = index => match index {
        Nat.Zero => refl,
        Nat.Succ(previous) => match previous {
            Nat.Zero => refl,
            Nat.Succ(_) => refl
        }
    }
};

pair_view: Sequence[Int] = pair_layout;

def law capacity_is_not_length() -> (
    (pair_view.len(), pair_view.get(2)) ~= (2, Option.None)
) {
    refl
}

// LinkedList 与 VectorLayout 都满足 Sequence，不推出二者彼此为子类型。
// 真正 Vector 的 reserve 还需证明长度和全部可读元素保持；本稿不声称实现了它。
```

## 06 Mapping、有限枚举与更新：BoolMap

区分缺键与值为 None；对任意键证明枚举、更新和删除的观察。

```spore
// 从查询、有限枚举与更新定律构造 BoolMap：两个键各对应一个可缺失的值。
// 选择有限 Bool 键域，使枚举与更新的通用证明完整可读，不假定任意 K 自带判等。

type Mapping[K, V] {
    fn get(key: K) -> Option[V];
}

def fn key_count(keys: LinkedList[Bool], query: Bool) -> Nat {
    match keys {
        LinkedList.Nil => 0,
        LinkedList.Cons(key, tail) =>
            (if key == query { 1 } else { 0 }) + key_count(tail, query)
    }
}

type FiniteMapping[V] <: Mapping[Bool, V] {
    fn keys() -> LinkedList[Bool];

    law enumeration(query: Bool) -> (
        key_count(keys(), query) ~= if get(query).is_some() { 1 } else { 0 }
    );

    method len() -> Nat {
        self.keys().len()
    }
}

// enumeration 同时排除重复键、缺键和额外的键。
// 更新定律需要比较两个状态，因此明确携带载体 M。
type MapUpdates[M, V] {
    fn get(map: M, key: Bool) -> Option[V];
    fn put(map: M, key: Bool, value: V) -> M;
    fn remove(map: M, key: Bool) -> M;

    law put_lookup(map: M, key: Bool, value: V, query: Bool) -> (
        get(put(map, key, value), query)
        ~= if key == query { Option.Some(value) } else { get(map, query) }
    );

    law remove_lookup(map: M, key: Bool, query: Bool) -> (
        get(remove(map, key), query)
        ~= if key == query { Option.None } else { get(map, query) }
    );
}

type BoolMap[V] {
    false_value: Option[V];
    true_value: Option[V];

    empty: Self = Self { false_value = Option.None, true_value = Option.None };

    method get(key: Bool) -> Option[V] {
        match key {
            false => self.false_value,
            true => self.true_value
        }
    }

    method keys() -> LinkedList[Bool] {
        match self.false_value {
            Option.None => match self.true_value {
                Option.None => LinkedList.Nil,
                Option.Some(_) => LinkedList[Bool].singleton(true)
            },
            Option.Some(_) => match self.true_value {
                Option.None => LinkedList[Bool].singleton(false),
                Option.Some(_) => LinkedList.Cons(false, LinkedList[Bool].singleton(true))
            }
        }
    }

    def fn put(map: Self, key: Bool, value: V) -> Self {
        match key {
            false => Self { false_value = Option.Some(value), true_value = map.true_value },
            true => Self { false_value = map.false_value, true_value = Option.Some(value) }
        }
    }

    method put(key: Bool, value: V) -> Self {
        Self.put(self, key, value)
    }

    def fn remove(map: Self, key: Bool) -> Self {
        match key {
            false => Self { false_value = Option.None, true_value = map.true_value },
            true => Self { false_value = map.false_value, true_value = Option.None }
        }
    }

    method remove(key: Bool) -> Self {
        Self.remove(self, key)
    }
}

def law bool_map_enumeration[V](map: BoolMap[V], query: Bool) -> (
    key_count(map.keys(), query) ~= if map.get(query).is_some() { 1 } else { 0 }
) {
    match map.false_value {
        Option.None => match map.true_value {
            Option.None => match query {
                false => refl,
                true => refl
            },
            Option.Some(_) => match query {
                false => refl,
                true => refl
            }
        },
        Option.Some(_) => match map.true_value {
            Option.None => match query {
                false => refl,
                true => refl
            },
            Option.Some(_) => match query {
                false => refl,
                true => refl
            }
        }
    }
}

def law bool_map_put_lookup[V](map: BoolMap[V], key: Bool, value: V, query: Bool) -> (
    map.put(key, value).get(query)
    ~= if key == query { Option.Some(value) } else { map.get(query) }
) {
    match key {
        false => match query {
            false => refl,
            true => refl
        },
        true => match query {
            false => refl,
            true => refl
        }
    }
}

def law bool_map_remove_lookup[V](map: BoolMap[V], key: Bool, query: Bool) -> (
    map.remove(key).get(query)
    ~= if key == query { Option.None } else { map.get(query) }
) {
    match key {
        false => match query {
            false => refl,
            true => refl
        },
        true => match query {
            false => refl,
            true => refl
        }
    }
}

forall[V] {
    BoolMap[V] <: FiniteMapping[V] {
        get = self.get,
        keys = self.keys,
        enumeration = query => bool_map_enumeration(self, query)
    }
}

def fn bool_map_updates[V]() -> MapUpdates[BoolMap[V], V] {
    MapUpdates[BoolMap[V], V] {
        get = (map, key) => map.get(key),
        put = BoolMap[V].put,
        remove = BoolMap[V].remove,
        put_lookup = (map, key, value, query) => bool_map_put_lookup(map, key, value, query),
        remove_lookup = (map, key, query) => bool_map_remove_lookup(map, key, query)
    }
}

original: BoolMap[Str] = BoolMap[Str].empty.put(false, "off").put(true, "on");
updated: BoolMap[Str] = original.put(false, "OFF");
updated_view: FiniteMapping[Str] = updated;
updates: MapUpdates[BoolMap[Str], Str] = bool_map_updates[Str]();

def law other_key_preserved() -> (updated.get(true) ~= original.get(true)) {
    updates.put_lookup(original, false, "OFF", true)
}

def law previous_value_preserved() -> (original.get(false) ~= Option.Some("off")) {
    refl
}

def law finite_size() -> (updated_view.len() ~= 2) {
    refl
}

stored_none: BoolMap[Option[Int]] = BoolMap[Option[Int]].empty.put(true, Option.None);

def law missing_and_stored_none() -> (
    (stored_none.get(false), stored_none.get(true)) ~= (Option.None, Option.Some(Option.None))
) {
    refl
}

// BoolMap 的存储大小由有限键域决定；这里没有实现任意键的哈希表。
// 具体 lookup/remove/put 的通用定律已提供，不能用几个具体查询代替这些证据。
```

## 07 Fin / Vec 与 Expr

把长度或结果类型放进索引；空 match 消去不可能分支。

```spore
// 用 Fin[n] 表达有效索引，用 Vec[A, n] 表达长度；再证明映射保持索引观察。
// Nat 采用本页开头的归纳背景。类型参数与值索引分别显式绑定。

type Fin: Nat -> Type {
    case Zero[n: Nat] -> Fin[Nat.Succ(n)];
    case Succ[n: Nat](previous: Fin[n]) -> Fin[Nat.Succ(n)];
}

type Vec: Type -> Nat -> Type {
    case Nil[A] -> Vec[A, Nat.Zero];
    case Cons[A, n: Nat](head: A, tail: Vec[A, n]) -> Vec[A, Nat.Succ(n)];
}

def fn head[A, n: Nat](values: Vec[A, Nat.Succ(n)]) -> A {
    match values {
        Vec.Cons(first, _) => first
    }
}

def fn vec_get[A, n: Nat](values: Vec[A, n], index: Fin[n]) -> A {
    match values {
        Vec.Nil => match index {},
        Vec.Cons(first, rest) => match index {
            Fin.Zero => first,
            Fin.Succ(previous) => vec_get(rest, previous)
        }
    }
}

def fn vec_map[A, B, n: Nat](function: A -> B) -> (Vec[A, n] -> Vec[B, n]) {
    values => match values {
        Vec.Nil => Vec.Nil,
        Vec.Cons(first, rest) => Vec.Cons(function(first), vec_map(function)(rest))
    }
}

def law vec_map_identity[A, n: Nat](values: Vec[A, n]) -> (
    vec_map(identity[A])(values) ~= values
) {
    match values {
        Vec.Nil => refl,
        Vec.Cons(first, rest) =>
            congr_arg(tail => Vec.Cons(first, tail), vec_map_identity(rest))
    }
}

def law vec_map_composition[A, B, C, n: Nat](
    values: Vec[A, n], first: A -> B, second: B -> C
) -> (
    vec_map(second)(vec_map(first)(values)) ~= vec_map(a => second(first(a)))(values)
) {
    match values {
        Vec.Nil => refl,
        Vec.Cons(head, tail) => congr_arg(
            rest => Vec.Cons(second(first(head)), rest),
            vec_map_composition(tail, first, second)
        )
    }
}

def law vec_map_get[A, B, n: Nat](values: Vec[A, n], function: A -> B, index: Fin[n]) -> (
    vec_get(vec_map(function)(values), index) ~= function(vec_get(values, index))
) {
    match values {
        Vec.Nil => match index {},
        Vec.Cons(_, rest) => match index {
            Fin.Zero => refl,
            Fin.Succ(previous) => vec_map_get(rest, function, previous)
        }
    }
}

pair_vector: Vec[Int, Nat.Succ(Nat.Succ(Nat.Zero))] =
    Vec.Cons(10, Vec.Cons(20, Vec.Nil));

def law nonempty_head() -> (head(pair_vector) ~= 10) {
    refl
}

type Expr: Type -> Type {
    case IntLit(value: Int) -> Expr[Int];
    case BoolLit(value: Bool) -> Expr[Bool];
    case Add(left: Expr[Int], right: Expr[Int]) -> Expr[Int];
    case If[A](condition: Expr[Bool], when_true: Expr[A], when_false: Expr[A]) -> Expr[A];
}

def fn eval[A](expression: Expr[A]) -> A {
    match expression {
        Expr.IntLit(value) => value,
        Expr.BoolLit(value) => value,
        Expr.Add(left, right) => eval(left) + eval(right),
        Expr.If(condition, when_true, when_false) =>
            if eval(condition) { eval(when_true) } else { eval(when_false) }
    }
}

calculation: Expr[Int] = Expr.If(
    Expr.BoolLit(true),
    Expr.Add(Expr.IntLit(1), Expr.IntLit(2)),
    Expr.IntLit(0)
);

def law evaluated_branch() -> (eval(calculation) ~= 3) {
    refl
}

// 空 match 消去不可能存在的 Fin[0]；分支检查需要根据构造器细化索引。
// 应拒绝：head(Vec.Nil)，以及 wrong: Expr[Bool] = Expr.IntLit(1)。
// Vec 的长度索引不承诺连续布局，也不是 Vector 的存储优化。
```

## 拒绝边界

语法反例由 scripts/check-syntax.mjs 交给 Ohm 验证。以下是需要单独审阅的语义反例，不能靠识别器通过与否裁定：

- Option[A] 内写 `Self[B]`：Self 已经是完整类型。
- 在 Counter 构造块中填写 step：step 是类型预定义，不是默认实例字段。
- 同一实例域同时声明名为 map 的函数字段和 method；类型函数与实例方法同名则允许。
- 普通类型函数直接读取 `self.value`，或方法用裸 value 隐式读取字段。
- 更换函数字段后直接复制不再成立的 law 证据，或用 refl 证明不能归约为同一项的等式。
- 未匹配就读取某 case 专有字段、构造 GADT 时返回错误索引，或对 Vec.Nil 使用非空 head。
- 把所有列表投影成空 Sequence：目标可能满足范围律，却没有保持源长度与元素。
- 仅用结果协变，把接收任意 Applicative 的 ap 换成只能接收 Option 的函数。完整类型族专门化不是普通参数逆变。

本稿保留 `Monad <: Selective <: Applicative <: Functor` 的契约增强方向，及 Option 的具体证据；它不把旧的 `Functor[Option]` 操作记录、`for F` 或 Family 作为已经接受的声明方案。
