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
  ['inferred function result', 'type Box[A] { value: A; def fn make(value: A) { Box[A] { value = value } } }'],
  ['same name in separate member domains', 'type Box[A] { value: A; def fn get(value: Box[A]) -> A { value.value } method get() -> A { value: Box[A] = self; Self.get(value) } }'],
  ['type function as lambda', 'type Box[A] { value: A; make = (value: A) => Box[A] { value = value }; }'],
  ['local binding and method extraction', 'def fn advance(x: Counter) -> Counter { bound = x.next; bound() }'],
  ['empty record construction', 'type Empty {} empty: Empty = Empty {};'],
  ['nested type scope', 'type Outer { type Inner { def fn identity(value: Self) -> Self { value } } }'],
  ['empty elimination', 'def fn absurd[A](x: Never) -> A { match x {} }'],
  ['parenthesized record subject', 'def fn inspect() -> Int { match (Box { value = 1 }) { b => b.value } }'],
  ['trailing separators', 'type Box { value: Int; def fn make(value: Int,) -> Box { Box { value = value, } } }'],
  ['subtype proposition', 'type Evidence[S, T] { law relation() -> (S <: T); }'],
  ['universe background rule', 'Universe<u>: Universe<next(u)>; Prop = Universe<0>; Type = Universe<1>;'],
  ['universe polymorphic function', 'def fn keep<u>[A: Universe<u>](value: A) -> A { value }'],
  ['level max and inferred level', 'type PairType<u, v> { carrier: Universe<max(u, next(v))>; } chosen: Universe<_> = Int;'],
  ['data family with functor attachment', 'type Box[A: Type]: Functor[types,types] { case Pack(value: A); obj = X => Box[X]; map[X,Y] = f => value => match value { Box.Pack(x) => Box.Pack(f(x)) }; identity[X] = funext(value => match value { Box.Pack(x) => refl }); composition[X,Y,Z] = (f,g) => funext(value => match value { Box.Pack(x) => refl }); }'],
  ['generic function type definition', 'Hom[X: Type, Y: Type] = X -> Y;'],
  ['dependent function type as value', 'Reflexivity<u>: Prop = (A: Universe<u>) -> (x: A) -> (x ~= x);'],
  ['proof value and proof function', 'type Evidence { law same[X] -> (X ~= X); law again[X]() -> (X ~= X); } def law reflexive[X] -> (X ~= X) { refl }'],
  ['bare equality annotation', 'def fn preserve[A, x: A, y: A](proof: x ~= y) -> (x ~= y) { proof }'],
  ['tuple function domain and pattern', 'def fn swap[A, B](pair: (A, B)) -> (B, A) { match pair { (a, b) => (b, a) } }'],
  ['parameterized structure value', 'identity_functor[C: Category]: Functor[C,C] = Functor[C,C] { obj = x => x, map[X: C.Obj,Y: C.Obj] = f => f, identity[X: C.Obj] = refl, composition[X: C.Obj,Y: C.Obj,Z: C.Obj] = (f,g) => refl, };'],
  ['dependent generic record completion', 'types: LargeCategory<1> = LargeCategory<1> { Obj = Type, Hom[X: Obj,Y: Obj] = X -> Y, id[X: Obj] = x => x, compose[X: Obj,Y: Obj,Z: Obj] = (g,f) => x => g(f(x)), left_identity[X: Obj,Y: Obj] = f => funext(x => refl), right_identity[X: Obj,Y: Obj] = f => funext(x => refl), associativity[W: Obj,X: Obj,Y: Obj,Z: Obj] = (f,g,h) => funext(x => refl), };'],
  ['select then apply a component', 'some_at_int: Int -> Option[Int] = some_transformation.app[Int]; answer = some_at_int(41);'],
];
const rejected = [
  ['old bare def', 'def id(x: Int) -> Int { x }'],
  ['old proof declaration', 'proof same() -> (1 ~= 1) { refl }'],
  ['static modifier', 'type Box { static size: Int = 1; }'],
  ['colon-equals binding', 'size: Int := 1;'],
  ['hash method selection', 'next = value#next();'],
  ['old subtype operator', 'S :> T;'],
  ['equals body for def law', 'def law same() -> (1 ~= 1) = refl;'],
  ['angle bracket argument pair', 'value = compose(<f, g>);'],
  ['level next with two arguments', 'value: Universe<next(u, v)> = Int;'],
  ['empty universe argument list', 'value: Universe<> = Int;'],
  ['body on fn field', 'type Box { fn get() -> Int { 1 } }'],
  ['body on law field', 'type Box { law same() -> (1 ~= 1) { refl } }'],
  ['bodyless method', 'type Box { method get() -> Int; }'],
  ['redundant def method', 'type Box { def method get() -> Int { 1 } }'],
  ['top-level method', 'method get() -> Int { 1 }'],
  ['definition in record completion', 'x = Box { def fn get() -> Int { 1 } };'],
  ['definition in relation completion', 'S <: T { def law same() -> (1 ~= 1) { refl } }'],
  ['colon in record completion', 'x = Box { value: 1 };'],
  ['missing field separator', 'x = Pair { first = 1 second = 2 };'],
  ['comma without a parameter', 'def fn get(,) -> Int { 1 }'],
  ['comma without a field', 'x = Empty {,};'],
  ['comma without an arm', 'def fn absurd(x: Never) -> Int { match x {,} }'],
  ['unclosed type', 'type Box { value: Int;'],
  ['def law in generic record completion', 'f = Functor[C,C] { def law identity[X: C.Obj] -> (X ~= X) { refl } };'],
  ['bodyless generic field completion', 'f = Functor[C,C] { map[X: C.Obj,Y: C.Obj] };'],
  ['function declaration in generic field completion', 'f = Functor[C,C] { map[X: C.Obj,Y: C.Obj](arrow) = arrow };'],
  ['semicolon in generic record completion', 'f = Functor[C,C] { map[X: C.Obj,Y: C.Obj] = arrow => arrow; };'],
];

// These are deliberately recognized. Ohm has no type checker, universe solver,
// member resolver or proof kernel; semantic review must reject these programs.
const semanticErrors = [
  ['non-cumulative universe', 'def fn lift(A: Universe<1>) -> Universe<2> { A }'],
  ['reapplying complete Self', 'type Box[A] { method wrong[B]() -> Self[B] { self } }'],
  ['constructing open Self from parent fields', 'type Counter { value: Int; def fn make(value: Int) -> Self { Self { value = value } } }'],
  ['data value used as functor structure', 'wrong: Functor[types, types] = Option.Some(1);'],
  ['argument count mismatch', 'add: (Int, Int) -> Int = (x, y) => x + y; wrong = add((1, 2));'],
  ['false reflexivity proof', 'def law wrong() -> (1 ~= 2) { refl }'],
  ['ordinary structure value disguised as a type', 'type IdentityFunctor[C: Category]: Functor[C,C] { obj = x => x; map[X: C.Obj,Y: C.Obj] = f => f; identity[X: C.Obj] = refl; composition[X: C.Obj,Y: C.Obj,Z: C.Obj] = (f,g) => refl; }'],
  ['data family attachment maps a different family', 'type Option[A: Type]: Monad { case None; case Some(value: A); obj = X => (Unit,X); }'],
  ['applied data family used as monad structure', 'wrong: Monad = Option[Int];'],
  ['applying a morphism in an arbitrary category', 'def fn wrong[C: Category,D: Category,F: Functor[C,D],G: Functor[C,D],X: C.Obj](alpha: NaturalTransformation[C,D,F,G], value: Int) -> Int { alpha.app[X](value) }'],
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
