# Definitions

What a piece of source declares, read from the syntax tree.

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

## D-005 — A file that is not Ruby

| Step | Statement |
| --- | --- |
| Given | a prose file in scope |
| When | the file is read for what it declares |
| Then | nothing is declared |

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
