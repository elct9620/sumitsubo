# CLI

The commands `sumi` answers, and what each one is for.

No command takes an option of its own. `-v` and `-h` are the whole of what a flag says here, and everything a run has to say goes to stdout.

What a run answers is one ladder throughout: `0` where it did what it was asked, `1` where the two sides differ, and `2` where the comparison could not be made — whatever had to be read first was absent, unreadable, or ambiguous. Only `verify` has a second side to differ from, so only it answers `1`.

## init

Lay down an empty specification to start a reference line from.

Writes the glossary file and a directory per mechanism under the root. What is already there is reported and left alone: a reference line is not a document to be replaced.

```console
$ sumi init
created .spec/glossary.json
created .spec/contract
exists .spec/behavior
```

## render

Render the structured specification into documents a person reads.

Writes what the specification means and not what the tool needs in order to find things, so a marker, the include globs and the words a glossary rejects stay out. A document is derived, so a run replaces what the last one wrote, and a specification that is not there is passed over rather than reported.

```console
$ sumi render
rendered docs/glossary.md
rendered docs/contract/cli.md
```

## verify

Verify the source code is aligned with the verifiable specification.

Reports the difference and does not decide which side is wrong — correcting the specification is as valid an outcome as correcting the code. A finding answers as `path:line`, relative to where the run started.

```console
$ sumi verify
.spec/behavior/verify.json:6 @behavior V-002 is claimed nowhere in test/*_test.rb
app/order.rb:2 Order rejects Purchase: Order is what the domain calls it.
2 differences
```

## help

Explain how to write a specification, without a document beside the executable.

A project using sumi has the command and nothing else of this repository, and a form it cannot look up is one it guesses at. Given no topic it lists the commands and the topics; the sections below say what each topic covers, and the command itself has the form.

## help glossary

The vocabulary a project means to use, and the words it rejects.

One file at the root of the specification. A section scopes its terms by include globs, and only the words a term rejects are checked: a term rejecting none is vocabulary the tool carries but cannot verify.

```json
{
  "glossary": [
    {
      "include": [],
      "terms": [
        { "term": "", "definition": "", "not": [{ "term": "", "reason": "" }] }
      ]
    }
  ]
}
```

## help contract

The interfaces a project means to keep, and the two readings of them.

One file per kind of interface, under `contract/`. Whether a file names a `marker` decides how the source is read: with one, source claims each interface in the comment in front of the code implementing it; without one, the interfaces are read from the syntax tree and the file says which `language` spells the names. One of the two has to be there and never both, so a file taking the second reading writes `language` where the shape below writes `marker`.

```json
{
  "name": "",
  "description": "",
  "marker": "",
  "include": [],
  "contracts": [
    { "name": "", "description": "", "internal": false, "params": [], "notes": [] }
  ],
  "notes": []
}
```

## help behavior

The behaviors a project means its tests to implement.

One file per feature, under `behavior/`, each carrying its own include. A scenario is a list of `given` and one sentence each for `when` and `then`, under an id unique across the directory; test code claims one in the comment in front of the code implementing it.

```json
{
  "name": "",
  "description": "",
  "include": [],
  "scenarios": [
    { "id": "", "title": "", "given": [], "when": "", "then": "" }
  ],
  "notes": []
}
```

## help config

Where the specifications live, what a run touches, and what it answers.

`.sumi.json` says where the specifications live, where the documents go, and which of them a run verifies or renders. A run reads the nearest one at or above where it started, and a project that has said nothing gets the defaults.

```json
{
  "root": ".spec",
  "docs": "docs",
  "specifications": { "glossary": { "verify": false, "render": false } }
}
```
