# Architecture

Where sumitsubo is going: a specification is read into one place, source into
another, and what the comparison says into a third.

## Layers

Nothing inner names anything outer, so what a build carries is decided at the
edge and handed in.

```
                          ┌─────────────────────────┐
        bin/sumi.rb ─────►│  Config (DTO)           │──── root
                │         │  root / exclusion /     │──── exclusion
                │         │  which mechanisms run   │──── switches
                │         └───────────┬─────────────┘
                │                     │ handed to the stage that needs it
                ▼                     ▼
  Drivers        Adapters               Use Cases              Entities
┌──────────┐  ┌────────────────┐  ┌────────────────────┐  ┌──────────────┐
│tree-     │◄─┤ Markdown parse │─►│ ╔════════════════╗ │  │Specification │
│sitter    │  │ + Builder×3    │  │ ║ Specification  ║─┼─►│  Statement   │
│          │  ├────────────────┤  │ ║  Repository    ║ │  │              │
│          │◄─┤ Ruby / Rust /  │  │ ╚═══════╤════════╝ │  │              │
│          │  │ Prose readings │─►│         │          │  │              │
└──────────┘  │ + node shaping │  │ ╔═══════▼════════╗ │  │              │
              ├────────────────┤  │ ║    Source      ║─┼─►│  Source::*   │
┌──────────┐  │ walk (reach)   │─►│ ║  Repository    ║ │  │  Place/Shape │
│filesystem│◄─┤                │  │ ╚═══════╤════════╝ │  │              │
└──────────┘  └────────────────┘  │         │          │  │              │
                                  │ Mechanism×3        │  │              │
┌──────────┐  ┌────────────────┐  │   └► the checks    │  │              │
│  stdout  │◄─┤ Report         │◄─┤         │          │  │              │
└──────────┘  ├────────────────┤  │ ╔═══════▼════════╗ │  │              │
              │ CLI / Command  │─►│ ║    Finding     ║─┼─►│  Finding     │
              └────────────────┘  │ ║  Repository    ║ │  │  Error       │
                                  │ ╚════════════════╝ │  │              │
                                  └────────────────────┘  └──────────────┘
```

## One run

Each stage keeps what it read in one place, so no stage has to know what the
next one will ask of it.

```
 (1) read the specification
     .spec/**            ┌─────────────────────────┐
         │  Parser       │ Specification Repository│  every specification
         └──────────────►│  ├ glossary   vocabulary│
                         │  ├ contract   definition│
                         │  └ behavior   feature   │
                         └───────────┬─────────────┘
                                     │ every include, as one set
 (2) scan the source                 ▼
                         ┌─────────────────────────┐
                         │ reach                   │──► barren
                         │  ├ union → what to read │
                         │  └ per spec → boundary  │
                         └───────────┬─────────────┘
                                     │ file list
                         ┌───────────▼─────────────┐
                         │    Source Repository    │  everything one run read
                         │  ├ Region       comment │
                         │  ├ Claim        marker  │
                         │  └ Declaration  syntax  │
                         └───────────┬─────────────┘
                                     │
                     specification × source ─► a check ─► Finding
 (3) answer                          ▼
                         ┌─────────────────────────┐
                         │   Finding Repository    │  collect, order, count,
                         └───────────┬─────────────┘  leave an exit code
                                     │
                         ┌───────────▼─────────────┐
                         │         Report          │──► stdout
                         └─────────────────────────┘
```

## What a specification is compared against

The specification decides which Source answers for it, so a mechanism that
compares an already-known shape is an attribute rather than new code.

```
  Specification.attributes            Source              what is read
  ────────────────────────         ────────────────    ───────────────────
  no marker, no language      ──►  Source::Region      comments, line by line
  marker                      ──►  Source::Claim       the word, and the rest
                                                       of the line unread
  language, no marker         ──►  Source::Declaration the name, and its Shape
```

## What this project's own specification reaches

An include is the whole of the relation between a specification and the code:
Glossary and Contract answer for the implementation, Behavior for the tests.

```
 .spec/                                       the repository
 ────────────────────────────────────         ──────────────────────────────

 glossary.md ─────── Region ──────────────►   CLAUDE.md   README.md
   the words this project keeps,          ┌─► docs/*.md
   and the ones it turns down             ├─► .spec/**          ◄── itself
                                          ├─► sumitsubo/**/*.rb
                                          └─► test/*.rb

 contract/cli.md ─── Claim @command ──────►   sumitsubo/command/*.rb
   what a person types

 contract/internal.md ─ Declaration ──────►   sumitsubo/**/*.rb
   the seams kept to one implementation

 behavior/behavior.md ─ Claim @behavior ──►   test/behavior_test.rb
 behavior/glossary.md ────────────────────►   test/glossary_test.rb
 behavior/markdown.md ────────────────────►   test/{grammar,markdown}_test.rb
 behavior/…            ────────────────────►  test/…_test.rb
   twelve features, reaching fourteen of       never the implementation
   the fifteen tests                           test/patterns_test.rb is
                                               declared by no feature, and
                                               no check can say so
```

