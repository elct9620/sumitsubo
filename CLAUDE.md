Sumitsubo verifies that source code stays aligned with its specification. The
specification is the reference line; the source code is the material.

## Dogfooding

Sumitsubo verifies its own specification. The set of mechanisms is not
closed, and each takes its shape from what can actually be verified. The
specification is written as the verification catches up to it, never ahead of
it: a specification the tool cannot verify is a document, not a reference
line. Until a mechanism can check it, the absence of a specification here is
deliberate.

What the rule governs is a claim. A scenario asserts that a behavior was
implemented, so writing one no mechanism can check is a promise nobody holds.
A term that rejects nothing asserts nothing about the code — it names what the
project means — and there is no unchecked promise in naming. A note is the
same.

`.spec/behavior/` therefore arrived with the Behavior mechanism and not before,
`.spec/contract/` with Contract, and `.spec/glossary.md` stayed empty until
this project had words worth rejecting. The vocabulary moved out of this file to sit beside them: a term
written here is prose, and the same term written there is checked against every
comment the project holds.

## Vocabulary

The vocabulary lives in `.spec/glossary.md`, and its includes say what it
reaches. A specification is checked at its source, which is where a finding's
fix belongs; the fixtures stay out, since what they carry is deliberately
wrong.

A term earns a rejected word when the project has actually drifted on it; the
rest name what the project means and reject nothing, which the tool carries
without checking.

## Comments

The code says what it does; a comment says why it is that way — the intent it
serves, not the story of how it came to be written. A comment that recounts
what was tried, or defends the code against a misreading, is that story and
belongs in the commit instead.

Two or three lines, around fifty words. The limit is loose; it is there to
keep an intent from turning into an account.

A comment never sends a reader to this file. What one would cite has become a
fact about the project by being worth citing, and a fact about the project
belongs in the project — in the comment saying it, or in the README where a
reader outside the code needs it. This file carries the direction, the
principles, and what the source cannot be read off, and none of that is a
reference for the code to point at.

Three things earn more room:

- Behavior a reader would otherwise take for a mistake and remove.
- An intent that needs an example to be readable.
- A piece of specification, such as a binary layout.

## Paths

A path the tool composes is a `Pathname` and reaches the file through that
same object; a path it read off the filesystem, or rendered for a reader, is a
String. The rendered ones are what findings carry, and they answer relative to
where the run started, so `Where.of` is the one place that makes one.

A seam normalises rather than refusing: `load` takes what it is handed and
wraps it, the way `Config.load` does, so a caller composing a path itself is
not made to say so twice.

## Build

The command is `sumi`, shipped as a single native executable.

- `scripts/vendor.sh` fetches the pinned tree-sitter runtime and grammars
  into `vendor/`, which is not committed. Nothing compiles before it has run,
  and that script is the only place any of those versions is written down —
  which is what lets CI key the cache on its contents alone.
- `scripts/build_rev.sh` writes the revision a build answers for into
  `build_rev.rb`, also not committed. It is a script of its own because a
  revision moves with every commit and that cache key must not.
- What a build says of itself is required by `bin/sumi.rb` and nowhere else:
  the revision it answers for, and the languages it carries. `spin test` never
  compiles `bin/`, so a test sees the unstamped default and hands in a reading
  only where it needs one — which is what keeps a snapshot able to hold the
  version line, and keeps a grammar out of every run that only prints or lays
  down files. The stamped revision is covered by CI running the executable.
- Carried C is one translation unit for the runtime and one per grammar
  (`ts_lib.c`, `ts_ruby.c`, `ts_rust.c`, `ts_markdown.c`), and cannot be fewer:
  the runtime and a grammar each carry a `tree_sitter/parser.h` under the same
  include guard, and two grammars collide on the macros every generated parser
  defines. Markdown carries the block grammar alone — the inline one is reached
  through `ts_parser_set_included_ranges`, which the binding does not have, and
  the unparsed text a block-level `inline` node holds is what a specification is
  read from. Grammars move into a directory of their own once there are enough
  to read as a group.
