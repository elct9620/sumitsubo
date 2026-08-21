# Sumitsubo

[![CI](https://github.com/elct9620/sumitsubo/actions/workflows/ci.yml/badge.svg)](https://github.com/elct9620/sumitsubo/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

Sumitsubo verifies that source code stays aligned with its specification. The
specification is the reference line; the source code is the material. It
reports the difference and does not decide which side is wrong — correcting the
specification is as valid an outcome as correcting the code.

The command is `sumi`, a single native executable. Ruby is the only language it
targets.

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

`sumi verify` checks the source against it:

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

`sumi help <topic>` explains how to write each kind of specification —
`glossary`, `contract`, `behavior`, and `config` — so a project has the forms
and the findings without a document beside the executable. The sections below
say the same for a reader who is here rather than at a terminal.

`sumi render` writes the specification out as something to read. It compares
nothing, so it answers `0` or `2`:

```console
$ sumi render
rendered docs/glossary.md
rendered docs/contract/cli.md
rendered docs/behavior/verify.md
```

### Configuration

`.sumi.json` says where the specifications live, where the documents go, and
which of them a run verifies or renders. A project that has said nothing gets
the defaults.

```json
{
  "root": ".spec",
  "docs": "docs",
  "specifications": { "glossary": { "verify": false } }
}
```

`root` is where the specifications live and `docs` is where `sumi render`
writes, both answered against the directory holding the `.sumi.json`.
`specifications` lists only the exceptions: one nobody mentions is both
verified and rendered, `verify: false` keeps a specification without checking
it, and `render: false` keeps it out of the documents. A run reads the
configuration from the nearest `.sumi.json` at or above where it started,
failing that the repository it sits in.

### Glossary

`glossary.json` holds sections, each scoped by `include` globs. Only the
rejected words are checked — a term declaring none is vocabulary the tool
carries but cannot verify. Matching is whole-word and case sensitive, over the
comments of a Ruby file and any other file entire.

```json
{
  "glossary": [
    {
      "include": ["app/**/*.rb", "docs/*.md"],
      "terms": [
        {
          "term": "Order",
          "definition": "What a customer asks us to fulfil.",
          "not": [
            { "term": "Purchase", "reason": "Order is what the domain calls it." }
          ]
        }
      ]
    }
  ]
}
```

### Contract

A contract file registers one kind of interface. Whether it names a `marker`
decides how the source is read.

**With a marker**, source claims each interface in the comment in front of the
code implementing it. That is what an interface needs when no Ruby construct
points at one — nothing in a file *is* a route — and it is why the name is read
whole rather than having to be a Ruby name at all.

```json
{
  "name": "Routes",
  "marker": "@route",
  "include": ["app/**/*.rb"],
  "contracts": [
    { "name": "GET /users/:id", "description": "One user." }
  ]
}
```

```ruby
# @route GET /users/:id
def show
```

**Without one**, the interfaces are read from the syntax tree and nothing is
written in front of the code. The name is how Ruby spells it: `.` for a
singleton method, `#` for an instance one, a bare path for a class or module.
A name that could be none of those stops the run rather than answering, since
read as Ruby it would be undefined everywhere.

```json
{
  "name": "Internal seams",
  "include": ["lib/**/*.rb"],
  "contracts": [
    { "name": "Store.open", "description": "Open the store." },
    { "name": "Store#read", "description": "Read one record.", "internal": true }
  ]
}
```

Under the second reading a contract may also register `params` — the shape a
caller has to write. A parameter is what it is called, its `kind`, and whether
a caller may leave it out; `kind` defaults to the one a bare name says, and a
parameter the language lets go unnamed registers a kind alone.

```json
{
  "name": "Store.open",
  "params": [
    { "name": "path" },
    { "name": "mode", "optional": true },
    { "kind": "block", "optional": true }
  ]
}
```

The kind words are the language's own. Sumitsubo compares them as text without
knowing what any of them means, so a specification never has to say which
language it is about — `include` already said which files, and those files are
read by whatever reading answers for them.

A contract registering `params` is compared against them entire; one
registering none asks for none to be compared. A shape that differs answers at
the line registering it. One name defined with two shapes is an entrance the
specification does not describe, answered at each definition and naming the
other — while definitions that agree are one way in, so reopening a class goes
on saying nothing.

Either way, an interface the source does not carry — unclaimed under the first
reading, undefined under the second — is a difference, answered at the line
registering it. An interface nobody registered is not one: only the contracts
that matter are written down.

`internal` says the project means to keep an interface but not to publish it:
it is verified like any other, and what it stays out of is the document.

What this establishes is that an interface is implemented somewhere in scope
and reached the way the specification says, never that what it does behind
that is right.

### Behavior

`behavior/` under the root holds one file per feature, each carrying its own
`include`. `given` is a list; `when` and `then` are one sentence each. An id is
unique across the whole directory.

```json
{
  "name": "Verify",
  "include": ["test/verify_test.rb"],
  "scenarios": [
    {
      "id": "V-001",
      "title": "Code that drifted from its glossary",
      "given": ["a glossary declaring a word one of its terms rejects"],
      "when": "`sumi verify` runs",
      "then": "one finding is reported for the line the word appears on"
    }
  ]
}
```

Source claims a scenario in the comment in front of the code implementing it:

```ruby
# @behavior V-001
```

A scenario nothing claims is a difference, answered at the line of the
specification declaring it. A claim resolving to no scenario is not one —
there is nothing on the specification side to compare it against.

What this establishes is that a behavior was read and implemented, never that
the implementation is right.

### Render

`sumi render` writes `glossary.md`, one file per kind under `contract/`, and one
per feature under `behavior/`, each named after the file declaring it. A
document carries what the specification means — terms and their definitions,
contracts with the shape each is reached by and what each is for, scenarios as
tables — and not what the tool
needs in order to find things, so the words a glossary rejects, a contract's
marker and the `include` globs stay out. An interface marked `internal` stays
out too, and a kind with nothing left to publish becomes no page at all.
Documents are derived, so a run replaces what the last one wrote, and a
specification that is not there is passed over rather than reported.

## Development

Sumitsubo is compiled by [Spinel](https://github.com/matz/spinel), an AOT
compiler for Ruby, which is built from source rather than installed from
RubyGems. Two scripts lay down what the tree needs and neither is committed:
`scripts/vendor.sh` fetches the pinned tree-sitter runtime and Ruby grammar,
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
every push. `docs/` is this project rendering its own, and is committed, so a
change to `.spec/` is followed by `./build/bin/sumi render` — which
`.claude/hooks/edit.sh` does for you inside a Claude Code session.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
