# Spore Notation examples

按编号读取相关章节；八个代码块共享背景并按顺序组成设计稿。语义约定见 [SKILL.md](SKILL.md)。每节把契约、具体操作与证明一起引入。Ohm 仅识别句法，所有类型、结构归属和证明仍须语义审阅。

## 01-definitions.sp · 定义、宇宙与 Counter

```spore
// 定义、成员选择与函数应用。共享背景见 SKILL.md；这些文件是待机器核验的设计稿。

// 宇宙层级是元层级参数；数字 n 是 next 迭代的简写。
// 这条分层规则是背景规则模式，不是一个满足 Universe : Universe 的值定义。
Universe<u>: Universe<next(u)>;
Prop = Universe<0>;
Type = Universe<1>;

// <u> 绑定宇宙层级；[A: Universe<u>] 绑定该层级中的类型。
// 省略 <_> 产生待推断的层级变量；非累积：不插入升层或降层。
// 返回 Prop 的依赖量化仍在 Prop；其他依赖函数按输入/结果层级的 max 形成。
// Unit 与元组均在本例需要的 Type 层；不通过宇宙提升实现它们。
type Unit { case unit; }

// 量化 A 的宇宙可以任意高，但该函数类型表达的命题仍在 Prop。
Reflexivity<u>: Prop = (A: Universe<u>) -> (x: A) -> (x ~= x);
reflexivity<u>: Reflexivity<u> = A => x => refl;

// 支持单个元组值的分支解构；不等于函数调用时自动拆包。
def law pair_congr<u, v>[
    A: Universe<u>, B: Universe<v>, x: A, y: A, a: B, b: B
](
    first: x ~= y, second: a ~= b
) -> ((x, a) ~= (y, b)) {
    trans(congr_arg(value => (value, a), first),
          congr_arg(value => (y, value), second))
}

type Counter {
    value: Int;
    step: Int = 1;

    // 已知的字段只足以构造 Counter，不足以构造任意子类型 Self。
    def fn make(value: Int) -> Counter {
        Counter { value = value }
    }

    method next() -> Counter {
        Counter.make(self.value + step)
    }

    // 普通函数仍可使用 Self：返回输入不需要重新构造它。
    def fn keep(value: Self) -> Self {
        value
    }

    def law keep_identity(value: Self) -> (Self.keep(value) ~= value) {
        refl
    }
}

counter: Counter = Counter.make(41);
advance: () -> Counter = counter.next;

def law bound_method() -> (advance().value ~= 42) {
    refl
}

type TaggedCounter <: Counter {
    tag: Str;
}

tagged_counter: TaggedCounter = TaggedCounter { value = 41, tag = "requests" };
same_counter: TaggedCounter = TaggedCounter.keep(tagged_counter);
next_counter: Counter = tagged_counter.next();

def law inherited_keep() -> (same_counter ~= tagged_counter) {
    TaggedCounter.keep_identity(tagged_counter)
}

def law inherited_next() -> (next_counter.value ~= 42) {
    refl
}

// 应拒绝：TaggedCounter { value = 41 }；缺少 tag。
// 应拒绝：next_tagged: TaggedCounter = tagged_counter.next()；结果仍是 Counter。
// 应拒绝：父定义 def fn make(value: Int) -> Self { Self { value = value } }。
// Self 按完整子类型实例化；检查父 body 时不能假定 value 是它的全部构造要求。

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

    def fn fold[C](on_left: A -> C, on_right: B -> C) -> (Either[A, B] -> C) {
        choice => match choice {
            Either.Left(value) => on_left(value),
            Either.Right(value) => on_right(value)
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

add: (Int, Int) -> Int = (left, right) => left + right;
add_pair: (pair: (Int, Int)) -> Int = pair => add(pair.0, pair.1);

def law argument_shapes() -> (
    (add(20, 22), add_pair((20, 22)), curry(add)(20)(22)) ~= (42, 42, 42)
) { refl }

// 应拒绝：Counter { value = 1, step = 2 }；预定义不是可覆盖的字段默认值。
// 应拒绝：counter.step；普通类型预定义通过 Counter.step 访问。
// 应拒绝：无 body 的 method、同一实例域的 transform 字段与同名 method。
// 类型域的 map 与实例域的 map 可以同名，见 05-computation.sp。
// Self 只表示当前完整类型；Option[A] 的作用域里 Self[A] / Self[B] 都应拒绝。

// 声明糖与核心形式：同名片段是对照，不重复登记定义。
// fn f(x: A) -> B;              对应 f: A -> B;
// law p[X] -> (P);             对应 p[X: Type]: P;
// law p[X]() -> (P);           对应 p[X: Type]: () -> P;
// def law p[X] -> (P) { e }    对应 p[X: Type]: P = e;
// 无 () 的证据族与 () -> P 的证据函数不同，前者用 p[X]，后者用 p[X]()。
// 应拒绝：def f(x: Int) = x；def 只能配合 fn/law 和大括号。
// 应拒绝：def law p() = refl；没有以 = 结尾的 def 形式。
// 应拒绝：identity<Int>；Int 是类型实参，应写 identity[Int]。
// 应拒绝：把 A: Universe<1> 自动当作 A: Universe<2>，或 Type: Type。
// 应拒绝：curry(add)(20, 22)；该函数依次接受两个单独实参。
// 应拒绝：add((20, 22)) 或 add_pair(20, 22)；不会自动拆包或打包元组。
```

## 02-subtyping.sp · 子类型与幂等操作

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

## 03-refinements.sp · 精化与谓词弱化

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

## 04-categories.sp · 范畴、函子与元组