- `spin build` compiles `bin/sumi.rb` to `build/bin/sumi`.
- `spin test` compiles each `test/*.rb` against the library sources — never
  against `bin/`, which is why `bin/sumi.rb` holds nothing but the delegation
  and the one require no test can see — and compares the program's stdout and
  stderr, merged, against a committed `test/<name>.rb.expected`.
- `spin test --regen` writes that snapshot by running the same file under
  CRuby. Anything reaching the tree-sitter binding cannot be regenerated —
  CRuby has no `ffi_func` — so those snapshots are written by hand and stay
  that way. A file reaching it through its requires counts, which is why
  `sumitsubo/config.rb` names no mechanism, why no mechanism names a language
  or a format, and why `sumitsubo/definitions.rb` requires nothing at all — a
  reading brings it captures rather than a path. `require "sumitsubo"` reaches
  no grammar, so what is written by hand is the five tests that read source or
  ask for a binding. Where no snapshot is committed the run is compared against CRuby
  rather than failing, and a test that asserts nothing passes.
- `--regen` takes the same file list, so name the test to rewrite. Given none
  it rewrites every snapshot including the hand-written ones, leaving a CRuby
  backtrace where the expectation was.
- Tests compile at `-O1` and the shipped executable at the compiler's default,
  so CI builds and runs `sumi` in addition to running the tests.
- `.claude/hooks/` holds this repository to the same promises inside a
  session: the suite runs before a turn is allowed to end.
- Targets are Linux x86_64, Linux aarch64, and macOS aarch64. Windows gets no
  executable — the Spinel runtime depends on POSIX structurally — and reaches
  the tool through the image instead. That image compiles nothing: it holds a
  Linux executable a release already built, which is what keeps one build path
  answering for both ways of shipping.

## Compiler

This project is compiled by [Spinel](https://github.com/matz/spinel) which is a
AOT compiler for Ruby. Its constraints shape the design:

- No `eval`, `method_missing`, `define_method` with computed names,
  `ObjectSpace`, `TracePoint`, or refinements — mechanisms register themselves
  statically, not through a dynamic DSL.
- Directories that do not start with a dot are scanned as source, which is
  half of why `.spec` is the default specification root.
- Dependencies are source trees compiled into the executable. Nothing loads at
  runtime, so what the executable supports is decided when it is built.
- C is reached through FFI declarations in a package. The tree-sitter binding
  is one, in `.packages/tree-sitter`: the dot is what keeps spin from
  compiling its C a second time as part of this application, since a package
  is scanned for the `.c` it carries. The runtime and the grammars are the
  application's to link in, which is why a grammar it does not carry fails at
  link time rather than at run time. One file reaches the binding —
  `sumitsubo/grammar.rb`, which every query in the program is put through — and
  only `bin/sumi.rb` decides which of what is linked in a build actually
  answers. What that bounds is the blast radius: a reading of source
  or of a specification is handed a grammar rather than reaching for one, so it
  names no grammar and its snapshot can still be regenerated.
- `Exception#backtrace` and `Kernel#caller` return empty arrays, so an error
  carries whatever context it needs by itself.
- String literals are frozen by default.
- There is no RubyGems. The standard library is what Spinel's own packages
  provide: json, csv, erb, set, strscan, stringio, pathname, optparse, digest,
  base64, forwardable, prelude. Structured specifications are JSON for that
  reason; YAML is a direction, not a capability.
- `spin` compiles with the compiler's require gate on, so a file naming one of
  those packages requires it first and a require nothing can satisfy fails the
  build. That is what keeps a source file reading the same here as under the
  CRuby run that takes a snapshot.
- Those packages are Spinel's own implementations, and some are subsets:
  optparse drops option descriptions from `to_s` and lets an unknown flag
  through instead of raising, and `erb` answers a template unchanged. Rendering
  is built as strings for that reason: templates would let a project word its
  own pages, and there is no engine to move the wording to. A snapshot taken from CRuby can therefore record
  behavior the executable does not have.
- A `join` whose receiver arrives untyped answers that receiver's string form
  with the arguments dropped, so a `Pathname` reaching one answers `""`. An
  Array is answered correctly, which is what every `join` here is; a path is
  composed with `#/`, which answers a `Pathname` on every branch, rather than
  with the `join` the ecosystem writes.
