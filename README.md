# Sumitsubo

[![CI](https://github.com/elct9620/sumitsubo/actions/workflows/ci.yml/badge.svg)](https://github.com/elct9620/sumitsubo/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

Sumitsubo verifies that source code stays aligned with its specification. The
specification is the reference line; the source code is the material. It
reports the difference and does not decide which side is wrong — correcting the
specification is as valid an outcome as correcting the code.

The command is `sumi`, a single native executable. It reads Ruby and Rust, and
whatever else is prose.

## Mechanisms

| Mechanism | The specification declares | Verified against |
|-----------|----------------------------|------------------|
| Glossary  | The domain vocabulary, and the words rejected in its place. | Words a person wrote: comments, and prose. |
| Contract  | The interfaces it means to keep. | Source code claiming an interface, or declaring one the language carries. |
| Behavior  | Behaviors in a BDD style. | Test code declaring which behavior it implements. |

## Installation

Not published yet — build from source, see [Development](#development).

## Usage

`sumi init` lays down an empty specification to start a reference line from:

```console
$ sumi init
created .spec/glossary.json
created .spec/contract
created .spec/behavior
```

Those files are where the project writes what it means to keep. `sumi help
glossary`, `sumi help contract` and `sumi help behavior` have the form of each,
and `sumi help config` has `.sumi.json` — where the specifications live, where
the documents go, and which of them a run touches.

`sumi verify` checks the source against them:

```console
$ sumi verify
.spec/behavior/verify.json:6 @behavior V-002 is claimed nowhere in test/*_test.rb
app/order.rb:2 Order rejects Purchase: Order is what the domain calls it.
2 differences
```

A run answers `0` where the two sides agree, `1` where they differ, and `2`
where the comparison could not be made — whatever had to be read first was
absent, unreadable, or ambiguous. Findings answer as `path:line`, relative to
where the run started.

`sumi render` writes the specification out as something to read — terms and
their definitions, contracts as sections, scenarios as tables — leaving out
what the tool needs in order to find things:

```console
$ sumi render
rendered docs/glossary.md
rendered docs/contract/cli.md
rendered docs/behavior/verify.md
```

## Where the rest is

The forms live in the executable, so a project has them wherever `sumi` is
installed. `docs/` here is this project's own specification, rendered by the
tool it is:

| Looking for | Where |
|-------------|-------|
| How to write each specification | `sumi help glossary` \| `contract` \| `behavior` \| `config` |
| What each command reads, writes and answers | [docs/contract/cli.md](docs/contract/cli.md) |
| The vocabulary this project keeps | [docs/glossary.md](docs/glossary.md) |
| The behaviors it holds itself to | [docs/behavior/](docs/behavior) |

## Development

Sumitsubo is compiled by [Spinel](https://github.com/matz/spinel), an AOT
compiler for Ruby, which is built from source rather than installed from
RubyGems. Two scripts lay down what the tree needs and neither is committed:
`scripts/vendor.sh` fetches the pinned tree-sitter runtime and grammars,
and `scripts/build_rev.sh` writes the revision the executable answers for.
Nothing compiles before both have run.

```console
$ ./scripts/vendor.sh
$ ./scripts/build_rev.sh
$ spin test
$ spin build
$ ./build/bin/sumi verify
```

`spin test` compares each test's output against a committed snapshot, and
`spin test --regen` writes those snapshots by running the file under CRuby.
CRuby has no `ffi_func`, so a test reaching the tree-sitter binding cannot be
regenerated and its snapshot is written by hand instead. That is why the files
reading a specification name no grammar: it keeps their tests on the side that
can still be regenerated.

That last line is the project verifying its own specification, which CI runs on
every push. `docs/` is committed, so a change to `.spec/` is followed by
`./build/bin/sumi render` — which `.claude/hooks/edit.sh` does for you inside a
Claude Code session.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
