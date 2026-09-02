# Architecture

A specification is read into one place, source into another, and what the
comparison says into a third.

Revisit this when a fourth stage appears — anything a run does that is not
reading a specification, scanning source, or answering — or when a mechanism
needs a source none of the three below can be read as.

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
│tree-     │◄─┤ Markdown parse │─►│  Builder×3         │  │Specification │
│sitter    │  │   → Block      │  │   └► the forms     │  │  Statement   │
│          │  ├────────────────┤  │ ╔═══════▼════════╗ │  │  Block       │
│          │◄─┤ Ruby / Rust /  │  │ ║ Specification  ║─┼─►│              │
│          │  │ Prose readings │─►│ ║  Repository    ║ │  │              │
└──────────┘  │ + node shaping │  │ ╚═══════╤════════╝ │  │              │
              ├────────────────┤  │         │          │  │              │
┌──────────┐  │ walk (reach)   │─►│ ╔═══════▼════════╗ │  │  Source::*   │
│filesystem│◄─┤                │  │ ║    Source      ║─┼─►│              │
└──────────┘  └────────────────┘  │ ║  Repository    ║ │  │  Place       │
                                  │ ╚═══════╤════════╝ │  │              │
                                  │ Mechanism×3        │  │              │
┌──────────┐  ┌────────────────┐  │   └► the checks    │  │              │
│  stdout  │◄─┤ Report         │◄─┤         │          │  │              │
└──────────┘  ├────────────────┤  │ ╔═══════▼════════╗ │  │              │
              │ CLI / Command  │─►│ ║    Finding     ║─┼─►│  Finding     │
              └────────────────┘  │ ║  Repository    ║ │  │  Error       │
                                  │ ╚════════════════╝ │  │              │
                                  └────────────────────┘  └──────────────┘
```

A form is not an adapter: it never reaches a driver. What a parser hands over is
a Block, and what a form makes of one is the specification's own — which is why
the two sit on either side of that word rather than in one box.

## One run

Each stage keeps what it read in one place, so no stage has to know what the
next one will ask of it.

```
 (1) read the specification
     the root's three    ┌─────────────────────────┐
         │  Parser       │ Specification Repository│  every specification
         │    → Block    │  ├ glossary   vocabulary│
         │  Builder      │  ├ contract   definition│
         └──────────────►│  └ behavior   feature   │
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
 docs/                                        the repository
 ────────────────────────────────────         ──────────────────────────────

 glossary.md ─────── Region ──────────────►   CLAUDE.md   README.md
   the words this project keeps,          ┌─► docs/*.md   ◄── itself, and the
   and the ones it turns down             │                   prose beside it
                                          ├─► docs/contract/*.md
                                          ├─► docs/behavior/*.md
                                          ├─► sumitsubo/**/*.rb
                                          └─► test/*.rb

 contract/cli.md ─── Claim @command ──────►   sumitsubo/command/*.rb
   what a person types

 contract/internal.md ─ Declaration ──────►   sumitsubo/**/*.rb
   the seams kept to one implementation

 behavior/behavior.md ─ Claim @behavior ──►   test/behavior_test.rb
 behavior/glossary.md ────────────────────►   test/glossary_test.rb
 behavior/markdown.md ────────────────────►   test/grammar_test.rb
   a document read into blocks
 behavior/form.md    ─────────────────────►   test/markdown_test.rb
   what a form makes of them
 behavior/…            ────────────────────►  test/…_test.rb
   fourteen features, reaching all             never the implementation
   fifteen tests
```

## The checks, grouped by the Source they consume

A check is named for what it finds, so one word is one check and one check is
one word however many mechanisms run it. The mechanism running it puts its own
word in front, which is the whole of `<mechanism>/<check>`.

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
 the source names nothing     │     —      │ nameless    │     —
 at all                       │            │ (C, B) ✕    │
──────────────────────────────┼────────────┼─────────────┼─────────────
 the source claims it where   │     —      │ dangling    │     —
 there is no code to claim it │            │ (C, B) ✕    │
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
 a specification that could not be read answers for itself, at no line ✕
   no parser reads it, its form refuses it, or it names one thing twice

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
│  ├─ the words            entities; they reach nothing outward
│  │  specification.rb  source.rb  finding.rb  check.rb
│  │  error.rb          version.rb
│  │  place.rb            the one place a path a reader is handed is made:
│  │                      a place in a file, or the file alone
│  │
│  ├─ handed in
│  │  config.rb                                    DTO
│  │
│  ├─ (1) the specification arrives
│  │  specification/repository.rb                  every specification
│  │  specification/block.rb                       what a document is made of
│  │  specification/parser.rb                      port
│  │  specification/parser/markdown.rb             adapter, both grammars
│  │  specification/builder.rb                     what every form shares
│  │  specification/builder/{glossary,contract,behavior}.rb
│  │
│  ├─ (2) the source arrives
│  │  source/repository.rb                         everything one run read
│  │  source/language.rb                           port
│  │  source/language/{ruby,rust,prose}.rb         adapter
│  │  source/language/nodes.rb                     captures → what no language owns
│  │  source/marker.rb                             answers Source::Claim
│  │  source/scope.rb  source/patterns.rb          reach
│  │
│  ├─ what a specification means to its own mechanism
│  │  glossary.rb  contract.rb  behavior.rb
│  │
│  ├─ the comparison
│  │  mechanism.rb                                 the register
│  │  mechanism/seed.rb
│  │  mechanism/{glossary,contract,behavior}.rb    name, seed, checks, wording
│  │  check/{region,claim,declaration,reach}.rb    eleven checks
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
├─ ts_{lib,ruby,rust,markdown,markdown_inline}.c
│                          one translation unit each; fewer will not link
├─ .packages/tree-sitter/  the FFI binding — the dot is what keeps its C from
│                          being compiled a second time
├─ docs/                   the reference line this tool holds itself to, and
│                          the prose beside it
├─ test/                   *_test.rb, the committed .expected beside each
│  └─ fixtures/            what a case is read against. Where one sits says
│     │                    which side of the tool it answers for, so a new
│     │                    case has one place to go
│     ├─ project/          a root a whole run is walked into, named for the
│     │                    answer that run gives
│     ├─ specification/    documents read for what they declare — a bag per
│     │                    mechanism, named for the defect, and one document
│     │                    per form under forms/
│     └─ source/<lang>/    material a language answers for; a language this
│                          build gains brings a directory of its own
├─ scripts/                vendor.sh, build_rev.sh — split by what moves when
├─ .github/  Dockerfile    what ships
├─ .claude/hooks/          the same promises, inside a session
├─ .sumi.json              what sumi is given about this project — the root
├─ spin.toml  spin.lock    what the compiler is given
└─ README.md  CLAUDE.md    prose for a reader

 not committed:  vendor/ (scripts/vendor.sh)   build_rev.rb
                 (scripts/build_rev.sh)        build/
```
