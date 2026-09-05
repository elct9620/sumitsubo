# CLI

The commands `sumi` answers, and what each one is for.

No command takes an option of its own. `-v` and `-h` are the whole of what a
flag says here, and everything a run has to say goes to stdout.

A word a command does not take is named back rather than passed over, and the
command never runs: a run that rewrites what it was pointed at would otherwise
read a mistyped flag as consent to rewrite it.

What a run answers is one ladder throughout: `0` where it did what it was
asked, `1` where the two sides differ, and `2` where the comparison could not
be made — whatever had to be read first was absent, unreadable, or ambiguous.
Only `verify` has a second side to differ from, so only it answers `1`.

## Includes

- `sumitsubo/command/*.rb`

## Marker

`@command`

## `init`

Lay down an empty specification to start a reference line from.

Lays down what each mechanism starts from under the root: the glossary as a
file, contract and behavior as directories. What is already there is reported
and left alone: a reference line is not a document to be replaced.

```console
$ sumi init
created .spec/glossary.md
created .spec/contract
exists .spec/behavior
```

## `verify`

Verify the source code is aligned with the verifiable specification.

Reports the difference and does not decide which side is wrong — correcting
the specification is as valid an outcome as correcting the code. A finding
answers as `path:line`, relative to where the run started.

```console
$ sumi verify
.spec/behavior/verify.md:9 @behavior V-002 is claimed nowhere this specification includes
app/order.rb:2 Order rejects Purchase: Order is what the domain calls it.
2 differences
```

## `fmt`

Check the specification is written the way a reference line is written.

Answers the half of a run that is about the specification alone, so a reference
line can be got right before any code is held to it. No file a specification
covers is opened: a signature is still read as the language it names, since
that is what says how the name is spelled, and nothing else of the source is.
A specification the configuration switched off is one the project does not
keep, so it is passed over here as it is under `verify`.

```console
$ sumi fmt
.spec/behavior/verify.md:9 declares a scenario whose heading does not open with an id in backticks; sumi help behavior has the form
0 differences
```

## `help`

Explain how to write a specification, without a document beside the executable.

A project using sumi has the command and nothing else of this repository, and a
form it cannot look up is one it guesses at. Given no topic it lists the
commands and the topics; the topics below say what each one covers, and the
command itself has the form.

## `help glossary`

The vocabulary a project means to use, and the words it rejects.

Only the words a term rejects are checked: a term rejecting none is vocabulary
the tool carries but cannot verify. A rejection carries the places it is wrong,
each with the reason that line is right; the line moving is what makes the run
stop and ask again, which a fingerprint would be built to avoid.

## `help contract`

The interfaces a project means to keep, and the two readings of them.

Whether a definition names a marker decides how the source is read: with one,
source claims each interface in the comment in front of the code implementing
it; without one, the interfaces are read from the syntax tree and each contract
carries the signature saying how its name is spelled. The two are exclusive,
and which applies has to be known before a fence is reached.

## `help behavior`

The behaviors a project means its tests to implement.

One file per feature, each carrying its own include. A scenario is stated as
steps under an id unique across the directory, and test code claims one in the
comment in front of the code implementing it.

## `help config`

Where the specifications live, what a run touches, and what it answers.

A run reads the nearest `.sumi.json` at or above where it started, and a
project that has said nothing gets the defaults.

`include` and `exclude` are one form read two ways, written the way a
`.gitignore` line is written, and the `.gitignore` beside that file is read as
well. An excluded directory is never looked inside; an include covering no file
at all refuses to certify.
