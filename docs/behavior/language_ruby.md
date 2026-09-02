# Ruby

What Ruby answers when it is the reading a file was handed to.

A scope is what a name is reached through rather than a keyword, so a constant
assigned a call carrying a block holds what is written inside it — which is how
`Data.define` and `Struct.new` spell a class body. Which call it is goes
unasked. One carrying no block encloses nothing, so it declares nothing either.

What the reading does not carry is stated here as well as what it does: a
method a call brings into being and one a class mixes in are both outside what
a file declares, because a syntax tree is read rather than a program run.

## Includes

- `test/language_ruby_test.rb`

## `L-001` What a person wrote in a source file

| Step | Statement |
| --- | --- |
| Given | a Ruby file carrying comments and identifiers |
| When | the file is read for what a person wrote |
| Then | the comments answer and nothing else does |

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

## `D-001` A name carries the scopes holding it

| Step | Statement |
| --- | --- |
| Given | a file nesting a module inside a module |
| When | the file is read for what it declares |
| Then | each name answers qualified by the scopes it sits in |

## `D-002` A singleton method and an instance one

| Step | Statement |
| --- | --- |
| Given | a class declaring one of each |
| When | the file is read for what it declares |
| Then | the two are told apart by the way Ruby spells them |

## `D-003` A scope written with its path

| Step | Statement |
| --- | --- |
| Given | a module named the way a path is written rather than by nesting |
| When | the file is read for what it declares |
| Then | the name answers whole, as the source spelled it |

## `D-004` A definition outside every scope

| Step | Statement |
| --- | --- |
| Given | a method declared at the top level of a file |
| When | the file is read for what it declares |
| Then | it answers by its bare name, because there is no path to put in front of it |

## `D-006` Source the grammar cannot read

| Step | Statement |
| --- | --- |
| Given | a Ruby file the grammar cannot parse |
| When | the file is read for what it declares |
| Then | the file is named as unreadable rather than answering with the names it recovered |

## `D-007` A method written inside a reopened singleton class

| Step | Statement |
| --- | --- |
| Given | a class whose `class << self` declares a method |
| When | the file is read for what it declares |
| Then | the name is spelled as belonging to the class rather than to an instance of it |

## `D-008` The kind of each parameter

| Step | Statement |
| --- | --- |
| Given | a method declaring a positional, a keyword, a splat and a block parameter |
| When | the file is read for what it declares |
| Then | each parameter answers with the kind Ruby's spelling gives it, in the order the source wrote them |

## `D-009` A parameter a caller may leave out

| Step | Statement |
| --- | --- |
| Given | a method declaring a parameter with a default, and one gathering the rest |
| When | the file is read for what it declares |
| Then | each of them answers as optional |

## `D-010` A parameter with no name

| Step | Statement |
| --- | --- |
| Given | a method declaring an anonymous splat |
| When | the file is read for what it declares |
| Then | it answers with its kind and no name |

## `D-011` A method declaring no parameters

| Step | Statement |
| --- | --- |
| Given | a method written with an empty parameter list |
| When | the file is read for what it declares |
| Then | it answers an empty list of parameters |

## `D-012` A scope takes no parameters at all

| Step | Statement |
| --- | --- |
| Given | a class in the file |
| When | the file is read for what it declares |
| Then | it answers no parameters, rather than an empty list of them |

## `D-013` A declaration that names no parameter

| Step | Statement |
| --- | --- |
| Given | a method written with `**nil` |
| When | the file is read for what it declares |
| Then | the method answers only the parameters it takes |

## `D-014` A method a call brings into being

| Step | Statement |
| --- | --- |
| Given | a class whose method is written as `attr_reader` |
| When | the file is read for what it declares |
| Then | the method is not among what the file declares |

## `D-015` A method a class mixes in

| Step | Statement |
| --- | --- |
| Given | a module declaring a method |
| Given | a class including that module |
| When | the file is read for what it declares |
| Then | the class does not declare the method |

## `D-019` A scope a call with a block brings into being

| Step | Statement |
| --- | --- |
| Given | a constant assigned a call carrying a block, and one of them written as a path |
| Given | a method inside each |
| When | the file is read for what it declares |
| Then | each method answers qualified by the constant holding it, the way one inside a class body does |

## `D-020` A constant assigned a call with no block

| Step | Statement |
| --- | --- |
| Given | a constant assigned a call carrying no block |
| When | the file is read for what it declares |
| Then | the constant is not among what the file declares |
