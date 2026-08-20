Sumitsubo verifies that source code stays aligned with its specification. The
specification is the reference line; the source code is the material.

## Alignment

The specification is the baseline: verification runs from specification to
source code. Sumitsubo reports the difference and does not decide which side is
wrong — correcting the specification is as valid an outcome as correcting the
code.

Several mechanisms establish alignment. Known so far:

| Mechanism | The specification declares                                             | Verified against                |
|-----------|------------------------------------------------------------------------|---------------------------------|
| Glossary  | The domain vocabulary, and the words rejected in its place.            | Words a person wrote: comments, and prose.       |
| Contract  | Public interfaces, and the interface an internal caller must go through.| Structure of the source code.   |
| Behavior  | Behaviors in a BDD style.                                              | Test code declaring which behavior it implements. |

The set is not closed, and each mechanism takes its shape from what can
actually be verified — see Dogfooding.

## Dogfooding

Sumitsubo verifies its own specification. That specification is written as the
verification catches up to it, never ahead of it: a specification the tool
cannot verify is a document, not a reference line. Until a mechanism can check
it, the absence of a specification here is deliberate.

## Glossary

| Term                       | Description                                                                                                          |
|----------------------------|----------------------------------------------------------------------------------------------------------------------|
| Specification              | The .md file(s) which describes the behavior of the application.                                                     |
| Structured Specification   | The machine-readable file(s) which can generate the .md specification or render as the part of the specification.    |
| Verifiable Specification   | The part of the structured specification a mechanism can check against source code.                                  |
| Source Code                | The code which is verified by the specification. Glossary and Contract verify the implementation, Behavior the tests. |
| AST (Abstract Syntax Tree) | The tree structure which represents the source code.                                                                 |

## How it works

Sumitsubo reads the structured specification and checks the source code
against the verifiable part of it. Ruby is the only language it targets.

`.sumi.json` says where. A run takes the nearest one at or above where it
started; failing that the repository it sits in, failing that — with neither
to go on — where it started. Two bases come out of this and they answer
different questions: what the configuration says is read against that base,
so wherever under it a run starts it reaches the same files, while findings
answer relative to where the run started, so a reader can go straight to one.
This is the convention tsc and RuboCop both follow.

```json
{
  "root": ".spec",
  "specifications": { "glossary": { "verify": false } }
}
```

`root` is where the specifications live, `.spec` by default. `specifications`
lists only the exceptions: one nobody mentions is verified, and `verify:
false` keeps a specification without checking it — which a Render that only
records it still needs. A project that has said nothing is not misconfigured,
so an absent `.sumi.json` answers the defaults; only an unreadable one stops
the run.

`.spec` is the default for two reasons, both about what else claims the name:
`spec/` is RSpec's, and Spinel scans directories that do not start with a dot,
so a specification directory without one would be swept in as source.

`glossary.json` holds sections, each scoped by `include` globs. A file takes
every section covering it, applied in the order the file lists them; a later
term replaces an earlier one of the same name outright, its rejected words
included, because a term meaning something else there rejects different words.

Only the rejected words are checked — a term declaring none is vocabulary the
tool carries but cannot verify. Matching is whole-word and case sensitive, over
what a person wrote for another person: the comments of a Ruby file, found
through its syntax tree, and any other file entire, since prose is a comment
for its whole length. An identifier is a spelling of a concept rather than the
concept's name, so counting one would flag every legitimate class in the tree.

## Features

| Feature | Description                                                          |
|---------|----------------------------------------------------------------------|
| Init    | Write an empty glossary specification to start a reference line from. |
| Render  | Render the structured specification to the markdown specification.   |
| Verify  | Verify the source code is aligned with the verifiable specification. |

## Output

The reader is an agent working in the codebase, with a person reading over its
shoulder. Findings answer as `path:line`, relative to where the run started,
one per line and sorted on a key that leaves no ties. One finding per line
however often the word appears on it: the line is what a reader goes to, and
what an exclusion would one day be written against.

