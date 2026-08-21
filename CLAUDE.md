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
| Contract  | The interfaces it means to keep.                                        | Source code claiming an interface, or declaring one the language carries. |
| Behavior  | Behaviors in a BDD style.                                              | Test code declaring which behavior it implements. |

The set is not closed, and each mechanism takes its shape from what can
actually be verified — see Dogfooding.

## Dogfooding

Sumitsubo verifies its own specification. That specification is written as the
verification catches up to it, never ahead of it: a specification the tool
cannot verify is a document, not a reference line. Until a mechanism can check
it, the absence of a specification here is deliberate.

What the rule governs is a claim. A scenario asserts that a behavior was
implemented, so writing one no mechanism can check is a promise nobody holds.
A term that rejects nothing asserts nothing about the code — it names what the
project means — and there is no unchecked promise in naming.

`.spec/behavior/` therefore arrived with the Behavior mechanism and not before,
`.spec/contract/` with Contract, and `.spec/glossary.json` stayed empty until
this project had words worth rejecting. The vocabulary moved out of this file to sit beside them: a term
written here is prose, and the same term written there is checked against every
comment the project holds.

## Vocabulary

The vocabulary lives in `.spec/glossary.json`, checked against this file, the
contract and behavior specifications, the comments under `sumitsubo/`, and
`docs/glossary.md`.
A term earns a rejected word when the project has actually drifted on it; the
rest name what the project means and reject nothing, which the tool carries
without checking.

That last file is the vocabulary checking its own definitions, which cannot be
done at the source: `.spec/glossary.json` holds the words it rejects, so a file
naming itself would report every one of them. The rendered document leaves them
out, and that is what makes it checkable. A finding there answers at a derived
file and the fix belongs in the specification it came from. The rendered
contract and behavior documents stay out of scope, since their source is
already in it and two findings for one drift are noise.

A rejected word carries the reason it is rejected, and that reason says why
that word is wrong rather than why the term is right. What the term means
belongs in its definition, which is the half a document carries.

## Specification

Sumitsubo reads the structured specification and checks the source code
against the verifiable part of it. Ruby is the only language it targets.

A specification that is not there is a different question, and not every
mechanism answers it the same way. `init` lays down what each starts from, so
a root without `glossary.json` is one something removed, and the run stops
rather than pass an absent reference line off as agreement. `behavior/` cannot
say the same: git carries no empty directory, so a fresh clone of a project
that committed what `init` laid down arrives without one, and declaring no
scenarios is what keeps every such clone from failing.

### Glossary

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

### Contract

What this establishes is that a registered interface is **implemented
somewhere in scope**, never that the implementation is right. It is the same
sentence Behavior turns on, and it licenses everything this mechanism cannot
check.

`contract/` under the root holds one file per kind — the commands an
executable answers, the routes an application serves, the methods a package
exposes. A contract file plays the role a behavior file plays, carrying its
own `include`.

There are two readings, and a file says which by naming a marker or not. A
marker is the word source claims its interfaces with, written in the comment
in front of the code — `# @command verify`. It is what an interface needs
when no construct of the language points at it: nothing in a Ruby file is a
route. A method is a construct, so a file naming no marker is read from the
syntax tree instead, and nothing has to be written in front of the code for
it to be found.

The name says which construct. `Sumitsubo::Where.of` is a singleton method,
`#` an instance one, and a bare path a class or module — which is the same
rule as everywhere else here, that a contract is named by the interface
itself. A name that could be none of those stops the mechanism rather than
answering: read as Ruby, a route-shaped name is undefined everywhere, and
reporting that would blame the code for a specification that lost its marker.

An interface may be `internal`, which says the project means to keep it but
not to publish it. It is verified like any other; what it stays out of is the
document. That is a fact about the interface rather than a preference about
pages, which is what separates it from `.sumi.json` switching a whole
specification off — and a kind whose every interface is internal has nothing
to render at all.

The marker is the namespace rather than the file. A project whose routes
outgrow one file is registering more of one kind, not a second kind, so two
files may share a word and their names resolve against the union of both.
What cannot happen is one name twice under one word: a claim carries only
those two, and a referent that is not unique resolves to nothing.

A contract is named by the interface itself — `GET /users/:id` — rather than
by a handle standing in for it, which is why what follows the marker is read
whole. Behavior's ids are handles and read as a list. Marker hands back the
line either way; how it is read belongs to the mechanism that named the word.

Verification runs one way. An interface nothing claims is a difference,
answered at the line registering it, because that is where a reader chooses
between writing the code and dropping the contract. An interface nobody
registered is not one: only the contracts that matter are written down, so an
absent registration says nothing about the code.

