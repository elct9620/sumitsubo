# Markdown

Reading a document written as Markdown into the blocks a form is written in.

A specification written this way is the document a person reads as well as the
reference line the tool compares against, so what is recovered is the structure
a reader already sees: headings and the levels they sit at, paragraphs, the
items of a list and how deep each is, the rows of a table and the cells under
them, and a fenced block with the language it declares.

Two grammars answer. The block one gives that structure and hands back the text
each block holds unparsed; the inline one reads inside that text for the runs a
document marked as taken letter for letter. Every document's structure is read
before any of their text is, so each grammar is asked for one query rather than
for two by turns.

A form says which kinds it is written in and no others, which is why a level one
form has no use for is prose rather than something read and passed over. What a
block means is never asked here: that belongs to the form reading it.

The grammar refuses nothing: every byte sequence is a legal document, so a
specification written wrong loses the shape a query matches rather than failing
to parse, and saying so belongs to the form that was reading it.

## Includes

- `test/grammar_test.rb`

## `MD-002` A paragraph wrapped for a reader says what an unwrapped one says

| Step | Statement |
| --- | --- |
| Given | a description written across several lines |
| When | the blocks the document is made of are read |
| Then | each soft line break answers as a single space |

## `MD-015` A real document read through the grammar

| Step | Statement |
| --- | --- |
| Given | a specification file written as Markdown |
| When | the reading is asked what it declares |
| Then | the blocks the query asks for answer with the lines they sit on |

## `MD-050` The shape a table is drawn with is no part of it

| Step | Statement |
| --- | --- |
| Given | a document whose table carries a heading row and a delimiter row above its own |
| When | the blocks the document is made of are read |
| Then | only the rows beneath them answer, so a form never reads the shape a table is drawn with |

## `MD-016` Which reading answers for a file

| Step | Statement |
| --- | --- |
| Given | a path |
| When | the reading is asked whether it reads it |
| Then | only a path ending in the extension it is written for answers yes |

## `MD-018` A level this reading has no use for is prose

| Step | Statement |
| --- | --- |
| Given | a document whose feature description is broken up by subheadings |
| When | the blocks the document is made of are read |
| Then | the subheadings are passed over and the scenarios are the headings that state one |

## `MD-047` A vocabulary read through the grammar

| Step | Statement |
| --- | --- |
| Given | a vocabulary file written as Markdown |
| When | the reading is asked what it declares |
| Then | each section answers its globs, its terms, the words they reject, and the lines set aside |

## `MD-048` A definition read through the grammar under a marker

| Step | Statement |
| --- | --- |
| Given | a definition file naming a marker, with a fence under one of its contracts |
| When | the reading is asked what it registers |
| Then | the marker answers and the fence is prose |

## `MD-049` A definition registering contracts in two languages

| Step | Statement |
| --- | --- |
| Given | a definition whose two contracts carry fences opened in different languages |
| When | the reading is asked what it registers |
| Then | each contract answers the language its own fence named |
