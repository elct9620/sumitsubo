# Definitions

What a piece of source declares, read from the syntax tree.

Nesting is recovered from where the nodes sit rather than from the query: a pattern reaches only its direct children, and tree-sitter has no operator for a deeper one. Two constructs spanning the same lines therefore answer with no scope, which loses a prefix rather than inventing one.

## D-001 — A name carries the scopes holding it

| Step | Statement |
| --- | --- |
| Given | a file nesting a module inside a module |
| When | the file is read for what it declares |
| Then | each name answers qualified by the scopes it sits in |

## D-002 — A singleton method and an instance one

| Step | Statement |
| --- | --- |
| Given | a class declaring one of each |
| When | the file is read for what it declares |
| Then | the two are told apart by the way Ruby spells them |

## D-003 — A scope written with its path

| Step | Statement |
| --- | --- |
| Given | a module named the way a path is written rather than by nesting |
| When | the file is read for what it declares |
| Then | the name answers whole, as the source spelled it |

## D-004 — A definition outside every scope

| Step | Statement |
| --- | --- |
| Given | a method declared at the top level of a file |
| When | the file is read for what it declares |
| Then | it answers by its bare name, because there is no path to put in front of it |

## D-006 — Source the grammar cannot read

| Step | Statement |
| --- | --- |
| Given | a Ruby file the grammar cannot parse |
| When | the file is read for what it declares |
| Then | the file is named as unreadable rather than answering with the names it recovered |

## D-007 — A method written inside a reopened singleton class

| Step | Statement |
| --- | --- |
| Given | a class whose `class << self` declares a method |
| When | the file is read for what it declares |
| Then | the name is spelled as belonging to the class rather than to an instance of it |

## D-008 — The kind of each parameter

| Step | Statement |
| --- | --- |
| Given | a method declaring a positional, a keyword, a splat and a block parameter |
| When | the file is read for what it declares |
| Then | each parameter answers with the kind Ruby's spelling gives it, in the order the source wrote them |

## D-009 — A parameter a caller may leave out

| Step | Statement |
| --- | --- |
| Given | a method declaring a parameter with a default, and one gathering the rest |
| When | the file is read for what it declares |
| Then | each of them answers as optional |

## D-010 — A parameter with no name

| Step | Statement |
| --- | --- |
| Given | a method declaring an anonymous splat |
| When | the file is read for what it declares |
| Then | it answers with its kind and no name |

## D-011 — A method declaring no parameters

| Step | Statement |
| --- | --- |
| Given | a method written with an empty parameter list |
| When | the file is read for what it declares |
| Then | it answers an empty list of parameters |

## D-012 — A scope takes no parameters at all

| Step | Statement |
| --- | --- |
| Given | a class in the file |
| When | the file is read for what it declares |
| Then | it answers no parameters, rather than an empty list of them |

## D-013 — A declaration that names no parameter

| Step | Statement |
| --- | --- |
| Given | a method written with `**nil` |
| When | the file is read for what it declares |
| Then | the method answers only the parameters it takes |

## D-014 — A method a call brings into being

| Step | Statement |
| --- | --- |
| Given | a class whose method is written as `attr_reader` |
| When | the file is read for what it declares |
| Then | the method is not among what the file declares |

## D-015 — A method a class mixes in

| Step | Statement |
| --- | --- |
| Given | a module declaring a method |
| Given | a class including that module |
| When | the file is read for what it declares |
| Then | the class does not declare the method |
