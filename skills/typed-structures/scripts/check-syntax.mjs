#!/usr/bin/env node
// Run with a global ohm CLI on PATH, or set OHM_BIN to its executable path.
// Validates recognition only; name resolution, types and laws need separate review.
import {mkdtempSync, readFileSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, join, resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const base = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const grammar = join(base, 'grammar.ohm');
const examples = readFileSync(join(base, 'examples.md'), 'utf8');
const blocks = [...examples.matchAll(/^```spore\r?\n([\s\S]*?)^```\s*$/gm)]
  .map(match => match[1]);
if (blocks.length === 0) throw new Error('No spore example blocks found');

const accepted = [
  ["type-side function with inferred result", "type Box[A] { value: A; static def fn make(value: A) { Box[A] { value: value } } }"],
  ["same name across member domains", "type Box { value: Int; static value: Int = 1; } box: Box = Box { value: 2 };"],
  ["static operation and bound method", "type Box[A] { value: A; static def fn get(value: Box[A]) -> A { value.value } method get() -> A { value: Box[A] = self; Self.get(value) } }"],
  ["type function as lambda", "type Box[A] { value: A; static make: A -> Box[A] = value => Box[A] { value: value }; }"],
  ["local binding and method extraction", "def fn advance(x: Counter) -> Counter { bound = x.next; bound() }"],
  ["empty record and empty branch", "type Unit {} type Flag { case On; case Off; } unit: Unit = Unit {}; on: Flag = Flag.On {};"],
  ["nested type scope", "type Outer { type Inner { static def fn identity(value: Self) -> Self { value } } }"],
  ["empty elimination", "def fn absurd[A](x: Never) -> A { match x {} }"],
  ["parenthesized record subject", "def fn inspect() -> Int { match (Box { value: 1 }) { Box { value } => value } }"],
  ["trailing separators", "type Box { value: Int; static def fn make(value: Int,) -> Box { Box { value: value, } } }"],
  ["subtype proposition and inheritance", "type Parent { value: Int; } type Child <: Parent { tag: Str; } type Evidence[S,T] { law relation() -> (S <: T); }"],
  ["universe background", "Universe<u>: Universe<next(u)>; Prop = Universe<0>; Type = Universe<1>;"],
  ["universe polymorphic function", "def fn keep<u>[A: Universe<u>](value: A) -> A { value }"],
  ["max and inferred level", "type PairType<u,v> { carrier: Universe<max(u,next(v))>; } chosen: Universe<_> = Int;"],
  ["family-wide static completion", "type Box[A: Type]: Functor[types,types] { case Pack { value: A; } static obj: Type -> Type = X => Box[X]; static map[X,Y]: (X -> Y) -> Box[X] -> Box[Y] = f => value => match value { Box[X].Pack { value: x } => Box[Y].Pack { value: f(x) } }; static identity[X] = funext(value => match value { Box[X].Pack { value: x } => refl }); static composition[X,Y,Z] = (f,g) => funext(value => match value { Box[X].Pack { value: x } => refl }); }"],
  ["generic type definition", "Hom[X: Type,Y: Type] = X -> Y;"],
  ["dependent proposition", "Reflexivity<u>: Prop = (A: Universe<u>) -> (x: A) -> (x ~= x);"],
  ["proof value and proof function", "type Evidence { law same[X] -> (X ~= X); law again[X]() -> (X ~= X); } def law reflexive[X] -> (X ~= X) { refl }"],
  ["static proof body", "type Box { static def law same[X] -> (X ~= X) { refl } }"],
  ["bare equality annotation", "def fn preserve[A,x: A,y: A](proof: x ~= y) -> (x ~= y) { proof }"],
  ["tuple function domain and pattern", "def fn swap[A,B](pair: (A,B)) -> (B,A) { match pair { (a,b) => (b,a) } }"],
  ["generic structure completion", "identity_functor[C: Category]: Functor[C,C] = Functor[C,C] { obj: x => x, map[X: C.Obj,Y: C.Obj]: f => f, identity[X: C.Obj]: refl, composition[X: C.Obj,Y: C.Obj,Z: C.Obj]: (f,g) => refl, };"],
  ["dependent record completion", "types: LargeCategory<1> = LargeCategory<1> { Obj: Type, Hom[X: Obj,Y: Obj]: X -> Y, id[X: Obj]: x => x, compose[X: Obj,Y: Obj,Z: Obj]: (g,f) => x => g(f(x)), left_identity[X: Obj,Y: Obj]: f => funext(x => refl), right_identity[X: Obj,Y: Obj]: f => funext(x => refl), associativity[W: Obj,X: Obj,Y: Obj,Z: Obj]: (f,g,h) => funext(x => refl) };"],
  ["select then apply component", "some_at_int: Int -> Option[Int] = some_transformation.app[Int]; answer = some_at_int(41);"],
  ["type item satisfies branch", "type X[A] { v: A; case L; case R; } type Z: X[Int].L { static v: Int = 1; data: Str; } z: Z = Z { data: \"hello\" }; left: X[Int].L = X[Int].L { v: 1 }; item: X[Int].L = Z;"],
  ["empty contract and independent data", "type Unit {} type ComplexUnit: Unit { real: Int; imaginary: Int; } z: ComplexUnit = ComplexUnit { real: 1, imaginary: 2 }; item: Unit = ComplexUnit;"],
  ["nested path and generic ownership", "type Packet[A] { source: Str; case Data { sequence: Nat; case Converted[B] { payload: B; } } case Closed; } p: Packet[Int].Data.Converted[Str] = Packet[Int].Data.Converted[Str] { source: \"s\", sequence: 1, payload: \"ok\" };"],
  ["named and rest patterns", "def fn read[A](p: Packet[A]) -> Str { match p { Packet[A].Data.Single { source: name, payload: _, ... } => name, Packet[A].Closed { source } => source } }"],
  ["nested branch patterns", "def fn first[A](x: Option[Option[A]]) -> Bool { match x { Option[_].Some { value: Option[_].Some { value: _ } } => true, Option[_].Some { value: Option[_].None {} } => false, Option[_].None {} => false } }"],
  ["case-bound index and constructed return index", "type Fin: Nat -> Type { case Zero[n: Nat] -> Fin[Nat.Succ { previous: n }]; case Succ[n: Nat] -> Fin[Nat.Succ { previous: n }] { previous: Fin[n]; } } zero: Fin[1] = Fin.Zero[Nat.Zero {}] {};"],
  ["case-bound generic data", "type Vec: Type -> Nat -> Type { case Nil[A] -> Vec[A,Nat.Zero {}]; case Cons[A,n: Nat] -> Vec[A,Nat.Succ { previous: n }] { head: A; tail: Vec[A,n]; } } xs: Vec[Int,1] = Vec.Cons[Int,0] { head: 1, tail: Vec.Nil[Int] {} };"],
  ["indexed match", "def fn head[A,n: Nat](x: Vec[A,Nat.Succ { previous: n }]) -> A { match x { Vec.Cons[A,n] { head, ... } => head } }"],
  ["explicit constructor lambda", "some: Int -> Option[Int] = value => Option[Int].Some { value: value };"],
  ["explicit adapter with evidence", "def fn normalize[A,B](source: RoundTrip[A,B]) -> Idempotent[B] { Idempotent[B] { run: value => source.encode(source.decode(value)), idempotent: value => congr_arg(source.encode, source.round_trip(source.decode(value))) } }"],
];
const rejected = [
  ["old bare def", "def id(x: Int) -> Int { x }"],
  ["old proof declaration", "proof same() -> (1 ~= 1) { refl }"],
  ["missing static value", "type Box { size: Int = 1; }"],
  ["missing static function", "type Box { def fn get() -> Int { 1 } }"],
  ["missing static law", "type Box { def law same() -> (1 ~= 1) { refl } }"],
  ["top-level static", "static size: Int = 1;"],
  ["static instance requirement", "type Box { static size: Int; }"],
  ["static method", "type Box { static method get() -> Int { 1 } }"],
  ["colon-equals", "size: Int := 1;"],
  ["hash selection", "next = value#next();"],
  ["old subtype operator", "S :> T;"],
  ["equals body for def law", "def law same() -> (1 ~= 1) = refl;"],
  ["angle bracket arguments", "value = compose(<f,g>);"],
  ["invalid next arity", "value: Universe<next(u,v)> = Int;"],
  ["empty universe arguments", "value: Universe<> = Int;"],
  ["body on fn declaration", "type Box { fn get() -> Int { 1 } }"],
  ["body on law declaration", "type Box { law same() -> (1 ~= 1) { refl } }"],
  ["bodyless method", "type Box { method get() -> Int; }"],
  ["redundant def method", "type Box { def method get() -> Int { 1 } }"],
  ["top-level method", "method get() -> Int { 1 }"],
  ["function declaration in construction", "x = Box { fn get() -> Int; };"],
  ["field declaration in construction", "x = Box { value: Int; };"],
  ["definition in construction", "x = Box { static def fn get() -> Int { 1 } };"],
  ["equals in construction", "x = Box { value = 1 };"],
  ["generic field equals", "f = Functor[C,C] { identity[X]: refl, map[X,Y] = f => f };"],
  ["missing field separator", "x = Pair { first: 1 second: 2 };"],
  ["empty parameter with comma", "def fn get(,) -> Int { 1 }"],
  ["empty field with comma", "x = Empty {,};"],
  ["empty arm with comma", "def fn absurd(x: Never) -> Int { match x {,} }"],
  ["unclosed type", "type Box { value: Int;"],
  ["proof definition in construction", "f = Functor[C,C] { def law identity[X] -> (X ~= X) { refl } };"],
  ["missing generic field value", "f = Functor[C,C] { map[X,Y] };"],
  ["function header in construction", "f = Functor[C,C] { map[X,Y](arrow): arrow };"],
  ["semicolon in construction", "f = Functor[C,C] { map[X,Y]: arrow => arrow; };"],
  ["positional case declaration", "type Box[A] { case Pack(value: A); }"],
  ["positional case pattern", "def fn get(x: Option[Int]) -> Int { match x { Option[Int].Some(v) => v, Option[Int].None {} => 0 } }"],
  ["bare empty branch pattern", "def fn get(x: Flag) -> Int { match x { Flag.On => 1 } }"],
  ["automatic relation completion", "RoundTrip[A,B] <: Idempotent[B] { run: value => value }"],
  ["old forall relation", "forall[A] { S[A] <: T[A] { value: self.value } }"],
];

// Recognized syntax, but each named semantic error requires separate manual review.
// Ohm cannot check membership, indices, member lookup, universes or proofs.
const semanticErrors = [
  ["non-cumulative universe", "def fn lift(A: Universe<1>) -> Universe<2> { A }"],
  ["reapplying complete Self", "type Box[A] { method wrong[B]() -> Self[B] { self } }"],
  ["open Self missing subtype fields", "type Counter { value: Int; static def fn make(value: Int) -> Self { Self { value: value } } }"],
  ["data value is not a functor structure", "wrong: Functor[types,types] = Option[Int].Some { value: 1 };"],
  ["argument count mismatch", "add: (Int,Int) -> Int = (x,y) => x+y; wrong = add((1,2));"],
  ["false reflexivity", "def law wrong() -> (1 ~= 2) { refl }"],
  ["family obj mismatch", "type Option[A: Type]: Monad { case None; case Some { value: A; } static obj: Type -> Type = X => (Unit,X); }"],
  ["applied family is not the full structure", "wrong: Monad = Option[Int];"],
  ["arbitrary morphism is not a function", "def fn wrong[C: Category,D: Category,F: Functor[C,D],G: Functor[C,D],X: C.Obj](alpha: NaturalTransformation[C,D,F,G], value: Int) -> Int { alpha.app[X](value) }"],
  ["unselected branch", "type X[A] { v: A; case L; case R; } wrong: X[Int] = X[Int] { v: 1 };"],
  ["missing public field", "type X[A] { v: A; case L; case R; } wrong: X[Int].L = X[Int].L {};"],
  ["illegal sibling path", "type X[A] { case L; case R; } wrong = X[Int].L.R {};"],
  ["parent generic moved to branch", "type X[A] { v: A; case L; } wrong = X.L[Int] { v: 1 };"],
  ["case generic moved to parent", "type Vec: Type -> Nat -> Type { case Nil[A] -> Vec[A,0]; } wrong = Vec[Int,0].Nil {};"],
  ["branch type used as value", "type Flag { case On; case Off; } wrong: Flag = Flag.On;"],
  ["branch type called as function", "type Box[A] { case Pack { value: A; } } wrong = Box[Int].Pack(1);"],
  ["instance fallback to static", "type Z { static v: Int = 1; data: Str; } z: Z = Z { data: \"hi\" }; wrong = z.v;"],
  ["type item membership is not instance subtyping", "type X[A] { v: A; case L; } type Z: X[Int].L { static v: Int = 1; data: Str; } z: Z = Z { data: \"hi\" }; wrong: X[Int].L = z;"],
  ["non-leaf construction", "type Packet { source: Str; case Data { case Single { value: Int; } } } wrong = Packet.Data { source: \"s\" };"],
  ["field shadowing on path", "type Packet { source: Str; case Data { source: Int; } }"],
  ["duplicate instance member", "type Box { value: Int; method value() -> Int { 1 } }"],
  ["duplicate static member", "type Box { static size: Int = 1; static size: Int = 2; }"],
  ["duplicate construction field", "type Box { value: Int; } wrong = Box { value: 1, value: 2 };"],
  ["wrong return index", "type Fin: Nat -> Type { case Zero[n: Nat] -> Fin[Nat.Succ { previous: n }]; } wrong: Fin[0] = Fin.Zero[0] {};"],
  ["wrong expression index", "type Expr: Type -> Type { case IntLit -> Expr[Int] { value: Int; } } wrong: Expr[Bool] = Expr.IntLit { value: 1 };"],
  ["missing explicit adapter", "wrong: Sequence[Int] = LinkedList[Int].Nil {};"],
  ["no implicit field projection", "type Box { value: Int; } wrong: Box -> Int = Box.value;"],
  ["static cannot capture instance data", "type Box { value: Int; static next: Int = value + 1; }"],
  ["same structure does not equate data types", "type Unit {} type ComplexUnit: Unit { real: Int; imaginary: Int; } type TextUnit: Unit { text: Str; } wrong: ComplexUnit = TextUnit { text: \"hi\" };"],
];

const directory = mkdtempSync(join(tmpdir(), 'typed-structures-syntax-'));
try {
  const modules = blocks.map((block, index) => [`example ${index + 1}`, block]);
  modules.push(['complete examples', blocks.join('\n')]);
  for (const [expected, cases] of [[true, modules], [true, accepted], [false, rejected], [true, semanticErrors]]) {
    for (const [name, source] of cases) {
      const input = join(directory, 'input.sp');
      writeFileSync(input, source);
      const result = spawnSync(process.env.OHM_BIN || 'ohm',
        ['match', input, '-f', grammar, '-g', 'TypedStructures'], {encoding: 'utf8'});
      if (result.error) throw result.error;
      if (result.signal || ![0, 1].includes(result.status)) {
        throw new Error(`${name}: unexpected CLI termination\n${result.stderr}`);
      }
      if ((result.status === 0) !== expected) {
        throw new Error(`${name}: expected ${expected ? 'acceptance' : 'rejection'}\n${result.stderr}`);
      }
    }
  }
  console.log(`${blocks.length} example blocks and joined module, ${accepted.length} accepted fixtures, ${rejected.length} rejected fixtures: passed (syntax only)`);
  console.log(`${semanticErrors.length} semantic-error fixtures were recognized; rejecting their meaning requires separate review, not Ohm`);
} finally {
  rmSync(directory, {recursive: true, force: true});
}
