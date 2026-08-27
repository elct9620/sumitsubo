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

## `MD-019` A vocabulary read into sections, terms and the words they reject

| Step | Statement |
| --- | --- |
| Given | a document with two sections, each scoping itself and declaring a term |
| When | the blocks the document is made of are read |
| Then | each section answers its globs and its terms, and a rejected word carries the line it sets aside |

## `MD-020` Two sections declaring one term

| Step | Statement |
| --- | --- |
| Given | a document whose two sections both declare a term of the same name |
| When | the blocks the document is made of are read |
| Then | both are answered, since which one holds where is decided by what its globs cover |

## `MD-021` A rejected word written with and without the separator

| Step | Statement |
| --- | --- |
| Given | rejected words written with the separator, without it, and with no reason at all |
| When | the blocks the document is made of are read |
| Then | each answers the reason it was written with, and the one with none answers nothing |

## `MD-022` A term with no section to belong to

| Step | Statement |
| --- | --- |
| Given | a term written before any section heading |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that heading |

## `MD-023` A vocabulary that declares no section

| Step | Statement |
| --- | --- |
| Given | a document holding prose and no section heading |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since a vocabulary checking nothing was never read |

## `MD-024` A heading under a term that does not open the rejected words

| Step | Statement |
| --- | --- |
| Given | a heading under a term spelled as something other than the reserved one |
| When | the blocks the document is made of are read |
| Then | the specification is refused, naming the word it was given |

## `MD-025` The rejected words written under no term

| Step | Statement |
| --- | --- |
| Given | the reserved heading written before any term |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that heading |

## `MD-026` A rejected word not taken letter for letter

| Step | Statement |
| --- | --- |
| Given | a rejected word written outside backticks |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that item |

## `MD-027` An ignore with no rejection to set aside

| Step | Statement |
| --- | --- |
| Given | an ignore nested under the reserved heading before any rejected word |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that item |

## `MD-028` An ignore with nothing to say why

| Step | Statement |
| --- | --- |
| Given | an ignore naming a line and giving no reason |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since an exception nobody revisits outlives what it was for |

## `MD-029` A list no reserved heading opens is prose

| Step | Statement |
| --- | --- |
| Given | a list written under a term and above the reserved heading |
| When | the blocks the document is made of are read |
| Then | the term rejects nothing, since only a reserved heading says a list declares something |

## `MD-030` A vocabulary nobody wrote

| Step | Statement |
| --- | --- |
| Given | a path where no vocabulary was written |
| When | the vocabulary is asked for |
| Then | the path is named as holding none, before any block is read |

## `MD-031` A definition whose contracts source claims in a comment

| Step | Statement |
| --- | --- |
| Given | a document naming a marker, and a contract with a fence under it |
| When | the blocks the document is made of are read |
| Then | the definition carries the marker and the fence is prose, since a claim needs no signature |

## `MD-032` A definition whose contracts the syntax tree declares

| Step | Statement |
| --- | --- |
| Given | a document with no marker whose two contracts carry fences in different languages |
| When | the blocks the document is made of are read |
| Then | each contract carries the language its own fence names, and the signature as it was written |

## `MD-033` A contract heading naming nothing

| Step | Statement |
| --- | --- |
| Given | a heading that is neither reserved nor opens with a name in backticks |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that heading |

## `MD-034` A flag a contract does not carry

| Step | Statement |
| --- | --- |
| Given | a contract heading carrying a flag outside the closed set |
| When | the blocks the document is made of are read |
| Then | the specification is refused, naming the word it was given |

## `MD-035` Prose written where only a flag is read

| Step | Statement |
| --- | --- |
| Given | a contract heading carrying a sentence after its name |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since a heading carries a name and its flags and nothing else |

## `MD-036` A marker named after a contract is already registered

| Step | Statement |
| --- | --- |
| Given | the reserved heading written below the first contract |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since which reading applies has to be known before a fence arrives |

## `MD-037` A marker heading with no word under it

| Step | Statement |
| --- | --- |
| Given | the reserved heading with no code span following it |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since nothing says what source claims with |

## `MD-038` A contract the syntax tree reading is given no signature for

| Step | Statement |
| --- | --- |
| Given | a document with no marker whose contract carries no fence |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since the fence is what says how the name is spelled |

## `MD-039` A signature whose fence names no language

| Step | Statement |
| --- | --- |
| Given | a fence under a contract opened without a language |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that fence |

## `MD-040` A signature in a language this build does not carry

| Step | Statement |
| --- | --- |
| Given | a fence whose language this build was not built with |
| When | the blocks the document is made of are read |
| Then | the specification is refused, naming the language it was given |

## `MD-041` A name the language it is spelled in could carry no definition of

| Step | Statement |
| --- | --- |
| Given | a contract whose name that language can spell no definition of |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since the code is not what is wrong |

## `MD-042` A definition that names nothing

| Step | Statement |
| --- | --- |
| Given | a document with no title |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since nothing says what it answers for |

## `MD-043` A second fence under one contract

| Step | Statement |
| --- | --- |
| Given | a contract carrying two fences |
| When | the blocks the document is made of are read |
| Then | the first is the signature and the second is prose |