```spore
// 从普通函数组合开始，每个契约紧接一个具体结构及其证据。
// Category 的两个层级分别约束对象和 Hom；结构自身位于 max(next(u),next(v))。
// 1. 函数为什么能组合：Category 与 types。

type Category<u, v> {
    Obj: Universe<u>;
    Hom[X: Obj, Y: Obj]: Universe<v>;
    id[X: Obj]: Hom[X, X];
    compose[X: Obj, Y: Obj, Z: Obj]:
        (Hom[Y, Z], Hom[X, Y]) -> Hom[X, Z];

    law left_identity[X: Obj, Y: Obj](f: Hom[X, Y]) -> (
        compose(id[Y], f) ~= f
    );
    law right_identity[X: Obj, Y: Obj](f: Hom[X, Y]) -> (
        compose(f, id[X]) ~= f
    );
    law associativity[W: Obj, X: Obj, Y: Obj, Z: Obj](
        f: Hom[W, X], g: Hom[X, Y], h: Hom[Y, Z]
    ) -> (
        compose(h, compose(g, f)) ~= compose(compose(h, g), f)
    );
}

// 类型与别名用大写名称；普通结构定义用小写，泛型参数沿用数学记号。
// 透明别名，不定义新子类型，也不登记宇宙转换。
LargeCategory<v> = Category<next(v), v>;

// types 是已有结构类型中的值；没有在此声明一个新的 Types 数据类型。
// 构造块按契约补全字段：后续字段可引用此前补全，泛型字段独立绑定参数。
types: LargeCategory<1> = LargeCategory<1> {
    Obj = Type,
    Hom[X: Obj, Y: Obj] = X -> Y,
    id[X: Obj] = x => x,
    compose[X: Obj, Y: Obj, Z: Obj] = (g, f) => x => g(f(x)),
    left_identity[X: Obj, Y: Obj] = f => funext(x => refl),
    right_identity[X: Obj, Y: Obj] = f => funext(x => refl),
    associativity[W: Obj, X: Obj, Y: Obj, Z: Obj] = (f, g, h) => funext(x => refl),
};

types_category: Category<2, 1> = types;

def law composing_integers() -> (
    types.compose((n: Int) => n + 1, (n: Int) => n * 2)(20) ~= 41
) { refl }

// 应拒绝：smaller: Category<1,1> = types；Obj = Type 不在 Universe<1>。
// 应拒绝：larger: Category<3,2> = types；不会自动提升字段或整个结构的宇宙。

// 2. 保持组合的映射：Functor 与恒等构造，随后用于真实的元组。

type Functor[C: Category, D: Category] {
    obj: C.Obj -> D.Obj;
    map[X: C.Obj, Y: C.Obj]: C.Hom[X, Y] -> D.Hom[obj(X), obj(Y)];

    law identity[X: C.Obj] -> (map(C.id[X]) ~= D.id[obj(X)]);
    law composition[X: C.Obj, Y: C.Obj, Z: C.Obj](
        f: C.Hom[X, Y], g: C.Hom[Y, Z]
    ) -> (map(C.compose(g, f)) ~= D.compose(map(g), map(f)));
}

identity_functor[C: Category]: Functor[C, C] = Functor[C, C] {
    obj = x => x,
    map[X: C.Obj, Y: C.Obj] = f => f,
    identity[X: C.Obj] = refl,
    composition[X: C.Obj, Y: C.Obj, Z: C.Obj] = (f, g) => refl,
};

identity_types: Functor[types, types] = identity_functor[types];
// identity_functor[C] 是参数化结构值；C 提供结构参数，不引入新数据类型。
// 应拒绝：把这份普通结构构造改写为 type IdentityFunctor[C]: Functor[C,C]。
// 对象映射 Type -> Type 位于 Universe<2>，map/law 不提高该界。
// 应拒绝：Functor[types,types]: Type；准确层级为 Universe<2>。

// 3. 同时变换两个分量：积范畴、Bifunctor 与 pair_bifunctor。

product_category<u, v, w, z>[C: Category<u, v>, D: Category<w, z>]:
    Category<max(u, w), max(v, z)> = Category<max(u, w), max(v, z)> {
    Obj = (C.Obj, D.Obj),
    Hom[P: Obj, Q: Obj] = (C.Hom[P.0, Q.0], D.Hom[P.1, Q.1]),
    id[P: Obj] = (C.id[P.0], D.id[P.1]),
    compose[P: Obj, Q: Obj, R: Obj] = (g, f) => (C.compose(g.0, f.0), D.compose(g.1, f.1)),
    left_identity[P: Obj, Q: Obj] = f => {
        match f { (fc, fd) => pair_congr(C.left_identity(fc), D.left_identity(fd)) }
    },
    right_identity[P: Obj, Q: Obj] = f => {
        match f { (fc, fd) => pair_congr(C.right_identity(fc), D.right_identity(fd)) }
    },
    associativity[P: Obj, Q: Obj, R: Obj, S: Obj] = (f, g, h) => {
        pair_congr(C.associativity(f.0, g.0, h.0), D.associativity(f.1, g.1, h.1))
    },
};

paired_types: Category<2, 1> = product_category[types, types];
// Bifunctor 是类型别名；product_category[C,D] 是该类型引用的源范畴值。
Bifunctor[C: Category, D: Category, E: Category] = Functor[product_category[C, D], E];

pair_bifunctor: Bifunctor[types, types, types] = Bifunctor[types, types, types] {
    obj = p => (p.0, p.1),
    map[P: (Type, Type), Q: (Type, Type)] = arrows => pair => (arrows.0(pair.0), arrows.1(pair.1)),
    identity[P: (Type, Type)] = funext(pair => match pair { (x, y) => refl }),
    composition[P: (Type, Type), Q: (Type, Type), R: (Type, Type)] = (f, g) => funext(pair => refl),
};

def law transforming_a_pair() -> (
    pair_bifunctor.map(((n: Int) => n + 1, (n: Int) => n * 2))((20, 21)) ~= (21, 42)
) { refl }
// map 接收一个态射对，再返回一个接收元组的函数；两次调用都只有一个实参。
// 应拒绝：pair_bifunctor.map(f, g)；应写 pair_bifunctor.map((f, g))。

// 4. 复合已有构造：先 pair_bifunctor，再保持结果的 identity_functor。

compose_functors[
    C: Category, D: Category, E: Category, F: Functor[C, D], G: Functor[D, E]
]: Functor[C, E] = Functor[C, E] {
    obj = x => G.obj(F.obj(x)),
    map[X: C.Obj, Y: C.Obj] = f => G.map(F.map(f)),
    identity[X: C.Obj] = {
        trans(congr_arg(G.map[F.obj(X), F.obj(X)], F.identity[X]),
              G.identity[F.obj(X)])
    },
    composition[X: C.Obj, Y: C.Obj, Z: C.Obj] = (f, g) => {
        trans(congr_arg(G.map[F.obj(X), F.obj(Z)], F.composition(f, g)),
              G.composition(F.map(f), F.map(g)))
    },
};

pair_then_identity: Functor[product_category[types, types], types] =
    compose_functors[product_category[types, types], types, types, pair_bifunctor, identity_functor[types]];

def law composing_pair_constructions() -> (
    pair_then_identity.map(((n: Int) => n + 1, (n: Int) => n * 2))((20, 21)) ~= (21, 42)
) { refl }

// 5. 换形状而不丢信息：Isomorphism 与元组结合、单位元。

type Isomorphism[C: Category, X: C.Obj, Y: C.Obj] {
    hom: C.Hom[X, Y];
    inv: C.Hom[Y, X];
    law inv_hom -> (C.compose(inv, hom) ~= C.id[X]);
    law hom_inv -> (C.compose(hom, inv) ~= C.id[Y]);
}

pair_associator[A, B, C]: Isomorphism[
    types, ((A, B), C), (A, (B, C))
] = Isomorphism[types, ((A, B), C), (A, (B, C))] {
    hom = p => (p.0.0, (p.0.1, p.1)),
    inv = p => ((p.0, p.1.0), p.1.1),
    inv_hom = funext(p => match p { ((a, b), c) => refl }),
    hom_inv = funext(p => match p { (a, (b, c)) => refl }),
};

pair_left_unitor[A]: Isomorphism[types, (Unit, A), A] = Isomorphism[types, (Unit, A), A] {
    hom = p => p.1,
    inv = a => (Unit.unit, a),
    inv_hom = funext(p => match p { (Unit.unit, a) => refl }),
    hom_inv = funext(a => refl),
};

pair_right_unitor[A]: Isomorphism[types, (A, Unit), A] = Isomorphism[types, (A, Unit), A] {
    hom = p => p.0,
    inv = a => (a, Unit.unit),
    inv_hom = funext(p => match p { (a, Unit.unit) => refl }),
    hom_inv = funext(a => refl),
};

def law reassociating_a_pair() -> (
    pair_associator[Int, Int, Int].hom(((1, 2), 3)) ~= (1, (2, 3))
) { refl }

// 6. 将元组规律合成一个结构：MonoidalStructure 与 types_monoidal。
// tensor.obj/map 各接收一个配对值；结合/单位同构的自然性与相容律分别列出。

type MonoidalStructure[C: Category] {
    tensor: Bifunctor[C, C, C];
    unit: C.Obj;
    associator[X: C.Obj, Y: C.Obj, Z: C.Obj]: Isomorphism[
        C, tensor.obj((tensor.obj((X, Y)), Z)), tensor.obj((X, tensor.obj((Y, Z))))
    ];
    left_unitor[X: C.Obj]: Isomorphism[C, tensor.obj((unit, X)), X];
    right_unitor[X: C.Obj]: Isomorphism[C, tensor.obj((X, unit)), X];

    law associator_naturality[X: C.Obj, Y: C.Obj, Z: C.Obj, U: C.Obj, V: C.Obj, W: C.Obj](
        f: C.Hom[X, U], g: C.Hom[Y, V], h: C.Hom[Z, W]
    ) -> (
        C.compose(associator[U, V, W].hom, tensor.map((tensor.map((f, g)), h)))
        ~= C.compose(tensor.map((f, tensor.map((g, h)))), associator[X, Y, Z].hom)
    );
    law left_unitor_naturality[X: C.Obj, Y: C.Obj](f: C.Hom[X, Y]) -> (
        C.compose(left_unitor[Y].hom, tensor.map((C.id[unit], f)))
        ~= C.compose(f, left_unitor[X].hom)
    );
    law right_unitor_naturality[X: C.Obj, Y: C.Obj](f: C.Hom[X, Y]) -> (
        C.compose(right_unitor[Y].hom, tensor.map((f, C.id[unit])))
        ~= C.compose(f, right_unitor[X].hom)
    );
    law pentagon[W: C.Obj, X: C.Obj, Y: C.Obj, Z: C.Obj] -> (
        C.compose(associator[W, X, tensor.obj((Y, Z))].hom,
                  associator[tensor.obj((W, X)), Y, Z].hom)
        ~= C.compose(tensor.map((C.id[W], associator[X, Y, Z].hom)),
            C.compose(associator[W, tensor.obj((X, Y)), Z].hom,
                      tensor.map((associator[W, X, Y].hom, C.id[Z]))))
    );
    law triangle[X: C.Obj, Y: C.Obj] -> (
        C.compose(tensor.map((C.id[X], left_unitor[Y].hom)), associator[X, unit, Y].hom)
        ~= tensor.map((right_unitor[X].hom, C.id[Y]))
    );
}

types_monoidal: MonoidalStructure[types] = MonoidalStructure[types] {
    tensor = pair_bifunctor,
    unit = Unit,
    associator[A, B, C] = pair_associator[A, B, C],
    left_unitor[A] = pair_left_unitor[A],
    right_unitor[A] = pair_right_unitor[A],
    associator_naturality[A, B, C, X, Y, Z] = (f, g, h) => funext(p => refl),
    left_unitor_naturality[A, B] = f => funext(p => refl),
    right_unitor_naturality[A, B] = f => funext(p => refl),
    pentagon[A, B, C, D] = funext(p => refl),
    triangle[A, B] = funext(p => refl),
};

// 自然变换在 05 中随 Some 注入引入；自然同构随 Unit 配对与拆除引入。
```

