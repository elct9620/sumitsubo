# Budget

How long a specification's prose may run, measured by `fmt` against the limits
a project writes. The limits follow ASD-STE100: a sentence of 25 words and a
paragraph of six sentences.

A word is a run of Latin letters or digits, and a span of inline code is one
word. Prose with no Latin letters counts nothing yet.

A paragraph and a list item are measured for both limits. A table cell is
measured for its sentences alone, since a row is already one statement.

## Includes

- `test/budget_test.rb`
- `test/fmt_test.rb`

## `BU-001` A sentence over its limit

| Step | Statement |
| --- | --- |
| Given | a budget of 25 words a sentence, and a paragraph with a sentence of 30 |
| When | `sumi fmt --check` runs |
| Then | the paragraph's line is answered with the sentence's opening words and its count, and the run answers 1 |

## `BU-002` A paragraph over its limit

| Step | Statement |
| --- | --- |
| Given | a budget of six sentences a paragraph, and a list item of seven |
| When | the item is measured |
| Then | it is answered with its count |

## `BU-003` Inline code is one word

| Step | Statement |
| --- | --- |
| Given | a sentence of 25 words, one of them a span of code holding spaces and a period |
| When | it is measured against 25 |
| Then | it is within its limit, and is one sentence |

## `BU-004` A cell is measured for its sentences alone

| Step | Statement |
| --- | --- |
| Given | a table cell of seven short sentences, and one of a long sentence |
| When | they are measured against six sentences and 25 words |
| Then | only the long sentence is answered |

## `BU-005` Only what the budget writes is measured

| Step | Statement |
| --- | --- |
| Given | a budget limiting sentences alone, and a paragraph of seven short sentences |
| When | it is measured |
| Then | nothing is answered |

## `BU-006` No budget measures nothing

| Step | Statement |
| --- | --- |
| Given | a project writing no budget, and a sentence of 30 words |
| When | `sumi fmt --check` runs |
| Then | nothing is answered, and the run answers 0 |

## `BU-007` The run that writes still answers

| Step | Statement |
| --- | --- |
| Given | a sentence over its limit, beside a word set off with a wide dash |
| When | `sumi fmt` runs |
| Then | the dash is rewritten, the sentence is answered, and the run answers 1 |