Two of the three findings belong to the marker reading alone, because they
are about claims and the syntax tree makes none. A claim resolving to no
contract is a comparison that could not be made. One interface claimed in two
places is a difference, and it is what Contract establishes that Behavior does
not: a behavior may be claimed by as many tests as exercise it, but a contract
is the way in, so a second way in is an entrance the specification does not
describe. Both places are answered, each naming the other, since deciding
which to keep means comparing them. Under the other reading a method defined
twice is Ruby reopening a class, which says nothing.

`include` therefore means something different in each. Under the marker
reading it narrows the search rather than tying an interface to one place, as
it does for Behavior: the union is what gets scanned, which is what lets a
claim written somewhere unexpected be seen at all, and a claim that cannot be
seen cannot be reported as the second one. Under the other reading there is
no second claim to miss, so the union is simply where a definition has to be
for the interface to count as implemented.

The syntax tree is read for names and nothing else. Whether the method a
contract names takes the arguments it should is the obvious next reading, and
the parameters are in the tree — names and kinds, though never types, which
Ruby does not carry. It waits because an interface that exists is the whole of
what this establishes, and there is no use yet to say what a signature would
have to match.

Nesting is recovered from where the nodes sit rather than from the query: a
pattern reaches only its direct children and tree-sitter has no operator for a
deeper one. Two constructs spanning the same lines therefore answer with no
scope, which loses a prefix rather than inventing one.

What the tree cannot see, it cannot verify, and a contract naming one of these
is answered as undefined however plainly the code works:

| Written as | Why it is missed |
|------------|------------------|
| `attr_reader :size` | A call, not a definition — the method exists only once it runs. |
| `define_method(:computed)` | The same, and the name need not be a literal at all. |
| `def_delegator :@parts, :count` | The same, through `Forwardable`. |
| `include Helper` | `Helper#helped` is declared; `Widget#helped` never is. |
| `def Other.oddball` | Only a receiver of `self` is read, which is what a class calls itself from inside. |

The list is what one reading of one grammar reaches, not a judgement about the
code. A project leaning on these registers the contracts it can check and
leaves the rest unregistered, since an interface nobody registered says
nothing.

### Behavior

What this establishes is that a behavior was **read and implemented**, never
that the implementation is right. Nothing mechanical can judge whether the code
under a claim does what the claim says, so that one sentence licenses
everything the mechanism cannot check.

`behavior/` under the root holds one file per feature; a behavior file plays
the role a glossary section plays, carrying its own `include`, and the union of
those is what gets searched. `.spec/behavior/` is the worked example. Source
claims a scenario in the comment in front of the code implementing it —
`# @behavior V-008 V-009`.

The model is Gherkin's, not its file format: these scenarios are read rather
than executed, so `.feature` would buy nothing the other mechanisms could
share. `given` is a list with no limit. `when` and `then` are one sentence
each, which three disciplines make reachable rather than a cap that turns work
away:

- The operation under test is the last one; everything before it is `given`.
- An outcome is what one observation settles — two observations are two
  scenarios, repeating their `given` and `when`.
- `then` names the observable difference and stops. Not the exit code, which
  Output governs and which follows from which of the three a `then` names; not
  the reason, which belongs to the title. The reason is the one that creeps
  back in.

An id is unique across the whole directory, since a claim carries only the id
and a referent that is not unique resolves to nothing.

A scenario nothing claims is a difference, answered at the line of the
specification declaring it, because that is where a reader chooses between
writing the test and dropping the scenario. A claim resolving to no scenario is
not one: there is nothing on the specification side to compare it against.
Both collect before reporting, the way a linter does, so a renamed id is fixed
in one pass.

## Command

