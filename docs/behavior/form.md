# Form

What each kind of specification makes of the blocks a document is made of.

Three kinds are written in one syntax and each is a form of its own, so each
says which kinds of block it is written in and reads what one means for itself.
The same level states a term in one and is prose in another, and a form that
asked for a kind it does not read would be reading something it never writes.

Nothing here names a format. A run taken letter for letter arrives already
found, so what a form does with one — a name, an id, a word a term turns down —
is the whole of what these scenarios say. How a document becomes those blocks is
the parser's, and is specified where the parser is.

Every shape rule below belongs to the form it was written against, and each
answers at the line that broke it rather than at the file.

A contract's signature is read by the reading that reads the source it
describes, so the shapes a definition can register are the shapes that reading
can find. The heading and the fenced block name one thing written twice, and one
declaring anything else is a contract nobody registered.

## Includes

- `test/markdown_test.rb`

## `F-001` A document read into a feature and its scenarios

| Step | Statement |
| --- | --- |
| Given | a document with a title, an Includes section and one scenario |
| When | the blocks the document is made of are read |
| Then | the feature carries the title, the globs it scopes by, and the scenario with its steps |

## `F-002` A scenario standing on two states

| Step | Statement |
| --- | --- |
| Given | a scenario stating Given twice and no Then |
| When | the blocks the document is made of are read |
| Then | both states are held under given, and no then is held at all |

## `F-003` An id with nothing written after it

| Step | Statement |
| --- | --- |
| Given | a scenario heading that is an id and nothing else |
| When | the blocks the document is made of are read |
| Then | the scenario carries the id and no title |

## `F-004` Prose written under a scenario is prose

| Step | Statement |
| --- | --- |
| Given | a paragraph under the title and another under a scenario |
| When | the blocks the document is made of are read |
| Then | the feature says what the paragraph under the title says |

## `F-005` A scenario heading naming no id

| Step | Statement |
| --- | --- |
| Given | a scenario heading that does not open with a code span |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that heading |

## `F-006` A pair of backticks with nothing between them

| Step | Statement |
| --- | --- |
| Given | a scenario heading opening with an empty code span |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that heading |

## `F-007` An include that is not taken letter for letter

| Step | Statement |
| --- | --- |
| Given | an Includes section listing a glob outside backticks |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that item |

## `F-008` A step row that lost a separator

| Step | Statement |
| --- | --- |
| Given | a step row the grammar reads as one cell |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that row |

## `F-009` A step row carrying a separator nobody escaped

| Step | Statement |
| --- | --- |
| Given | a step row the grammar reads as three cells |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that row |

## `F-010` A row naming something that is not a step

| Step | Statement |
| --- | --- |
| Given | a step row whose first cell is neither Given, When nor Then |
| When | the blocks the document is made of are read |
| Then | the specification is refused, naming the word it was given |

## `F-011` A step with no scenario to belong to

| Step | Statement |
| --- | --- |
| Given | a step row written before any scenario heading |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that row |

## `F-012` A document that names nothing

| Step | Statement |
| --- | --- |
| Given | a document with no title |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since nothing says what it answers for |

## `F-013` A document that names itself twice

| Step | Statement |
| --- | --- |
| Given | a document with two titles |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at the second one |

## `F-014` A vocabulary read into sections, terms and the words they reject

| Step | Statement |
| --- | --- |
| Given | a document with two sections, each scoping itself and declaring a term |
| When | the blocks the document is made of are read |
| Then | one specification answers, its sections carrying their globs and terms, and each rejected word the line it is written on |

## `F-015` Two sections declaring one term

| Step | Statement |
| --- | --- |
| Given | a document whose two sections both declare a term of the same name |
| When | the blocks the document is made of are read |
| Then | both are answered, since which one holds where is decided by what its globs cover |

## `F-016` A rejected word written with and without the separator

| Step | Statement |
| --- | --- |
| Given | rejected words written with the separator, without it, and with no reason at all |
| When | the blocks the document is made of are read |
| Then | each answers the reason it was written with, and the one with none answers nothing |

## `F-017` A term with no section to belong to

| Step | Statement |
| --- | --- |
| Given | a term written before any section heading |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that heading |

## `F-018` A document that never says it is a vocabulary

| Step | Statement |
| --- | --- |
| Given | a document holding sections and terms but no title |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since nothing said it was a vocabulary |

## `F-019` A vocabulary that declares no section

| Step | Statement |
| --- | --- |
| Given | a document holding a title and prose and no section heading |
| When | the blocks the document is made of are read |
| Then | it answers a vocabulary declaring nothing, which is what a project that has written no words yet keeps |

## `F-020` A heading under a term that does not open the rejected words

| Step | Statement |
| --- | --- |
| Given | a heading under a term spelled as something other than the reserved one |
| When | the blocks the document is made of are read |
| Then | the specification is refused, naming the word it was given |

## `F-021` The rejected words written under no term

| Step | Statement |
| --- | --- |
| Given | the reserved heading written before any term |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that heading |

## `F-022` A rejected word not taken letter for letter

| Step | Statement |
| --- | --- |
| Given | a rejected word written outside backticks |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that item |

## `F-023` A rejected word written as an empty pair of marks

| Step | Statement |
| --- | --- |
| Given | a term rejecting a word with nothing between the marks |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that item |

## `F-024` An ignore with no rejection to set aside

| Step | Statement |
| --- | --- |
| Given | an ignore nested under the reserved heading before any rejected word |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that item |

