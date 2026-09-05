# Python

What Python answers when it is the reading a file was handed to.

A name is the dotted path the scopes holding it spell, `Charge.settle` for a
method and `Outer.Inner.deep` for a class inside a class, as Sphinx writes one.
Nothing marks a method as belonging to the class rather than to an instance of
it, because Python spells neither: a sigil invented here would be this reading
deciding for the language.

Python's two parameter separators say what the parameters around them are
rather than naming one of their own — everything before a `/` may only be
passed by position, and everything after a `*` only by keyword. Which one a
parameter is therefore cannot be read off the parameter, only off where it
sits, which is the one place a reading here walks a declaration in the order
the source wrote it.

What the reading does not carry. A docstring is a string the language
evaluates rather than a comment, so what a person wrote is narrower here than
in the languages beside it — much of a Python project's vocabulary lives
somewhere this does not look. A module-level assignment declares nothing:
Python has no constant, so reading `LIMIT = 10` as one would mean reading every
assignment as one.

## Includes

- `test/language_python_test.rb`

## `PY-001` A comment, and the docstring that is not one

| Step | Statement |
| --- | --- |
| Given | a Python file carrying comments and a class docstring |
| Given | a comment on the last line |
| When | the file is read for what a person wrote |
| Then | the comments answer, the docstring does not, and the last one stands in front of nothing |

## `PY-002` A name is the dotted path holding it

| Step | Statement |
| --- | --- |
| Given | a method, a method written under a decorator, and a class inside a class |
| When | the file is read for what it declares |
| Then | each answers under the scopes holding it, dotted, and the decorated one answers once |

## `PY-003` What each separator says about the parameters around it

| Step | Statement |
| --- | --- |
| Given | a function declaring a parameter before a `/`, one after a `*`, and one after a splat |
| When | the file is read for what it declares |
| Then | the first answers positional-only and the other two keyword, none of which is written on the parameter |

## `PY-004` Source the grammar cannot read for what a person wrote

| Step | Statement |
| --- | --- |
| Given | a Python file the grammar cannot parse |
| When | the file is read for what a person wrote |
| Then | the file is named as unreadable rather than answering with what it recovered |

## `PY-005` Source the grammar cannot read for what it declares

| Step | Statement |
| --- | --- |
| Given | a Python file the grammar cannot parse |
| When | the file is read for what it declares |
| Then | the file is named as unreadable rather than answering with the names it recovered |