### Configuration

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
  "docs": "docs",
  "specifications": { "glossary": { "verify": false } }
}
```

`root` is where the specifications live, `.spec` by default, and `docs` is
where Render writes, `docs` by default.

`specifications` lists only the exceptions: one nobody mentions is both
verified and rendered. The two switches sit in the same entry and are
independent — `verify: false` keeps a specification without checking it, which
a Render that only records it still needs, and `render: false` keeps one out of
the documents without stopping the check. A project that has said nothing is
not misconfigured, so an absent `.sumi.json` answers the defaults; only an
unreadable one stops the run.

`.spec` is the default for two reasons, both about what else claims the name:
`spec/` is RSpec's, and Spinel scans directories that do not start with a dot,
so a specification directory without one would be swept in as source.

### Features

| Feature | Description                                                          |
|---------|----------------------------------------------------------------------|
| Init    | Lay down an empty specification to start a reference line from.      |
| Render  | Render the structured specification into documents a person reads.   |
| Verify  | Verify the source code is aligned with the verifiable specification. |

### Render

Render writes the structured specification out as something a person reads:
`glossary.md` under the documents path, one file per kind of contract under
`contract/`, and one file per feature under `behavior/`, each named after the
file declaring it.

A document carries what the specification means, not what the tool needs in
order to find things. A glossary renders its terms and their definitions; the
words it rejects stay out, because they record where this project drifted
rather than what the vocabulary is, and a reader is handed one at the line it
was tripped on instead. The `include` globs stay out for the same reason, and a
contract's marker with them: they say where to look and what to look for.
Structured fields become tables, and a scenario is sentences rather than
fields, so its table carries one step per row.

A document is derived, so a run replaces what the last one wrote. What `init`
refuses to overwrite is a reference line, and this is not one.

An absent specification is nothing to render rather than a comparison that
could not be made, so it is passed over in silence. Render records where Verify
certifies, and the run that would otherwise pass an absent reference line off
as agreement is `verify`, which still stops.

Templates are the obvious way to word these pages, and would let a project word
its own. Spinel's `erb` is a placeholder that answers the template unchanged,
so the wording is built in the mechanism and stays there until there is an
engine to move it to.

### Output

The reader is an agent working in the codebase, with a person reading over its
shoulder. Findings answer as `path:line`, relative to where the run started,
one per line and sorted on a key that leaves no ties. One finding per line
however often the word appears on it: the line is what a reader goes to, and
what an exclusion would one day be written against.

The run answers 0 where the two sides agree, 1 where they differ, and 2 where
the comparison could not be made — whatever had to be read first was absent,
unreadable, or ambiguous — three words standing in for a list that grows with
every mechanism. A difference is a finding about the code; being unable to
compare is not, and an operator branches on which it got. A run with both
answers 2: it says everything it found either way, and the answer is what
refuses to certify it. A mechanism that could not be read stops that mechanism
and no other, the way a linter reports every file it managed to parse.
Findings and failures share stdout, the test harness comparing the two streams
merged.

Render reads the same ladder one rung short. It compares nothing, so it never
answers 1, and its 0 says every document it had to write is written. What it
could not read answers 2 as everywhere else.

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

- `scripts/vendor.sh` lays down what nothing compiles without, none of it
  committed: the pinned tree-sitter runtime and Ruby grammar into `vendor/`,
  and the revision a build answers for into `build_rev.rb`. That script is the
  only place either version is written down, so the CI cache keyed on it now
  misses whenever anything else in it moves too.
- The revision sits at the root, which no specification's include globs reach,
  and only `bin/sumi.rb` requires it. `spin test` never compiles `bin/`, so a
  test always sees the unstamped default and a snapshot can hold the version
  line. The stamped one is covered by CI running the executable instead.
- Carried C is one translation unit for the runtime and one per grammar
  (`ts_lib.c`, `ts_ruby.c`), and cannot be fewer: the runtime and a grammar
  each carry a `tree_sitter/parser.h` under the same include guard. Grammars
  move into a directory of their own once there are enough to read as a group.
- `spin build` compiles `bin/sumi.rb` to `build/bin/sumi`.
- `spin test` compiles each `test/*.rb` against the library sources — never
  against `bin/`, which is why `bin/sumi.rb` holds nothing but the delegation
  and the one require no test can see — and compares the program's stdout and
  stderr, merged, against a committed `test/<name>.rb.expected`.
- `spin test --regen` writes that snapshot by running the same file under
  CRuby. Anything reaching the tree-sitter binding cannot be regenerated —
  CRuby has no `ffi_func` — so those snapshots are written by hand and stay
  that way. A file reaching it through its requires counts, which is why
  `sumitsubo/config.rb` names no mechanism and why neither `behavior.rb` nor
  `contract.rb` names a grammar — each hands its reading of source to `marker.rb`
  or `definitions.rb` instead. Keeping the specification side apart from the side
  that reads source is what leaves those three tests able to regenerate. Where no
  snapshot is committed the run is compared against CRuby rather than failing,
  and a test that asserts nothing passes.
- `--regen` takes the same file list, so name the test to rewrite. Given none
  it rewrites every snapshot including the hand-written ones, leaving a CRuby
  backtrace where the expectation was.
- Tests compile at `-O1` and the shipped executable at the compiler's default,
  so CI builds and runs `sumi` in addition to running the tests.
- `.claude/hooks/` holds this repository to the same promises inside a
  session: one renders the documents after any tool call that could have moved
  the specification, the other runs the suite before a turn is allowed to end.
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
  behavior the executable does not have.
- `Pathname#join` reduces with `acc + part`, and once the accumulator loses
  its type that `+` dispatches to String, so it answers a String. `#/` and
  `#+` answer a Pathname on every branch, which is what the next call in a
  chain needs.