## 05-computation.sp · 计算结构与 Option

```spore
// 从 Functor → Applicative → Selective → Monad 的契约逐层构造 Option。
// 阅读顺序与 SKILL.md 配对：Functor/map → Applicative/pure、ap → Selective/select → Monad/bind。
// 前置契约声明供唯一的 Option 类型体使用；长的通用推导放在实例与具体计算之后。

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

compose_function[A, B, C]: (B -> C) -> (A -> B) -> A -> C =
    outer => inner => value => outer(inner(value));
make_pair[A, B]: A -> B -> (A, B) = a => b => (a, b);

// 这些是结构值的类型；obj/map/pure/ap 等是同一份结构中的字段。
// Self 若出现在这里会表示完整结构值类型，不表示 obj(A)。
type Applicative <: Functor[types, types] {
    pure[A: Type]: A -> obj(A);
    ap[A: Type, B: Type]: (obj(A -> B), obj(A)) -> obj(B);

    law map_from_ap[A, B](f: A -> B, x: obj(A)) -> (map(f)(x) ~= ap(pure(f), x));
    law ap_identity[A](x: obj(A)) -> (ap(pure(types.id[A]), x) ~= x);
    law ap_homomorphism[A, B](f: A -> B, a: A) -> (ap(pure(f), pure(a)) ~= pure(f(a)));
    law ap_interchange[A, B](u: obj(A -> B), a: A) -> (
        ap(u, pure(a)) ~= ap(pure(f => f(a)), u)
    );
    law ap_composition[A, B, C](u: obj(B -> C), v: obj(A -> B), w: obj(A)) -> (
        ap(ap(map(compose_function[A, B, C])(u), v), w) ~= ap(u, ap(v, w))
    );
}

type Selective <: Applicative {
    select[A: Type, B: Type]: (obj(Either[A, B]), obj(A -> B)) -> obj(B);

    law select_identity[A](x: obj(Either[A, A])) -> (
        select(x, pure(types.id[A])) ~= map(Either[A, A].fold(types.id[A], types.id[A]))(x)
    );
    // keep_right 展开为 ap/map；没有隐含捕获实例字段的普通预定义。
    law select_distributivity[A, B](choice: Either[A, B], first: obj(A -> B), second: obj(A -> B)) -> (
        select(pure(choice), ap(map(_ => types.id[A -> B])(first), second))
        ~= ap(map(_ => types.id[B])(select(pure(choice), first)), select(pure(choice), second))
    );
    law select_associativity[A, B, C](
        choice: obj(Either[A, B]), route: obj(Either[C, A -> B]), handler: obj(C -> A -> B)
    ) -> (
        select(choice, select(route, handler))
        ~= select(select(map(select_lift_right[A, B, C])(choice), map(select_route[A, B, C])(route)),
                  map(select_apply_pair[A, B, C])(handler))
    );
}

type Monad <: Selective {
    bind[A: Type, B: Type]: (A -> obj(B)) -> obj(A) -> obj(B);

    law bind_left_identity[A, B](a: A, next: A -> obj(B)) -> (bind(next)(pure(a)) ~= next(a));
    law bind_right_identity[A](x: obj(A)) -> (bind(pure[A])(x) ~= x);
    law bind_associativity[A, B, C](x: obj(A), f: A -> obj(B), g: B -> obj(C)) -> (
        bind(g)(bind(f)(x)) ~= bind(a => bind(g)(f(a)))(x)
    );
    law ap_from_bind[A, B](u: obj(A -> B), v: obj(A)) -> (
        ap(u, v) ~= bind(f => bind(a => pure(f(a)))(v))(u)
    );
    law select_from_bind[A, B](choice: obj(Either[A, B]), handler: obj(A -> B)) -> (
        select(choice, handler)
        ~= bind(Either[A, B].fold(a => map(f => f(a))(handler), pure[B]))(choice)
    );
}

// 此处 type 真正建立由 None/Some 构成的数据族，并为整个 Option 配备 Monad。
// 先生成数据族，再把继承的 obj 指定为该族；不是 Option[A] 与 obj(A) 循环展开。
// [A] 约束构造器与数据方法；结构操作另行量化 X/Y，不生成逐 A 的 Monad。
// 这种附带结构的声明要求事先指定数据族与 obj 的对应规则，不推广到任意记录。
type Option[A: Type]: Monad {
    case None;
    case Some(value: A);

    // Functor：None 没有值可变换；Some 将同一个变换作用于元素。
    // 显式 obj 必须与生成的数据族定义相等；不能改成 X => (Unit, X)。
    obj: Type -> Type = X => Option[X];

    map[X: Type, Y: Type]: (X -> Y) -> Option[X] -> Option[Y] =
        function => value => match value {
            Option[X].None => Option[Y].None,
            Option[X].Some(item) => Option[Y].Some(function(item))
        };

    method map[B](function: A -> B) -> Option[B] {
        value: Option[A] = self;
        Self.map(function)(value)
    }

    method is_some() -> Bool {
        value: Option[A] = self;
        match value {
            Option.None => false,
            Option.Some(_) => true
        }
    }

    def law identity[X] -> (
        Option.map(types.id[X]) ~= types.id[Option[X]]
    ) {
        funext(value => match value {
            Option.None => refl,
            Option.Some(_) => refl
        })
    }

    def law composition[X, B, C](first: X -> B, second: B -> C) -> (
        Option.map(value => second(first(value)))
        ~= (value => Option.map(second)(Option.map(first)(value)))
    ) {
        funext(value => match value {
            Option.None => refl,
            Option.Some(_) => refl
        })
    }

    def law map_binding[X, B](value: Option[X], function: X -> B) -> (
        value.map(function) ~= Option.map(function)(value)
    ) {
        refl
    }

    // Applicative：注入普通值，或者组合两个已经给定的 Option。
    def fn pure[X](value: X) -> Option[X] {
        Option[X].Some(value)
    }

    def fn ap[X, B](function: Option[X -> B], value: Option[X]) -> Option[B] {
        match function {
            Option.None => Option.None,
            Option.Some(f) => Option.map(f)(value)
        }
    }

    def fn map2[X, B, C](
        left: Option[X], right: Option[B], combine: (X, B) -> C
    ) -> Option[C] {
        Option.ap(left.map(a => b => combine(a, b)), right)
    }

    def fn keep_right[X, B](left: Option[X], right: Option[B]) -> Option[B] {
        Option.ap(left.map(_ => types.id[B]), right)
    }

    def law map_from_ap[X, B](function: X -> B, value: Option[X]) -> (
        value.map(function) ~= Option.ap(Option.pure(function), value)
    ) {
        refl
    }

    def law ap_identity[X](value: Option[X]) -> (
        Option.ap(Option.pure(types.id[X]), value) ~= value
    ) {
        match value {
            Option.None => refl,
            Option.Some(_) => refl
        }
    }

    def law ap_homomorphism[X, B](function: X -> B, value: X) -> (
        Option.ap(Option.pure(function), Option.pure(value))
        ~= Option.pure(function(value))
    ) {
        refl
    }

    def law ap_interchange[X, B](function: Option[X -> B], value: X) -> (
        Option.ap(function, Option.pure(value))
        ~= Option.ap(
            Option.pure(f => f(value)), function
        )
    ) {
        match function {
            Option.None => refl,
            Option.Some(_) => refl
        }
    }

    def law ap_composition[X, B, C](
        outer: Option[B -> C], inner: Option[X -> B], value: Option[X]
    ) -> (
        Option.ap(
            Option.ap(outer.map(f => g => a => f(g(a))), inner),
            value
        )
        ~= Option.ap(outer, Option.ap(inner, value))
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

    // Selective：Right 已有结果；Left 需要给定的 handler。
    def fn select[X, B](choice: Option[Either[X, B]], handler: Option[X -> B]) -> Option[B] {
        match choice {
            Option.None => Option.None,
            Option.Some(result) => match result {
                Either.Left(value) => handler.map(f => f(value)),
                Either.Right(value) => Option.pure(value)
            }
        }
    }

    def law select_identity[X](choice: Option[Either[X, X]]) -> (
        Option.select(choice, Option.pure(types.id[X]))
        ~= choice.map(Either[X, X].fold(types.id[X], types.id[X]))
    ) {
        match choice {
            Option.None => refl,
            Option.Some(result) => match result {
                Either.Left(_) => refl,
                Either.Right(_) => refl
            }
        }
    }

    def law select_distributivity[X, B](
        choice: Either[X, B], first: Option[X -> B], second: Option[X -> B]
    ) -> (
        Option.select(
            Option.pure(choice),
            Option.keep_right(first, second)
        )
        ~= Option.keep_right(
            Option.select(Option.pure(choice), first),
            Option.select(Option.pure(choice), second)
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

    def law select_associativity[X, B, C](
        choice: Option[Either[X, B]],
        route: Option[Either[C, X -> B]],
        handler: Option[C -> X -> B]
    ) -> (
        Option.select(choice, Option.select(route, handler))
        ~= Option.select(
            Option.select(
                choice.map(select_lift_right[X, B, C]),
                route.map(select_route[X, B, C])
            ),
            handler.map(select_apply_pair[X, B, C])
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

    // Monad：后续 Option 可以依赖当前 Some 的值。
    def fn bind[X, B](next: X -> Option[B]) -> (Option[X] -> Option[B]) {
        value => match value {
            Option.None => Option.None,
            Option.Some(item) => next(item)
        }
    }

    method bind[B](next: A -> Option[B]) -> Option[B] {
        value: Option[A] = self;
        Self.bind(next)(value)
    }

    def law bind_left_identity[X, B](value: X, next: X -> Option[B]) -> (
        Option.pure(value).bind(next) ~= next(value)
    ) {
        refl
    }

    def law bind_right_identity[X](value: Option[X]) -> (
        value.bind(Option.pure) ~= value
    ) {
        match value {
            Option.None => refl,
            Option.Some(_) => refl
        }
    }

    def law bind_associativity[X, B, C](
        value: Option[X], first: X -> Option[B], second: B -> Option[C]
    ) -> (
        value.bind(first).bind(second) ~= value.bind(a => first(a).bind(second))
    ) {
        match value {
            Option.None => refl,
            Option.Some(_) => refl
        }
    }

    def law ap_from_bind[X, B](function: Option[X -> B], value: Option[X]) -> (
        Option.ap(function, value)
        ~= function.bind(f => value.bind(a => Option.pure(f(a))))
    ) {
        match function {
            Option.None => refl,
            Option.Some(_) => match value {
                Option.None => refl,
                Option.Some(_) => refl
            }
        }
    }

    def law select_from_bind[X, B](
        choice: Option[Either[X, B]], handler: Option[X -> B]
    ) -> (
        Option.select(choice, handler)
        ~= choice.bind(Either[X, B].fold(
            a => handler.map(f => f(a)),
            Option.pure
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
lifted_inc: Option[Int] -> Option[Int] = Option.map(inc);
sample: Option[Int] = Option.Some(41);
apply_to_sample: (Int -> Int) -> Option[Int] = sample.map;

def law mapping_two_directions() -> (
    (lifted_inc(sample), apply_to_sample(inc)) ~= (Option.Some(42), Option.Some(42))
) {
    refl
}

def law applicative_pair() -> (
    Option.map2(Option.Some(20), Option.Some(22), (a, b) => a + b)
    ~= Option.Some(42)
) {
    refl
}

def law selective_ready_result() -> (
    Option.select[Int, Int](Option.Some(Either.Right(7)), Option.None) ~= Option.Some(7)
) {
    refl
}

def law selective_missing_handler() -> (
    Option.select[Int, Int](Option.Some(Either.Left(7)), Option.None) ~= Option.None
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

// 带目标类型的规范视图保留同一 obj/map；不是把 Some(41) 转换成结构值。
option_monad: Monad = Option;
option_selective: Selective = option_monad;
option_applicative: Applicative = option_selective;
option_functor: Functor[types, types] = option_applicative;

def law inherited_operation_view(value: Option[Int]) -> (
    (option_monad.map(inc)(value), option_functor.map(inc)(value))
    ~= (Option.map(inc)(value), Option.map(inc)(value))
) { refl }

// 应拒绝：bad: Functor[types,types] = Option.Some(41)；它是数据值。
// 应拒绝：bad: Monad = Option[Int]；应用参数得到的是数据类型。
// 应拒绝：type Option[A] <: Monad；构造的数据不具有 Monad 的结构字段。
// 应拒绝：Option[A] <: Functor[types,types]；本声明没有建立这样的数据值视图。
// 应拒绝：把 method map 的参数写成 Self -> B；需要的是元素变换 A -> B。
// 应拒绝：继承 map[X,Y] 时只定义 map[Y]: (A -> Y) -> Option[A] -> Option[Y]。
// Option 的结构成员不隐式固定 A；Option[Int].map 仍是全族操作，self 才固定接收者。
// Right 不需要 handler 的内容，不意味着严格求值会跳过 handler 实参表达式。

// 从已经给出的 Option.ap 回看积结构：先得到配对值，再推广其证明。
// 在 types 上从 Applicative 派生积操作。F 是显式结构参数，不是隐式 self。
app_unit[F: Applicative]: F.obj(Unit) = F.pure(Unit.unit);
app_lift2[F: Applicative, A, B, C]:
    (A -> B -> C, F.obj(A), F.obj(B)) -> F.obj(C) =
    (function, x, y) => F.ap(F.map(function)(x), y);
app_zip[F: Applicative, A, B]: (F.obj(A), F.obj(B)) -> F.obj((A, B)) =
    (x, y) => app_lift2[F](make_pair[A, B], x, y);

option_pair: Option[(Int, Int)] =
    app_zip[option_applicative](Option.Some(20), Option.Some(22));

def law combining_optional_values() -> (option_pair ~= Option.Some((20, 22))) { refl }

// 以下将这个配对行为推广到任意 Applicative，并证明其相容性。
def law app_map_twice[F: Applicative, A, B, C](f: A -> B, g: B -> C, x: F.obj(A)) -> (
    F.map(g)(F.map(f)(x)) ~= F.map(a => g(f(a)))(x)
) { congr_arg(function => function(x), symm(F.composition(f, g))) }

def law app_map_pure[F: Applicative, A, B](f: A -> B, a: A) -> (
    F.map(f)(F.pure(a)) ~= F.pure(f(a))
) { trans(F.map_from_ap(f, F.pure(a)), F.ap_homomorphism(f, a)) }

def law app_ap_pure[F: Applicative, A, B](u: F.obj(A -> B), a: A) -> (
    F.ap(u, F.pure(a)) ~= F.map(f => f(a))(u)
) { trans(F.ap_interchange(u, a), symm(F.map_from_ap(f => f(a), u))) }

def law app_map_ap[F: Applicative, A, B, C](h: B -> C, u: F.obj(A -> B), x: F.obj(A)) -> (
    F.map(h)(F.ap(u, x)) ~= F.ap(F.map(f => a => h(f(a)))(u), x)
) {
    compose = compose_function[A, B, C];
    trans(F.map_from_ap(h, F.ap(u, x)),
        trans(symm(F.ap_composition(F.pure(h), u, x)),
            congr_arg(k => F.ap(k, x),
                trans(congr_arg(k => F.ap(k, u), app_map_pure[F](compose, h)),
                      symm(F.map_from_ap(compose(h), u))))))
}

def law app_ap_map_arg[F: Applicative, A, B, C](u: F.obj(B -> C), g: A -> B, x: F.obj(A)) -> (
    F.ap(u, F.map(g)(x)) ~= F.ap(F.map(h => a => h(g(a)))(u), x)
) {
    compose = compose_function[A, B, C];
    evaluate: ((A -> B) -> A -> C) -> A -> C = k => k(g);
    trans(congr_arg(v => F.ap(u, v), F.map_from_ap(g, x)),
        trans(symm(F.ap_composition(u, F.pure(g), x)),
            congr_arg(k => F.ap(k, x),
                trans(app_ap_pure[F](F.map(compose)(u), g),
                      app_map_twice[F](compose, evaluate, u)))))
}

def law app_map_lift2[F: Applicative, A, B, C, D](
    h: C -> D, f: A -> B -> C, x: F.obj(A), y: F.obj(B)
) -> (
    F.map(h)(app_lift2[F](f, x, y)) ~= app_lift2[F](a => b => h(f(a)(b)), x, y)
) {
    trans(app_map_ap[F](h, F.map(f)(x), y),
          congr_arg(k => F.ap(k, y), app_map_twice[F](f, g => b => h(g(b)), x)))
}

def law app_lift2_map_left[F: Applicative, A, B, C, D](
    k: B -> C -> D, f: A -> B, x: F.obj(A), y: F.obj(C)
) -> (
    app_lift2[F](k, F.map(f)(x), y) ~= app_lift2[F](a => k(f(a)), x, y)
) { congr_arg(h => F.ap(h, y), app_map_twice[F](f, k, x)) }

def law app_lift2_map_right[F: Applicative, A, B, C, D](
    k: A -> C -> D, g: B -> C, x: F.obj(A), y: F.obj(B)
) -> (
    app_lift2[F](k, x, F.map(g)(y)) ~= app_lift2[F](a => b => k(a)(g(b)), x, y)
) {
    trans(app_ap_map_arg[F](F.map(k)(x), g, y),
          congr_arg(h => F.ap(h, y), app_map_twice[F](k, h => b => h(g(b)), x)))
}

def law app_zip_naturality[F: Applicative, A, B, C, D](
    f: A -> C, g: B -> D, x: F.obj(A), y: F.obj(B)
) -> (
    F.map(pair_bifunctor.map((f, g)))(app_zip[F](x, y))
    ~= app_zip[F](F.map(f)(x), F.map(g)(y))
) {
    left = app_map_lift2[F](pair_bifunctor.map((f, g)), make_pair[A, B], x, y);
    right = trans(app_lift2_map_left[F](make_pair[C, D], f, x, F.map(g)(y)),
                  app_lift2_map_right[F](a => d => (f(a), d), g, x, y));
    trans(left, symm(right))
}

def law app_zip_left_unit[F: Applicative, A](x: F.obj(A)) -> (
    F.map(pair_left_unitor[A].hom)(app_zip[F](app_unit[F], x)) ~= x
) {
    inject: A -> (Unit, A) = a => (Unit.unit, a);
    zip_pure = trans(
        congr_arg(k => F.ap(k, x), app_map_pure[F](make_pair[Unit, A], Unit.unit)),
        symm(F.map_from_ap(inject, x)));
    trans(congr_arg(F.map(pair_left_unitor[A].hom), zip_pure),
        trans(app_map_twice[F](inject, pair_left_unitor[A].hom, x),
              congr_arg(function => function(x), F.identity[A])))
}

def law app_zip_right_unit[F: Applicative, A](x: F.obj(A)) -> (
    F.map(pair_right_unitor[A].hom)(app_zip[F](x, app_unit[F])) ~= x
) {
    evaluate: (Unit -> (A, Unit)) -> (A, Unit) = k => k(Unit.unit);
    inject: A -> (A, Unit) = a => (a, Unit.unit);
    zip_pure = trans(app_ap_pure[F](F.map(make_pair[A, Unit])(x), Unit.unit),
                     app_map_twice[F](make_pair[A, Unit], evaluate, x));
    trans(congr_arg(F.map(pair_right_unitor[A].hom), zip_pure),
        trans(app_map_twice[F](inject, pair_right_unitor[A].hom, x),
              congr_arg(function => function(x), F.identity[A])))
}

def law app_zip_associativity[F: Applicative, A, B, C](x: F.obj(A), y: F.obj(B), z: F.obj(C)) -> (
    F.map(pair_associator[A, B, C].hom)(app_zip[F](app_zip[F](x, y), z))
    ~= app_zip[F](x, app_zip[F](y, z))
) {
    // 两边均化到 ap(ap(map(a => b => c => (a,(b,c)))(x),y),z)。
    reassociate: (p: (A, B)) -> C -> (A, (B, C)) = p => c => (p.0, (p.1, c));
    left = trans(app_map_lift2[F](pair_associator[A, B, C].hom, make_pair[(A, B), C], app_zip[F](x, y), z),
                 congr_arg(k => F.ap(k, z), app_map_lift2[F](reassociate, make_pair[A, B], x, y)));
    u = F.map(make_pair[A, (B, C)])(x);
    v = F.map(make_pair[B, C])(y);
    compose = compose_function[C, (B, C), (A, (B, C))];
    evaluate: ((C -> (B, C)) -> C -> (A, (B, C))) -> B -> C -> (A, (B, C)) =
        k => b => k(make_pair[B, C](b));
    normalize = trans(app_map_twice[F](compose, evaluate, u),
                      app_map_twice[F](make_pair[A, (B, C)], h => evaluate(compose(h)), x));
    right = trans(symm(F.ap_composition(u, v, z)),
        trans(congr_arg(k => F.ap(k, z), app_ap_map_arg[F](F.map(compose)(u), make_pair[B, C], y)),
              congr_arg(k => F.ap(F.ap(k, y), z), normalize)));
    trans(left, symm(right))
}

def law option_product_naturality[A, B, C, D](
    f: A -> C, g: B -> D, x: Option[A], y: Option[B]
) -> (
    Option.map(pair_bifunctor.map((f, g)))(app_zip[option_applicative](x, y))
    ~= app_zip[option_applicative](Option.map(f)(x), Option.map(g)(y))
) { app_zip_naturality[option_applicative](f, g, x, y) }

def law option_product_units[A](x: Option[A]) -> (
    (Option.map(pair_left_unitor[A].hom)(app_zip[option_applicative](app_unit[option_applicative], x)),
     Option.map(pair_right_unitor[A].hom)(app_zip[option_applicative](x, app_unit[option_applicative])))
    ~= (x, x)
) { pair_congr(app_zip_left_unit[option_applicative](x), app_zip_right_unit[option_applicative](x)) }

def law option_product_associativity[A, B, C](x: Option[A], y: Option[B], z: Option[C]) -> (
    Option.map(pair_associator[A, B, C].hom)(app_zip[option_applicative](app_zip[option_applicative](x, y), z))
    ~= app_zip[option_applicative](x, app_zip[option_applicative](y, z))
) { app_zip_associativity[option_applicative](x, y, z) }

// 将普通值放入 Option：NaturalTransformation 与 Some 注入。
type NaturalTransformation[C: Category, D: Category, F: Functor[C, D], G: Functor[C, D]] {
    app[X: C.Obj]: D.Hom[F.obj(X), G.obj(X)];
    law naturality[X: C.Obj, Y: C.Obj](f: C.Hom[X, Y]) -> (
        D.compose(G.map(f), app[X]) ~= D.compose(app[Y], F.map(f))
    );
}

// alpha 是整个自然变换，alpha.app 是按源对象索引的态射族。
// alpha.app[X]: D.Hom[F.obj(X),G.obj(X)] 选择一个分量，不把 X 传给态射。
// 应拒绝：对一般 D 直接写 alpha.app[X](value)；Hom 未必是函数。
some_transformation: NaturalTransformation[
    types, types, identity_functor[types], option_functor
] = NaturalTransformation[types, types, identity_functor[types], option_functor] {
    app[X: Type] = value => Option.Some(value),
    naturality[X: Type, Y: Type] = f => funext(value => refl),
};

// 这里目标是 types，Hom 展开为函数，才可以继续传入 Int 数据。
some_at_int: Int -> Option[Int] = some_transformation.app[Int];

def law injecting_a_value() -> (some_transformation.app[Int](41) ~= Option.Some(41)) { refl }
def law applying_a_component() -> (some_at_int(41) ~= Option.Some(41)) { refl }

// 恒等自然变换是同一结构的一个通用构造，证据来自范畴的单位律。
identity_transformation[C: Category, D: Category, F: Functor[C, D]]:
    NaturalTransformation[C, D, F, F] = NaturalTransformation[C, D, F, F] {
    app[X: C.Obj] = D.id[F.obj(X)],
    naturality[X: C.Obj, Y: C.Obj] = f => trans(D.right_identity(F.map(f)), symm(D.left_identity(F.map(f)))),
};

// 可逆地添加 Unit：先定义该实际数据形状的函子，再给自然同构契约。
unit_product_functor: Functor[types, types] = Functor[types, types] {
    obj = X => (Unit, X),
    map[X, Y] = f => pair => (pair.0, f(pair.1)),
    identity[X] = funext(pair => match pair { (unit, value) => refl }),
    composition[X, Y, Z] = (f, g) => funext(pair => refl),
};

add_unit: NaturalTransformation[
    types, types, identity_functor[types], unit_product_functor
] = NaturalTransformation[types, types, identity_functor[types], unit_product_functor] {
    app[X] = pair_left_unitor[X].inv,
    naturality[X, Y] = f => funext(value => refl),
};

remove_unit: NaturalTransformation[
    types, types, unit_product_functor, identity_functor[types]
] = NaturalTransformation[types, types, unit_product_functor, identity_functor[types]] {
    app[X] = pair_left_unitor[X].hom,
    naturality[X, Y] = f => funext(pair => refl),
};

type NaturalIsomorphism[C: Category, D: Category, F: Functor[C, D], G: Functor[C, D]] {
    hom: NaturalTransformation[C, D, F, G];
    inv: NaturalTransformation[C, D, G, F];
    law inv_hom[X: C.Obj] -> (D.compose(inv.app[X], hom.app[X]) ~= D.id[F.obj(X)]);
    law hom_inv[X: C.Obj] -> (D.compose(hom.app[X], inv.app[X]) ~= D.id[G.obj(X)]);
}

unit_product_isomorphism: NaturalIsomorphism[
    types, types, unit_product_functor, identity_functor[types]
] = NaturalIsomorphism[types, types, unit_product_functor, identity_functor[types]] {
    hom = remove_unit,
    inv = add_unit,
    inv_hom[X] = pair_left_unitor[X].inv_hom,
    hom_inv[X] = pair_left_unitor[X].hom_inv,
};

def law adding_and_removing_unit() -> (
    unit_product_isomorphism.hom.app[Int](unit_product_isomorphism.inv.app[Int](42)) ~= 42
) { refl }

// 保留通用的恒等自然同构构造；上面的 Unit 例子展示了不同形状之间的同构。
identity_natural_isomorphism[C: Category, D: Category, F: Functor[C, D]]:
    NaturalIsomorphism[C, D, F, F] = NaturalIsomorphism[C, D, F, F] {
    hom = identity_transformation[C, D, F],
    inv = identity_transformation[C, D, F],
    inv_hom[X: C.Obj] = D.left_identity(D.id[F.obj(X)]),
    hom_inv[X: C.Obj] = D.left_identity(D.id[F.obj(X)]),
};
```

