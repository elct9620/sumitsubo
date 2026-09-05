# Go

What Go answers when it is the reading a file was handed to.

A name carries the type a declaration is reached through, and a Go file puts
one there two ways: a method names its type in a receiver beside it, and a
method written inside an interface is held by the type enclosing it. The first
is where this reading parts from the ones whose languages nest — a receiver is
not a scope the method sits in. Pointer and value spell one type, so `*Charge`
and `Charge` both answer `Charge`. What the package is called lives in the
directory rather than the file, so a name written here stops where the file
does, as go doc links stop it.

Go spells `//` and `/* */` with one node and gives that node no children, so
where a person stopped writing is not something the tree can be asked — it
comes off the text instead. A variadic parameter gathers whatever is there, so
Go does have the question about a parameter a caller may leave out that Rust
does not.

What the reading does not carry: a struct's fields, and the package a file
belongs to, which is written in the directory rather than in what this reads.

## Includes

- `test/language_go_test.rb`

## `GO-001` A third language reads its own comments

| Step | Statement |
| --- | --- |
| Given | a Go file carrying line comments and a block comment |
| Given | a block comment with nothing after it |
| When | the file is read for what a person wrote and for what each comment stands next to |
| Then | every comment answers, and the one nothing follows says it stands in front of nothing |

## `GO-002` A block comment stops before its own closing delimiter

| Step | Statement |
| --- | --- |
| Given | a block comment carrying a claim and code after it |
| Given | text in that comment which is not all ASCII |
| When | the file is read for what a person wrote |
| Then | the region ends where the closing delimiter begins, and a line comment is unchanged |

## `GO-003` A name carries the type it is reached through

| Step | Statement |
| --- | --- |
| Given | a method with a pointer receiver, one with a value receiver, and a method inside an interface |
| When | the file is read for what it declares |
| Then | each answers under its type, and the pointer is no part of the name |

## `GO-004` The parameters a caller has to satisfy

| Step | Statement |
| --- | --- |
| Given | a function declaring two parameters of one type, a variadic one, and one with no name |
| When | the file is read for what it declares |
| Then | the shared type answers as two parameters, the variadic one as optional, and the unnamed one with its kind alone |

## `GO-005` Source the grammar cannot read for what a person wrote

| Step | Statement |
| --- | --- |
| Given | a Go file the grammar cannot parse |
| When | the file is read for what a person wrote |
| Then | the file is named as unreadable rather than answering with what it recovered |

## `GO-006` Source the grammar cannot read for what it declares

| Step | Statement |
| --- | --- |
| Given | a Go file the grammar cannot parse |
| When | the file is read for what it declares |
| Then | the file is named as unreadable rather than answering with the names it recovered |
