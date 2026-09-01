# Language

How a file is read for what a person put in it.

Which language reads a file for what a person wrote is the same question as
which files a reading reaches, so it is asked once: a mechanism scans
everything its globs cover, and a language claiming nothing is how a file is
passed over. Reading it for what it declares is a different question — a name
is spelled the way one language spells it — so there the language arrives
named.

No mechanism names a language. The one answering owns the shapes it hands back
— those more than one language would answer with — which is why a region of
prose lives here and a name's parameters stay with the reading that makes
them.

## Includes

- `test/language_test.rb`

## `L-001` What a person wrote in a source file

| Step | Statement |
| --- | --- |
| Given | a Ruby file carrying comments and identifiers |
| When | the file is read for what a person wrote |
| Then | the comments answer and nothing else does |

## `L-002` A file no language claims

| Step | Statement |
| --- | --- |
| Given | a prose file |
| When | the file is read for what a person wrote |
| Then | every line of it answers |

## `L-003` What a line of prose stands in front of

| Step | Statement |
| --- | --- |
| Given | a prose file |
| When | the file is read for what a person wrote |
| Then | every line stands in front of more of the same, and the last in front of nothing |

## `L-004` The language a specification named is the one that reads it

| Step | Statement |
| --- | --- |
| Given | a source file |
| Given | a specification naming the language it is written in |
| When | the file is read for what it declares |
| Then | that language answers, rather than the one the filename implies |

## `L-005` Depth is not a barrier

| Step | Statement |
| --- | --- |
| Given | a Ruby file whose comments sit in a class body, a method body and a block comment |
| When | the file is read for what each comment stands next to |
| Then | every one answers code, at whatever depth it sits |

## `L-006` A comment nothing follows

| Step | Statement |
| --- | --- |
| Given | a Ruby file whose last line is a comment |
| When | the file is read for what each comment stands next to |
| Then | that comment answers nothing, and one standing in front of another answers a comment |

## `L-007` Source the grammar cannot read

| Step | Statement |
| --- | --- |
| Given | a Ruby file the grammar cannot parse |
| When | the file is read for what a person wrote |
| Then | the file is named as unreadable rather than answering with what it recovered |

## `L-008` A language this build was not given

| Step | Statement |
| --- | --- |
| Given | a name no language this executable carries answers to |
| When | the build is asked whether it carries that language |
| Then | it answers that it does not, rather than reading the file some other way |

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

## `L-013` What a piece of text declares

| Step | Statement |
| --- | --- |
| Given | a declaration written as text rather than to a file |
| When | it is read as the language it is spelled in |
| Then | it answers the same name and shape the file holding it would, at where the caller said |

## `L-014` Text the grammar cannot read

| Step | Statement |
| --- | --- |
| Given | a piece of text the language cannot parse |
| When | it is read for what it declares |
| Then | the reading refuses rather than answering what it recovered |

## `L-015` A block comment stops before its own closing delimiter

| Step | Statement |
| --- | --- |
| Given | a block comment carrying a claim and code after it |
| Given | text in that comment which is not all ASCII |
| When | the file is read for what a person wrote |
| Then | the region ends where the closing delimiter begins |
