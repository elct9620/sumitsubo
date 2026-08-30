# Nodes

What a piece of source declares, read from the syntax tree.

Nesting is recovered from where the nodes sit rather than from the query: a
pattern reaches only its direct children, and tree-sitter has no operator for
a deeper one. Two constructs spanning the same lines therefore answer with no
scope, which loses a prefix rather than inventing one.

A scope is what a name is reached through rather than a keyword, so a constant
assigned a call carrying a block holds what is written inside it — which is how
`Data.define` and `Struct.new` spell a class body. Which call it is goes
unasked. One carrying no block encloses nothing, so it declares nothing either.

## Includes

- `test/nodes_test.rb`
- `test/language_test.rb`

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

## `D-016` Captures grouped by the match they came from

| Step | Statement |
| --- | --- |
| Given | captures from two matches, arriving interleaved |
| When | they are grouped |
| Then | each match answers whole, in the order the parser met them |

## `D-017` A match that declares nothing

| Step | Statement |
| --- | --- |
| Given | a match carrying no capture that names it |
| When | the matches are read for what they declare |
| Then | it answers nothing, and the node beside it carries the lines its text spans |

## `D-018` The nodes holding one, outermost first

| Step | Statement |
| --- | --- |
| Given | a node inside two others, and a third spanning exactly its lines |
| When | what holds it is worked out |
| Then | the two answer outermost first and the third does not, since neither can be told from it |

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
