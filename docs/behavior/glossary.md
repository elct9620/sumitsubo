# Glossary

The domain vocabulary a project declares, and the words it rejects in their
place.

## Includes

- `test/glossary_test.rb`

## `G-001` A section reaches the files its includes cover, under the name it carries

| Step | Statement |
| --- | --- |
| Given | a vocabulary carrying two sections, each with include globs |
| When | the sections are resolved against the base |
| Then | each answers the files its own globs cover, under the name it was written with |

## `G-012` A glob two sections share is one mistake rather than two

| Step | Statement |
| --- | --- |
| Given | two sections whose includes name one glob |
| When | the vocabulary is asked what its includes cover |
| Then | the glob is asked about once, at the line the first section wrote it on |

## `G-017` A section that declares words and reaches nowhere

| Step | Statement |
| --- | --- |
| Given | a vocabulary with one section declaring a term and writing no glob, and one writing neither |
| When | the vocabulary is asked what its includes cover |
| Then | only the one declaring a term answers, as a failure at the section, since a word held in no file is checked nowhere |

## `G-002` A later section stands in for an earlier one where both name a term

| Step | Statement |
| --- | --- |
| Given | two sections covering one file and declaring the same term |
| When | the effective vocabulary for that file is worked out |
| Then | the later section's term replaces the earlier one outright, its rejected words included |

## `G-003` A missing glossary is a broken reference line

| Step | Statement |
| --- | --- |
| Given | a path where no glossary was written |
| When | the glossary is loaded |
| Then | the path is named as one holding no glossary |

## `G-005` A file that never says it is a vocabulary

| Step | Statement |
| --- | --- |
| Given | a document with sections and terms but no title |
| When | the glossary is loaded |
| Then | the file is named as declaring no title |

## `G-006` The root arrives absolute

| Step | Statement |
| --- | --- |
| Given | a glossary named by an absolute path that is not there |
| When | the glossary is loaded |
| Then | the path answers relative to where the run started |

## `G-007` Order is all that decides which vocabulary is laid over which

| Step | Statement |
| --- | --- |
| Given | two sections covering one file and declaring the same term |
| When | the sections are read in the reverse of the order the specification writes them |
| Then | the first section's term replaces the second's, which is why order is what a project writes its sections in |

## `G-008` The specification spelling a word is not a use of it

| Step | Statement |
| --- | --- |
| Given | mentions against the glossary's own file and against a source file, for a word the glossary spells |
| When | the uses among them are worked out |
| Then | the one at the line the glossary spells the word on is set aside, and the other stands |

## `G-009` A mention the specification sets aside by hand is not reported

| Step | Statement |
| --- | --- |
| Given | a rejection carrying an ignore, and mentions at that line and at another |
| When | the mentions that still stand are worked out |
| Then | the one the ignore names is set aside and the other stands |

## `G-010` An ignore naming no mention is a broken reference line

| Step | Statement |
| --- | --- |
| Given | a rejection carrying an ignore that no mention answers to |
| When | the ignores that have gone stale are worked out |
| Then | it answers at the line the specification wrote it on, saying what it no longer names |

## `G-011` An ignore missing either half is refused where it is written

| Step | Statement |
| --- | --- |
| Given | a glossary writing an ignore with no place to point, and one with no reason |
| When | the glossary is loaded |
| Then | each is named as one the specification cannot carry |

## `G-013` A section opened twice under one name is refused where the second is written

| Step | Statement |
| --- | --- |
| Given | a glossary opening two sections under one name |
| When | the glossary is loaded |
| Then | the second is named as one the specification cannot carry, naming the line the first was opened at |

## `G-014` A term declared twice in one section is refused, where twice in two is not

| Step | Statement |
| --- | --- |
| Given | a glossary whose second section declares a term the first already did, and then declares it again |
| When | the glossary is loaded |
| Then | only the one repeated inside a section is named as one the specification cannot carry, naming the line that section first declared it at |

## `G-015` A word rejected twice under one term is refused, where twice under two is not

| Step | Statement |
| --- | --- |
| Given | a glossary whose section has two terms turning down one word, and one of them turning it down twice |
| When | the glossary is loaded |
| Then | only the one repeated under a term is named as one the specification cannot carry, naming the line that term first rejected it at |

## `G-016` A line set aside twice under one word is refused, where twice under two is not

| Step | Statement |
| --- | --- |
| Given | a glossary whose term has two words setting one line aside, and one of them setting it aside twice |
| When | the glossary is loaded |
| Then | only the one repeated under a word is named as one the specification cannot carry, naming the line that word first set it aside at |

## `G-018` A longer term holding a rejected word is a use of that term

| Step | Statement |
| --- | --- |
| Given | a term rejecting a word that its own name and another term's name each hold |
| When | a file writing both names and the word on its own is checked |
| Then | only the line writing the word on its own answers |

## `G-019` A specification beside the vocabulary takes the sections its includes reach

| Step | Statement |
| --- | --- |
| Given | two sections, and a specification whose includes reach a file only the first covers |
| When | the effective vocabulary is worked out with that specification beside it |
| Then | the specification's own file takes the first section's terms and not the second's |

## `G-020` A longer term a line break cuts in two is still that term

| Step | Statement |
| --- | --- |
| Given | a term rejecting a word that its own name and another term's name each hold |
| When | prose and a run of line comments wrapping both names are checked |
| Then | only the lines writing the word on its own answer |

## `G-021` A sentence ending on half a term does not carry it on

| Step | Statement |
| --- | --- |
| Given | a term rejecting a word that its own name and another term's name each hold |
| When | prose and a run of line comments wrapping both names are checked |
| Then | a sentence ending on the first half does not carry it into the next line |
