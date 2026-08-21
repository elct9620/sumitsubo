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
| Contract  | The interfaces it means to keep. | Source code declaring which interface it implements. |
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
.spec/behavior/verify.json:6 V-002 is claimed nowhere in test/*_test.rb
app/order.rb:2 Order rejects Purchase: Order is what the domain calls it.
2 differences
```

A run answers `0` where the two sides agree, `1` where they differ, and `2`
where the comparison could not be made — whatever had to be read first was
absent, unreadable, or ambiguous. Findings answer as `path:line`, relative to
where the run started.

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

`sumi render` writes `glossary.md` and one file per feature under `behavior/`,
named after the file declaring it. A document carries what the specification
means — terms and their definitions, scenarios as tables — and not what the
tool needs in order to find things, so the words a glossary rejects and the
`include` globs stay out. Documents are derived, so a run replaces what the
last one wrote, and a specification that is not there is passed over rather
than reported.

## Development

Sumitsubo is compiled by [Spinel](https://github.com/matz/spinel), an AOT
compiler for Ruby, which is built from source rather than installed from
RubyGems. `scripts/vendor.sh` fetches the pinned tree-sitter runtime and Ruby
grammar, and nothing compiles before it has run.

```console
$ ./scripts/vendor.sh
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
