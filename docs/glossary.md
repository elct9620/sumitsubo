# Glossary

The words this project keeps, and the ones it turns down in their place.

Most of them belong to no mechanism. A mechanism has a word of its own only
where a sentence would turn false with another mechanism in its place, so
meeting one says the sentence holds for that mechanism alone.

## Sumitsubo

### Includes

- `CLAUDE.md`
- `README.md`
- `docs/*.md`
- `docs/contract/*.md`
- `docs/behavior/*.md`
- `sumitsubo/**/*.rb`
- `test/*.rb`

### Specification

What a project declares its source should stay aligned with. It is the
reference line and what a person reads, which is why there is no second copy
of it.

### Structured Specification

The files a mechanism reads a specification from, under whatever root the
project names: glossary.md, one file per kind of contract under contract/, and
one file per feature under behavior/.

### Verifiable Specification

The part of the structured specification a mechanism can check against source
code.

### Source Code

The code verified against the specification. Glossary and Contract verify the
implementation, Behavior the tests.

### Syntax Tree

What tree-sitter answers for a source file: every token kept, comments
included.

#### Rejected

- `AST` - An abstract tree drops the comments, which are the only thing Glossary reads.

### Parser

How a file is read for the structure a person gave it. A file is offered to
each in turn and the first one claiming it answers, the way a language is
chosen, so which files are specifications is decided by what a build carries
rather than by an extension written into a mechanism.

### Block

What a document is made of, said in the words a specification is written in
rather than any one format's: a heading and the level it sits at, a paragraph,
an item of a list and how deep it is, a fenced block and the language it
declares, a row and the cells under it. It is what a parser answers with, and
the first thing that no longer knows how the document was written.

### Form

One kind of specification as the shape a document is written in — a vocabulary,
a definition, a feature. Three of them share one syntax, so each says which
kinds of block it is written in and reads what one means for itself: a level
that states a term in one is prose in another.

### Language

How a file is read for what a person put in it, and how the names it declares
are spelled. A file is offered to each in turn and the first one claiming it
answers, which is how comments are found without anyone saying what the file
is written in; a name, though, is spelled the way one language spells it, so a
specification registering names says which it means. What a build carries is
decided when it is built.

### Mechanism

One kind of specification, and the checks it is verified by. Which source a
specification is compared against the specification selects itself, so what a
mechanism decides is the name it is switched by, the checks it runs, and how
each of them is worded.

### Contract

An interface a project registers as one it means to keep, found in the source
implementing it. Source claims one in a comment where no construct of the
language points at it, and declares it outright where one does — which is why
registering is a word of its own for how a definition declares one.

### Behavior

A scenario the specification declares in a BDD style, claimed by the tests
witnessing it.

#### Rejected

- `behaviour` - Behavior is the spelling every identifier here uses.
- `Behaviour` - Behavior is the spelling every identifier here uses.
- `behaviours` - Behaviors is the spelling every identifier here uses.

### Witness

What a test does for a scenario it claims: it stands as evidence the behavior
was read, never that the implementation is right. Only a test witnesses, and
any number of them may witness one scenario, where a contract has one
implementation.

#### Rejected

- `exercise` - What a claim asserts is that the test stands for the scenario, not that it runs anything.

### Declare

To say something exists. A specification declares what it holds the source to
— a term, a contract, a scenario; source declares the classes, modules and
methods it defines. One relation, and the subject is what changes — which is
why both sides use the word.

### Check

One comparison a mechanism runs, answering a finding wherever the two sides
have something to say about each other. It is named for what it finds rather
than for the mechanism running it, so two mechanisms asking one question run
one check under one name.

### Finding

One thing a comparison has to say about one place, answered as `path:line`. It
is a difference where the comparison was made and the two sides disagree, and a
failure where it could not be made at all.

### Marker

The word source claims a contract or behavior with, written in the comment in
front of the code. It is what an interface needs when no construct of the
language points at it.

### Claim

A comment naming, after the marker, something a specification declares, with
code below it — which is what standing in front of code means. It is one act in
every mechanism reading a marker; what it asserts is the mechanism's own, a
contract implemented or a scenario witnessed.

### Internal

An interface the project means to keep but not to publish. It is verified like
any other; what it says is that a reader outside the project is not the one it
is kept for.

### Ignore

One line a rejection does not answer for, and the reason that line is right to
say what it says. It names a mention and nothing wider, so fixing the line
leaves it naming nothing and the run says so.

### Reach

What something extends to through what it names: an include through its
pattern, a specification through its includes, a file through its requires.
What an include reaches is what it covers; a specification reaches what its
includes cover less what is excluded — the files it answers for. Every
specification's reach together is what a run reads.

### Exclude

A path no mechanism reads, however much an include covers. It is written once
for the project because a build directory is the project's rather than any one
specification's, and it decides what is read where an Ignore decides what is
answered for.

### Subdomain

A part of the problem a project addresses, and what one specification answers
for there. Its `include` is the boundary: a glossary section's terms hold in
the files it reaches, in place of an earlier section's wherever both name the
same term; a feature's scenarios are witnessed only there, and a definition's
contracts implemented only there. One file may sit under two, and answers for
both.
