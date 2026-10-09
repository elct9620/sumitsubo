# Kept

What a run keeps of what corresponds, and how each check reads it back. Every
stage hands the next its answer as relations, so each is asked here with its
input written out rather than read from a document.

```text
K-001  includes        -> reach, read back per specification
K-002  claims          -> the keys one comment names
K-003  claims          -> what a check compares
K-004  declarations    -> grouped by the language that read them
K-005  mentions        -> joined with the reason a section gives
K-006  a written key   -> unresolved, or ambiguous
```

## Includes

- `test/kept_test.rb`

## `K-001` What each specification reaches

| Step | Statement |
| --- | --- |
| Given | two specifications whose includes cover different files |
| When | their reach is kept and read back |
| Then | each holds only its own files, and the files to read are the union |

## `K-002` The keys one comment names

| Step | Statement |
| --- | --- |
| Given | a comment naming one scenario twice, and a comment of its own |
| When | the keys that first comment names are asked for |
| Then | each answers once, in the order written, and the other comment adds none |

## `K-003` A claim read back for a check

| Step | Statement |
| --- | --- |
| Given | claims kept from a scenario's marker and a contract's marker |
| When | each mechanism reads them back |
| Then | a scenario is named by its id, and a contract by its marker and name |

## `K-004` A declaration read back under its language

| Step | Statement |
| --- | --- |
| Given | declarations kept from one file read as two languages |
| When | they are read back |
| Then | each stands under the language that read it, in the order read |

## `K-005` A mention read back with its reason

| Step | Statement |
| --- | --- |
| Given | a rejected word kept where a person wrote it |
| When | the vocabulary reads it back |
| Then | it carries the term rejecting it and the reason that section gives |

## `K-006` A written key naming none, or more than one

| Step | Statement |
| --- | --- |
| Given | a scenario relating to a key nothing declares, and one two statements declare |
| When | each is answered |
| Then | the first is unresolved and the second ambiguous, both at the scenario's heading |
