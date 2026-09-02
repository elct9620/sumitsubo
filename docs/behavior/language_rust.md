# Rust

What Rust answers when it is the reading a file was handed to.

A name is the path a reader would write to reach it, which is the path the file
itself carries: `Charge::settle` for a method in an `impl`, `audit::Entry` for a
struct in a `mod`. What a crate is called and which module a file becomes live
in Cargo.toml and in the directory tree, so a name written here stops where the
file does — as the documentation convention does, writing `Vec::push` rather
than the whole path.

What Ruby spells with one node this splits into two, and a block comment ends
with a delimiter the language required rather than with something a person
wrote. Rust lets a caller leave no parameter out, so the question Ruby answers
about a parameter that may be omitted is one this language does not have.

## Includes

- `test/language_rust_test.rb`

## `L-010` A second language reads its own comments

| Step | Statement |
| --- | --- |
| Given | a Rust file carrying line comments, a doc comment and a block comment |
| Given | a block comment with nothing after it |
| When | the file is read for what a person wrote and for what each comment stands next to |
| Then | every comment answers, and the one nothing follows says it stands in front of nothing |

## `L-011` A name is the path the file itself carries

| Step | Statement |
| --- | --- |
| Given | a Rust file whose functions sit in an impl block, a trait and a module |
| When | the file is read for what it declares |
| Then | each name answers as the path a reader would write, the blocks holding it in front of it |

## `L-012` The receiver is a parameter like any other

| Step | Statement |
| --- | --- |
| Given | a Rust function taking a receiver and one taking none |
| When | the file is read for what it declares |
| Then | the receiver answers among the parameters, carrying the kind word that language uses |

## `L-015` A block comment stops before its own closing delimiter

| Step | Statement |
| --- | --- |
| Given | a block comment carrying a claim and code after it |
| Given | text in that comment which is not all ASCII |
| When | the file is read for what a person wrote |
| Then | the region ends where the closing delimiter begins |
