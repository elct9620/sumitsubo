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
| Glossary  | The domain vocabulary.                                                 | Identifiers in the source code. |
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

Sumitsubo reads the structured specification from `.spec/` and uses tree-sitter
to query the source code, checking it against the verifiable specification.
Ruby is the only language it targets.

`.spec/` is provisional — chosen to stay clear of RSpec's `spec/`, and open to
change.

## Features

| Feature | Description                                                          |
|---------|----------------------------------------------------------------------|
| Render  | Render the structured specification to the markdown specification.   |
| Verify  | Verify the source code is aligned with the verifiable specification. |

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

- `spin build` compiles `bin/sumi.rb` to `build/bin/sumi`.
- `spin test` compiles each `test/*.rb` against the library sources — never
  against `bin/`, which is why `bin/sumi.rb` holds nothing but a delegation —
  and compares the program's stdout and stderr, merged, against a committed
  `test/<name>.rb.expected`.
- `spin test --regen` writes that snapshot by running the same file under
  CRuby, so whatever a test reaches has to behave identically on both. Where
  no snapshot is committed the run is compared against CRuby rather than
  failing, and a test that asserts nothing passes.
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
