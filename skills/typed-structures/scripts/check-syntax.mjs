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
  ['complete examples', blocks.join('\n')],
  ['inferred function result', 'type Box[A] { value: A; def fn make(value: A) { Self { value = value } } }'],
  ['same name in separate member domains', 'type Box[A] { value: A; def fn get(value: Self) -> A { value.value } method get() -> A { Self.get(self) } }'],
  ['type function as lambda', 'type Box[A] { value: A; make = (value: A) => Self { value = value }; }'],
  ['local binding and method extraction', 'def fn advance(x: Counter) -> Counter { bound = x.next; bound() }'],
  ['empty record construction', 'type Empty {} empty: Empty = Empty {};'],
  ['nested type scope', 'type Outer { type Inner { def fn identity(value: Self) -> Self { value } } }'],
  ['empty elimination', 'def fn absurd[A](x: Never) -> A { match x {} }'],
  ['parenthesized record subject', 'def fn inspect() -> Int { match (Box { value = 1 }) { b => b.value } }'],
  ['trailing separators', 'type Box { value: Int; def fn make(value: Int,) -> Self { Self { value = value, } } }'],
  ['subtype proposition', 'type Evidence[S, T] { law relation() -> (S <: T); }'],
];
const rejected = [
  ['old bare def', 'def id(x: Int) -> Int { x }'],
  ['old proof declaration', 'proof same() -> (1 ~= 1) { refl }'],
  ['static modifier', 'type Box { static size: Int = 1; }'],
  ['colon-equals binding', 'size: Int := 1;'],
  ['hash method selection', 'next = value#next();'],
  ['old subtype operator', 'S :> T;'],
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
];

const directory = mkdtempSync(join(tmpdir(), 'typed-structures-syntax-'));
try {
  for (const [expected, cases] of [[true, accepted], [false, rejected]]) {
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
  console.log(`${blocks.length} example blocks, ${accepted.length - 1} valid fixtures, ${rejected.length} invalid fixtures: passed (syntax only)`);
} finally {
  rmSync(directory, {recursive: true, force: true});
}
