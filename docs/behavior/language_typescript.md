# TypeScript

What TypeScript answers when it is the reading a file was handed to.

A name is the declaration reference TypeDoc resolves, which is JavaScript's
namepath with what TypeScript adds written under the same marks:
`Charge#settle` for a member reached through a value, `Charge.open` for one
reached through the class, and the dotted path for whatever a namespace or the
module holds. An interface's method is reached through a value like any other
member, so it takes the same `#`.

An abstract class is a node of its own rather than a class carrying a word, so
a reading asking only for a class passes one over without saying it did. A `?`
says outright that a caller may leave a parameter out, where a default only
implies it.

What the reading does not carry. An enum's members are not declared, only the
enum — the same line Rust draws around a variant. A function written inside
another answers by its bare name, and what an object literal holds is outside
this, both as in JavaScript. A name assigned a plain value declares nothing.

## Includes

- `test/language_typescript_test.rb`

## `TS-001` What a person wrote in a file of its own

| Step | Statement |
| --- | --- |
| Given | a file carrying line comments, a JSDoc comment and a block comment |
| Given | a block comment with nothing after it, and text in one that is not all ASCII |
| When | the file is read for what a person wrote and for what each comment stands next to |
| Then | every comment answers, the region ends where the closing delimiter begins, and the one nothing follows says so |

## `TS-002` What TypeScript declares beyond what JavaScript does

| Step | Statement |
| --- | --- |
| Given | an interface, a type alias, an enum, a namespace, an abstract class and an ambient function |
| When | the file is read for what it declares |
| Then | each answers, the abstract class among them, and what a namespace holds answers under its name |

## `TS-003` A parameter the language itself marks as omissible

| Step | Statement |
| --- | --- |
| Given | a method declaring a parameter with a `?`, one with a default, and a rest parameter |
| When | the file is read for what it declares |
| Then | all three answer as optional, and the rest parameter answers once rather than under two kinds |

## `TS-004` Source the grammar cannot read for what a person wrote

| Step | Statement |
| --- | --- |
| Given | a TypeScript file the grammar cannot parse |
| When | the file is read for what a person wrote |
| Then | the file is named as unreadable rather than answering with what it recovered |

## `TS-005` Source the grammar cannot read for what it declares

| Step | Statement |
| --- | --- |
| Given | a TypeScript file the grammar cannot parse |
| When | the file is read for what it declares |
| Then | the file is named as unreadable rather than answering with the names it recovered |
