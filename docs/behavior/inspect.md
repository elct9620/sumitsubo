# Inspect

Everything a run relates to one scenario, or to one place in source. A count
from `sumi stats` raises a question about a place; this answers it from either
end. A key naming a file, with or without a line, is a place.

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
| Given | no id and no path |
| When | `sumi inspect` runs |
| Then | it says what it takes, and the run answers 2 |

## `IN-005` A line inside a comment

| Step | Statement |
| --- | --- |
| Given | a comment whose first line names no scenario and whose next two do |
| When | `sumi inspect` is given any of its lines |
| Then | it answers every scenario the comment claims, with where each is declared |

## `IN-006` A whole file

| Step | Statement |
| --- | --- |
| Given | a file with two comments claiming scenarios |
| When | `sumi inspect` is given its path alone |
| Then | it answers each comment in turn |

## `IN-007` A place claiming nothing

| Step | Statement |
| --- | --- |
| Given | a file with no claim in it |
| When | `sumi inspect` is given a line of it |
| Then | it says nothing is claimed there, and the run answers 0 |
