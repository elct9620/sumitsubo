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

<!-- x-release-please-start-version -->

Every [release](https://github.com/elct9620/sumitsubo/releases) carries one
executable per target, as a tarball because that is what keeps the file mode,
and the checksums a download can be checked against:

```console
$ version=0.1.0-preview5 target=macos-aarch64
$ base="https://github.com/elct9620/sumitsubo/releases/download/v$version"
$ curl -sSLO "$base/sumi-$version-$target.tar.gz"
$ curl -sSLO "$base/sumi-$version-checksums.txt"
$ shasum -a 256 -c --ignore-missing "sumi-$version-checksums.txt"
sumi-0.1.0-preview5-macos-aarch64.tar.gz: OK
$ tar xzf "sumi-$version-$target.tar.gz"
$ ./sumi -v
```

That file names every target, so `--ignore-missing` is what keeps the two you
did not download from failing the check. Linux spells the command
`sha256sum -c --ignore-missing`.

The targets are `linux-x86_64`, `linux-aarch64` and `macos-aarch64`. The Linux
executables ask the host for glibc 2.34 or newer — Ubuntu 22.04, Debian 12 and
RHEL 9 onward. Anything older, and anything that is not one of these three,
reaches `sumi` through the image instead.

### Docker

The image holds the same executable a release ships, so it is a way to run
`sumi` rather than a different tool. Windows has no executable of its own here,
and this is the way in:

```console
$ docker run --rm -v "$PWD:/work" ghcr.io/elct9620/sumitsubo:0.1.0-preview5 verify
```

It is built `FROM scratch` and carries the executable, the glibc loader, and
the libraries it names — no shell, no package manager, nothing else. What the
image weighs is what the executable weighs, plus the few megabytes glibc costs.
`/work` is where a run starts, so the tree to check is what gets mounted there.

`init` writes into that tree, and a container writing as `root` leaves files
behind that the person who ran it does not own. On Linux, say who you are:

```console
$ docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/work" ghcr.io/elct9620/sumitsubo:0.1.0-preview5 init
```

Docker Desktop maps ownership back to whoever is running it, so on macOS and
Windows the flag changes nothing and PowerShell spells the mount
`-v ${PWD}:/work`.

<!-- x-release-please-end -->

To build from source instead, see [Development](#development).

## Usage

`sumi init` lays down an empty specification to start a reference line from:

```console
$ sumi init
created .spec/glossary.md
created .spec/contract
created .spec/behavior
```

Those files are where the project writes what it means to keep. `sumi help
glossary`, `sumi help contract` and `sumi help behavior` have the form of each,
and `sumi help config` has `.sumi.json` — where the specifications live, what
no mechanism reads, and which of them a run touches.

`sumi verify` checks the source against them:

```console
$ sumi verify
.spec/behavior/verify.md:9 @behavior V-002 is claimed nowhere this specification includes
app/order.rb:2 Order rejects Purchase: Order is what the domain calls it.
2 differences
```

A run answers `0` where the two sides agree, `1` where they differ, and `2`
where the comparison could not be made — whatever had to be read first was
absent, unreadable, or ambiguous. Findings answer as `path:line`, relative to
where the run started.

## Where the rest is

The forms live in the executable, so a project has them wherever `sumi` is
installed. The specification is what a person reads, so this project keeps it
in `docs/` beside the rest of its prose rather than in a directory of its own.
`.spec` is the default, and a `.sumi.json` is what says otherwise.

A shared root reserves three names: `glossary.md`, and the files directly under
`contract/` and `behavior/`. Those are read as specifications, and refused when
they turn out not to be one. Everything else under the root is the project's —
read as source wherever an include reaches it, and passed over where none does.

| Looking for | Where |
|-------------|-------|
| How to write each specification | `sumi help glossary` \| `contract` \| `behavior` \| `config` |
| What each command reads and answers | [docs/contract/cli.md](docs/contract/cli.md) |
| The vocabulary this project keeps | [docs/glossary.md](docs/glossary.md) |
| The behaviors it holds itself to | [docs/behavior/](docs/behavior) |
| How the code is laid out | [docs/architecture.md](docs/architecture.md) |

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
regenerated and its snapshot is written by hand instead. That is what the seam
between reading a document and reading a specification is for: a parser is
handed the grammars it puts its queries to and answers with the blocks a
document is made of, and the file deciding what a block means never sees one —
so the judgement stays on the side that can still be regenerated.

That last line is the project verifying its own specification, which CI runs on
every push.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