## 06-sequences.sp · Sequence 与实际表示

```spore
// Sequence 是有限密集序列的观察契约：索引恰好在 [0, len) 内时有值。
// 从契约选择表示，再证明表示的观察满足它；依赖 05 的 Option。

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
    case Cons(head: A, tail: LinkedList[A]);

    // 递归节点和构造结果固定为 LinkedList[A]，不承诺任意子类型的额外要求。
    empty: LinkedList[A] = LinkedList.Nil;

    def fn singleton(value: A) -> LinkedList[A] {
        LinkedList.Cons(value, empty)
    }

    method len() -> Nat {
        values: LinkedList[A] = self;
        match values {
            LinkedList.Nil => 0,
            LinkedList.Cons(_, tail) => Nat.Succ(tail.len())
        }
    }

    method get(index: Nat) -> Option[A] {
        values: LinkedList[A] = self;
        match values {
            LinkedList.Nil => Option.None,
            LinkedList.Cons(head, tail) => match index {
                Nat.Zero => Option.Some(head),
                Nat.Succ(previous) => tail.get(previous)
            }
        }
    }

    method prepend(value: A) -> LinkedList[A] {
        values: LinkedList[A] = self;
        LinkedList.Cons(value, values)
    }

    method append(value: A) -> LinkedList[A] {
        values: LinkedList[A] = self;
        match values {
            LinkedList.Nil => LinkedList[A].singleton(value),
            LinkedList.Cons(head, tail) => LinkedList.Cons(head, tail.append(value))
        }
    }

    // 与 Option 相同的 Functor 操作形状，数据表示改为递归节点。
    def fn map[B](function: A -> B) -> (LinkedList[A] -> LinkedList[B]) {
        values => match values {
            LinkedList.Nil => LinkedList[B].Nil,
            LinkedList.Cons(head, tail) =>
                LinkedList[B].Cons(function(head), LinkedList[A].map(function)(tail))
        }
    }

    method map[B](function: A -> B) -> LinkedList[B] {
        values: LinkedList[A] = self;
        LinkedList[A].map(function)(values)
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

## 07-mappings.sp · Mapping 与 BoolMap

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

// enumeration 同时排除重复键、缺键和额外的键；用两个实际槽位实现。
type BoolMap[V] {
    false_value: Option[V];
    true_value: Option[V];

    // 只重建两个槽位，结果是 BoolMap[V]；不据此构造带额外字段或约束的子类型。
    empty: BoolMap[V] = BoolMap { false_value = Option.None, true_value = Option.None };

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

    def fn put(map: BoolMap[V], key: Bool, value: V) -> BoolMap[V] {
        match key {
            false => BoolMap { false_value = Option.Some(value), true_value = map.true_value },
            true => BoolMap { false_value = map.false_value, true_value = Option.Some(value) }
        }
    }

    method put(key: Bool, value: V) -> BoolMap[V] {
        map: BoolMap[V] = self;
        BoolMap[V].put(map, key, value)
    }

    def fn remove(map: BoolMap[V], key: Bool) -> BoolMap[V] {
        match key {
            false => BoolMap { false_value = Option.None, true_value = map.true_value },
            true => BoolMap { false_value = map.false_value, true_value = Option.None }
        }
    }

    method remove(key: Bool) -> BoolMap[V] {
        map: BoolMap[V] = self;
        BoolMap[V].remove(map, key)
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

// 已有 BoolMap 的查询与枚举证据，再用更新契约检查 put/remove。
// 更新定律比较前后两个状态，载体 M 在实例中取 BoolMap[V]。
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

## 08-indexed-types.sp · 索引类型与 Vec

```spore
// 用 Fin[n] 表达有效索引，用 Vec[A, n] 表达长度；再证明映射保持索引观察。
// Nat 采用 SKILL.md 的归纳背景。类型参数与值索引分别显式绑定。

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