## The checks, grouped by the Source they consume

A check is named for what it finds, so one word is one check and one check is
one word however many mechanisms run it.

```
                              │ Source::   │ Source::    │ Source::
                              │ Region     │ Claim       │ Declaration
──────────────────────────────┼────────────┼─────────────┼─────────────
 the specification says so,   │     —      │ unclaimed   │ undefined
 the source does not          │            │ (C, B)      │ (C)
──────────────────────────────┼────────────┼─────────────┼─────────────
 the specification says not,  │ rejected   │     —       │     —
 the source does              │ (G)        │             │
──────────────────────────────┼────────────┼─────────────┼─────────────
 what the specification set   │ stale      │     —       │     —
 aside is no longer there     │ (G) ✕      │             │
──────────────────────────────┼────────────┼─────────────┼─────────────
 the source points at         │     —      │ unresolved  │     —
 nothing                      │            │ (C, B) ✕    │
──────────────────────────────┼────────────┼─────────────┼─────────────
 it points at something,      │     —      │ misplaced   │     —
 outside the boundary         │            │ (C, B) ✕    │
──────────────────────────────┼────────────┼─────────────┼─────────────
 the source has two where     │     —      │ duplicated  │ conflicting
 the specification has one    │            │ (C)         │ (C)
──────────────────────────────┼────────────┼─────────────┼─────────────
 both sides have it, and      │     —      │     —       │ mismatched
 the shapes disagree          │            │             │ (C)
──────────────────────────────┴────────────┴─────────────┴─────────────
 reach answers for itself:  barren  (G, C, B) ✕
 a specification no parser can read answers for itself, at no line ✕

 G glossary   C contract   B behavior
 ✕ a failure: the comparison could not be made
   everything else is a difference: both sides were read and disagree
```

## Tree

Every file has one place, and where it sits is what says what it is.

```
.
├─ sumitsubo.rb            what `require "sumitsubo"` reaches, which is the
│                          inner layer and nothing else
├─ sumitsubo/
│  ├─ the words            entities; they require nothing
│  │  specification.rb  source.rb  finding.rb  error.rb  version.rb
│  │  place.rb            the one place a path a reader is handed is made,
│  │                      and with no line it answers for a whole file
│  │
│  ├─ handed in
│  │  config.rb                                    DTO
│  │
│  ├─ (1) the specification arrives
│  │  specification/repository.rb                  every specification
│  │  specification/parser.rb                      port
│  │  specification/markdown.rb                    adapter
│  │  specification/markdown/format.rb
│  │  specification/markdown/builder/{vocabulary,definition,feature}.rb
│  │
│  ├─ (2) the source arrives
│  │  source/repository.rb                         everything one run read
│  │  source/language.rb                           port
│  │  source/language/{ruby,rust,prose}.rb         adapter
│  │  source/language/nodes.rb                     captures → declarations
│  │  source/marker.rb                             answers Source::Claim
│  │  source/scope.rb  source/patterns.rb          reach
│  │
│  ├─ the comparison
│  │  mechanism.rb                                 the register
│  │  mechanism/{glossary,contract,behavior}.rb    name, seed, checks, wording
│  │  check/{region,claim,declaration,reach}.rb    ten checks
│  │
│  ├─ (3) the answer leaves
│  │  finding/repository.rb                        collect, order, count, code
│  │  finding/report.rb                            adapter, to stdout
│  │
│  ├─ the shell
│  │  cli.rb  command/{help,init,verify}.rb
│  │
│  └─ grammar.rb                                   the one driver, both sides
│
├─ bin/sumi.rb             what this build carries and answers for; never
│                          compiled into a test
├─ ts_{lib,ruby,rust,markdown}.c
│                          one translation unit each; fewer will not link
├─ .packages/tree-sitter/  the FFI binding — the dot is what keeps its C from
│                          being compiled a second time
├─ .spec/                  the reference line this tool holds itself to
├─ test/                   *_test.rb, the committed .expected beside each,
│                          and the fixtures they read
├─ scripts/                vendor.sh, build_rev.sh — split by what moves when
├─ .github/  Dockerfile    what ships
├─ .claude/hooks/          the same promises, inside a session
├─ spin.toml  spin.lock    what the compiler is given
└─ README.md  CLAUDE.md  docs/
                           prose for a reader

 not committed:  vendor/ (scripts/vendor.sh)   build_rev.rb
                 (scripts/build_rev.sh)        build/
```
