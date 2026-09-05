# TSX

What TypeScript with JSX answers when it is the reading a file was handed to.

A `.tsx` file is TypeScript, so it declares what TypeScript declares and spells
it the same way — the same TypeDoc reference, `Charge#settle` through a value
and `Charge.open` through the class. What differs is the grammar underneath,
and that difference is why this is a reading of its own rather than something
the one beside it claims: `<Charge />` is a comparison to the other grammar,
which refuses the file outright. Which of the two reads a `.tsx` is therefore
decided by its name and cannot be guessed from what it holds, and a
specification naming the wrong one is refused rather than half-read.

What the reading does not carry is what TypeScript's does not: an enum's
members, a function written inside another, what an object literal holds, and
a name assigned a plain value. The markup itself declares nothing — a component
answers as the function it is.

## Includes

- `test/language_tsx_test.rb`

## `TSX-001` What a person wrote in a file of its own

| Step | Statement |
| --- | --- |
| Given | a file carrying line comments, a JSDoc comment and a block comment |
| Given | a block comment with nothing after it, and text in one that is not all ASCII |
| When | the file is read for what a person wrote and for what each comment stands next to |
| Then | every comment answers, the region ends where the closing delimiter begins, and the one nothing follows says so |

## `TSX-002` A component is the function it is

| Step | Statement |
| --- | --- |
| Given | a component written as an arrow function returning markup, and one written as a function declaration |
| Given | an interface and an abstract class beside them |
| When | the file is read for what it declares |
| Then | each answers as what it is, and the markup declares nothing of its own |

## `TSX-003` The parameters a component takes

| Step | Statement |
| --- | --- |
| Given | a component taking its props as one name, and one taking them apart |
| When | the file is read for what it declares |
| Then | the first answers a plain parameter and the second a destructured one with no name |

## `TSX-004` Source the grammar cannot read for what a person wrote

| Step | Statement |
| --- | --- |
| Given | a TSX file the grammar cannot parse |
| When | the file is read for what a person wrote |
| Then | the file is named as unreadable rather than answering with what it recovered |

## `TSX-005` Source the grammar cannot read for what it declares

| Step | Statement |
| --- | --- |
| Given | a TSX file the grammar cannot parse |
| When | the file is read for what it declares |
| Then | the file is named as unreadable rather than answering with the names it recovered |

## `TSX-006` The grammar beside it cannot read the same file

| Step | Statement |
| --- | --- |
| Given | a TSX file the two grammars of one repository could each be asked for |
| When | it is read as the language the other grammar answers to |
| Then | the file is named as unreadable, rather than answering with what a comparison recovered |
