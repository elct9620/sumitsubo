# Markdown

Reading a specification written as Markdown into the shape every mechanism
judges against.

A specification written this way is the document a person reads as well as the
reference line the tool compares against, so what the reading recovers is the
structure a reader already sees: a title, the globs an Includes section lists,
a scenario heading opening with its id, and the rows stating its steps.

The grammar refuses nothing — every byte sequence is a legal document — so
every shape rule below is the reading's own, and each answers at the line that
broke it rather than at the file.

The grammar is handed to the reading rather than reached for, so the file that
decides what a block means names none. That is why the scenarios about meaning
are claimed from a test whose snapshot can still be regenerated, and only the
one reading a real document is claimed from a test that cannot.

## Includes

- `test/grammar_test.rb`
- `test/markdown_test.rb`

## `MD-001` A document read into a feature and its scenarios

| Step | Statement |
| --- | --- |
| Given | a document with a title, an Includes section and one scenario |
| When | the blocks the document is made of are read |
| Then | the feature carries the title, the globs it scopes by, and the scenario with its steps |

## `MD-002` A paragraph wrapped for a reader says what an unwrapped one says

| Step | Statement |
| --- | --- |
| Given | a description written across several lines |
| When | the blocks the document is made of are read |
| Then | each soft line break answers as a single space |

## `MD-003` A scenario standing on two states

| Step | Statement |
| --- | --- |
| Given | a scenario stating Given twice and no Then |
| When | the blocks the document is made of are read |
| Then | both states are held under given, and no then is held at all |

## `MD-004` An id with nothing written after it

| Step | Statement |
| --- | --- |
| Given | a scenario heading that is an id and nothing else |
| When | the blocks the document is made of are read |
| Then | the scenario carries the id and no title |

## `MD-005` Prose written under a scenario is prose

| Step | Statement |
| --- | --- |
| Given | a paragraph under the title and another under a scenario |
| When | the blocks the document is made of are read |
| Then | the feature says what the paragraph under the title says |

## `MD-006` A scenario heading naming no id

| Step | Statement |
| --- | --- |
| Given | a scenario heading that does not open with a code span |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that heading |

## `MD-007` A pair of backticks with nothing between them

| Step | Statement |
| --- | --- |
| Given | a scenario heading opening with an empty code span |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that heading |

## `MD-008` An include that is not taken letter for letter

| Step | Statement |
| --- | --- |
| Given | an Includes section listing a glob outside backticks |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that item |

## `MD-009` A step row that lost a separator

| Step | Statement |
| --- | --- |
| Given | a step row the grammar reads as one cell |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that row |

## `MD-010` A step row carrying a separator nobody escaped

| Step | Statement |
| --- | --- |
| Given | a step row the grammar reads as three cells |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that row |

## `MD-011` A row naming something that is not a step

| Step | Statement |
| --- | --- |
| Given | a step row whose first cell is neither Given, When nor Then |
| When | the blocks the document is made of are read |
| Then | the specification is refused, naming the word it was given |

## `MD-012` A step with no scenario to belong to

| Step | Statement |
| --- | --- |
| Given | a step row written before any scenario heading |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that row |

## `MD-013` A document that names nothing

| Step | Statement |
| --- | --- |
| Given | a document with no title |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since nothing says what it answers for |

## `MD-014` A document that names itself twice

| Step | Statement |
| --- | --- |
| Given | a document with two titles |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at the second one |

## `MD-015` A real document read through the grammar

| Step | Statement |
| --- | --- |
| Given | a specification file written as Markdown |
| When | the reading is asked what it declares |
| Then | the blocks the query asks for answer with the lines they sit on |

## `MD-016` Which reading answers for a file

| Step | Statement |
| --- | --- |
| Given | a path |
| When | the reading is asked whether it reads it |
| Then | only a path ending in the extension it is written for answers yes |

## `MD-017` The same specification written both ways

| Step | Statement |
| --- | --- |
| Given | one specification written as Markdown and as JSON |
| When | each is read by the reading answering for it |
| Then | the two answer alike in every field but the path and the line |

## `MD-018` A level this reading has no use for is prose

| Step | Statement |
| --- | --- |
| Given | a document whose feature description is broken up by subheadings |
| When | the blocks the document is made of are read |
| Then | the subheadings are passed over and the scenarios are the headings that state one |