## `F-025` An ignore with nothing to say why

| Step | Statement |
| --- | --- |
| Given | an ignore naming a line and giving no reason |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since an exception nobody revisits outlives what it was for |

## `F-026` A list no reserved heading opens is prose

| Step | Statement |
| --- | --- |
| Given | a list written under a term and above the reserved heading |
| When | the blocks the document is made of are read |
| Then | the term rejects nothing, since only a reserved heading says a list declares something |

## `F-027` A definition whose contracts source claims in a comment

| Step | Statement |
| --- | --- |
| Given | a document naming a marker, and a contract with a fence under it |
| When | the blocks the document is made of are read |
| Then | the definition carries the marker and the fence is prose, since a claim needs no signature |

## `F-028` A definition whose contracts the syntax tree declares

| Step | Statement |
| --- | --- |
| Given | a document with no marker whose two contracts carry fences in different languages |
| When | the blocks the document is made of are read |
| Then | each contract carries the language its own fence names, and the signature as it was written |

## `F-029` A contract heading naming nothing

| Step | Statement |
| --- | --- |
| Given | a heading that is neither reserved nor opens with a name in backticks |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that heading |

## `F-031` Anything written after a contract's name

| Step | Statement |
| --- | --- |
| Given | a contract heading carrying a sentence, or a second run in backticks, after its name |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since a heading carries the name alone |

## `F-045` What a contract's attributes are written as

| Step | Statement |
| --- | --- |
| Given | a row under a contract naming an attribute and the value it takes |
| When | the blocks the document is made of are read |
| Then | the contract carries it, held under the word the first cell names |

## `F-030` An attribute a contract does not carry

| Step | Statement |
| --- | --- |
| Given | a row naming an attribute outside the closed set |
| When | the blocks the document is made of are read |
| Then | the specification is refused, naming the word it was given |

## `F-046` An attribute given a value it does not take

| Step | Statement |
| --- | --- |
| Given | a row writing a known attribute with a value that attribute does not take |
| When | the blocks the document is made of are read |
| Then | the specification is refused, naming the value it was given and the one it takes |

## `F-047` An attribute row standing under no contract

| Step | Statement |
| --- | --- |
| Given | a row written above the first contract |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since a row states an attribute of the contract it sits under |

## `F-048` An attribute row of another width

| Step | Statement |
| --- | --- |
| Given | a row under a contract carrying one cell rather than two |
| When | the blocks the document is made of are read |
| Then | the specification is refused, naming how many cells it turned out to have |

## `F-049` One attribute written twice

| Step | Statement |
| --- | --- |
| Given | two rows under one contract naming the same attribute |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since an attribute written twice says which of them it is nowhere |

## `F-032` A marker named after a contract is already registered

| Step | Statement |
| --- | --- |
| Given | the reserved heading written below the first contract |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since which reading applies has to be known before a fence arrives |

## `F-033` A marker heading with no word under it

| Step | Statement |
| --- | --- |
| Given | the reserved heading with no code span following it |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since nothing says what source claims with |

## `F-034` A contract the syntax tree reading is given no signature for

| Step | Statement |
| --- | --- |
| Given | a document with no marker whose contract carries no fence |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since the fence is what says how the name is spelled |

## `F-035` A signature whose fence names no language

| Step | Statement |
| --- | --- |
| Given | a fence under a contract opened without a language |
| When | the blocks the document is made of are read |
| Then | the specification is refused, answering at that fence |

## `F-036` A signature in a language this build does not carry

| Step | Statement |
| --- | --- |
| Given | a fence whose language this build was not built with |
| When | the blocks the document is made of are read |
| Then | the specification is refused, naming the language it was given |

## `F-037` A signature declaring a name other than the contract's

| Step | Statement |
| --- | --- |
| Given | a contract whose fence does not declare the name its heading registers |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since what a contract registers is what its signature declares |

## `F-038` A signature declaring a second contract

| Step | Statement |
| --- | --- |
| Given | a fence declaring the contract's name and another name beside it |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since a signature declares one contract and the scopes holding it |

## `F-039` A signature the reading cannot read

| Step | Statement |
| --- | --- |
| Given | a fence whose content the language it names cannot parse |
| When | the blocks the document is made of are read |
| Then | the specification is refused under the name of the document rather than of the source |

## `F-040` A definition that names nothing

| Step | Statement |
| --- | --- |
| Given | a document with no title |
| When | the blocks the document is made of are read |
| Then | the specification is refused, since nothing says what it answers for |

## `F-041` A second fence under one contract

| Step | Statement |
| --- | --- |
| Given | a contract carrying two fences |
| When | the blocks the document is made of are read |
| Then | the first is the signature and the second is prose |

## `F-042` Includes written at the level a feature writes them

| Step | Statement |
| --- | --- |
| Given | a feature scoping itself under the second level, and a list elsewhere |
| When | the blocks the document is made of are read |
| Then | only the globs under the reserved heading answer, each carrying the line it was written on |

## `F-043` Includes written at the level a vocabulary writes them

| Step | Statement |
| --- | --- |
| Given | two sections each scoping itself under the third level, and a list elsewhere |
| When | the blocks the document is made of are read |
| Then | each section answers its own globs, since a boundary is the section's rather than the document's |

## `F-044` One glob written twice

| Step | Statement |
| --- | --- |
| Given | two sections whose includes name one glob |
| When | the blocks the document is made of are read |
| Then | each section keeps its own, so a reader is sent to the section that wrote it |