The run answers 0 where the two sides agree, 1 where they differ, and 2 where
the comparison could not be made — no root to verify from, a specification
missing from one that is there, an unreadable `.sumi.json`, or source the
grammar could not read. A difference is a finding about the code; being
unable to compare is not, and an operator branches on which it got. Findings
and failures share stdout, the test harness comparing the two streams merged.

## Comments

The code says what it does; a comment says why it is that way — the intent it
serves, not the story of how it came to be written. A comment that recounts
what was tried, or defends the code against a misreading, is that story and
belongs in the commit instead.

Two or three lines, around fifty words. The limit is loose; it is there to
keep an intent from turning into an account. Where this file already holds
the reason, the comment points at it rather than repeating it.

Three things earn more room:

- Behaviour a reader would otherwise take for a mistake and remove.
- An intent that needs an example to be readable.
- A piece of specification, such as a binary layout.

## Build

The command is `sumi`, shipped as a single native executable.

- `scripts/vendor.sh` fetches the pinned tree-sitter runtime and Ruby grammar
  into `vendor/`, which is not committed. Nothing compiles before it has run,
  and that script is the only place either version is written down.
- Carried C is one translation unit for the runtime and one per grammar
  (`ts_lib.c`, `ts_ruby.c`), and cannot be fewer: the runtime and a grammar
  each carry a `tree_sitter/parser.h` under the same include guard. Grammars
  move into a directory of their own once there are enough to read as a group.
- `spin build` compiles `bin/sumi.rb` to `build/bin/sumi`.
- `spin test` compiles each `test/*.rb` against the library sources — never
  against `bin/`, which is why `bin/sumi.rb` holds nothing but a delegation —
  and compares the program's stdout and stderr, merged, against a committed
  `test/<name>.rb.expected`.
- `spin test --regen` writes that snapshot by running the same file under
  CRuby. Anything reaching the tree-sitter binding cannot be regenerated —
  CRuby has no `ffi_func` — so those snapshots are written by hand and stay
  that way; today that is every test except `config_test.rb`, which is why
  nothing in `sumitsubo/config.rb` names a mechanism. Where no snapshot is
  committed the run is compared against CRuby rather than failing, and a test
  that asserts nothing passes.
- `--regen` takes no file, so it rewrites every snapshot including the
  hand-written ones, leaving a CRuby backtrace where the expectation was.
  Restore the rest afterwards.
- Tests compile at `-O1` and the shipped executable at the compiler's default,
  so CI builds and runs `sumi` in addition to running the tests.
- Targets are Linux x86_64, Linux aarch64, and macOS aarch64. Windows has no
  entry — the Spinel runtime depends on POSIX structurally.

## Compiler

This project is compiled by [Spinel](https://github.com/matz/spinel) which is a
AOT compiler for Ruby. Its constraints shape the design:

- No `eval`, `method_missing`, `define_method` with computed names,
  `ObjectSpace`, `TracePoint`, or refinements — mechanisms register themselves
  statically, not through a dynamic DSL.
- Dependencies are source trees compiled into the executable. Nothing loads at
  runtime, so what the executable supports is decided when it is built.
- C is reached through FFI declarations in a package. The tree-sitter binding
  is one, in `.packages/tree-sitter`: the dot is what keeps spin from
  compiling its C a second time as part of this application, since a package
  is scanned for the `.c` it carries. The runtime and the grammar are the
  application's to link in, which is why a grammar it does not carry fails at
  link time rather than at run time.
- `Exception#backtrace` and `Kernel#caller` return empty arrays, so an error
  carries whatever context it needs by itself.
- String literals are frozen by default.
- There is no RubyGems. The standard library is what Spinel's own packages
  provide: json, csv, erb, set, strscan, stringio, pathname, optparse, digest,
  base64, forwardable, prelude. Structured specifications are JSON for that
  reason; YAML is a direction, not a capability.
- Those packages are Spinel's own implementations, and some are subsets:
  optparse drops option descriptions from `to_s` and lets an unknown flag
  through instead of raising. A snapshot taken from CRuby can therefore record
  behaviour the executable does not have.
- `Pathname#join` reduces with `acc + part`, and once the accumulator loses
  its type that `+` dispatches to String, so it answers a String. `#/` and
  `#+` answer a Pathname on every branch, which is what the next call in a
  chain needs.
