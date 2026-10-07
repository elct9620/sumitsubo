# Inspect

Everything a run relates to one scenario, asked for by its id. A count from
`sumi stats` raises a question about a place; this answers it from the
scenario's end.

Nothing is compared, so what is missing is said rather than counted as a
difference.

## Includes

- `test/inspect_test.rb`

## `IN-001` A scenario claimed from a busy place

| Step | Statement |
| --- | --- |
| Given | a scenario claimed in a comment naming two others |
| When | `sumi inspect` is given its id |
| Then | it answers where it is declared, what it says, and the claim with two others |

## `IN-002` A scenario nothing claims

| Step | Statement |
| --- | --- |
| Given | a declared scenario no test claims |
| When | `sumi inspect` is given its id |
| Then | it answers where it is declared and that it is claimed nowhere |

## `IN-003` An id nothing knows

| Step | Statement |
| --- | --- |
| Given | an id no feature declares and no test claims |
| When | `sumi inspect` is given it |
| Then | it says nothing declares or claims it, and the run answers 0 |

## `IN-004` Nothing to look at

| Step | Statement |
| --- | --- |
| Given | no id |
| When | `sumi inspect` runs |
| Then | it says what it takes, and the run answers 2 |
