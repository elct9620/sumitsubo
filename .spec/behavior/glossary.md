# Glossary

The domain vocabulary a project declares, and the words it rejects in their
place.

## Includes

- `test/glossary_test.rb`

## `G-001` An entry reaches the files its includes cover, under the name it carries

| Step | Statement |
| --- | --- |
| Given | a glossary carrying Global and a named subdomain, each with include globs |
| When | the entries are resolved against the base |
| Then | each answers the files its globs cover, Global under that name and the subdomain under its own |

## `G-002` A subdomain stands in for Global where both name one term

| Step | Statement |
| --- | --- |
| Given | Global and a subdomain covering one file and declaring the same term |
| When | the effective vocabulary for that file is worked out |
| Then | the subdomain's term replaces Global's outright, its rejected words included |

## `G-003` A missing glossary is a broken reference line

| Step | Statement |
| --- | --- |
| Given | a path where no glossary was written |
| When | the glossary is loaded |
| Then | the path is named as one holding no glossary |

## `G-004` A glossary that will not parse

| Step | Statement |
| --- | --- |
| Given | a glossary file that is not readable JSON |
| When | the glossary is loaded |
| Then | the file is named as unreadable |

## `G-005` A file declaring no glossary at all

| Step | Statement |
| --- | --- |
| Given | readable JSON with no glossary in it |
| When | the glossary is loaded |
| Then | the file is named as declaring no glossary |

## `G-006` The root arrives absolute

| Step | Statement |
| --- | --- |
| Given | a glossary named by an absolute path that is not there |
| When | the glossary is loaded |
| Then | the path answers relative to where the run started |

## `G-007` Order is all that decides which vocabulary is laid over which

| Step | Statement |
| --- | --- |
| Given | Global and a subdomain covering one file and declaring the same term |
| When | the entries are read in the reverse of the order the specification writes them |
| Then | Global's term replaces the subdomain's, which is why Global is written first |

## `G-008` The specification spelling a word is not a use of it

| Step | Statement |
| --- | --- |
| Given | findings against the glossary's own file and against a source file, for a word the glossary spells |
| When | the uses among them are worked out |
| Then | the one at the line the glossary spells the word on is set aside, and the other stands |

## `G-009` A finding the specification sets aside by hand is not reported

| Step | Statement |
| --- | --- |
| Given | a rejection carrying an ignore, and findings at that line and at another |
| When | the findings that still stand are worked out |
| Then | the one the ignore names is set aside and the other stands |

## `G-010` An ignore naming no finding is a broken reference line

| Step | Statement |
| --- | --- |
| Given | a rejection carrying an ignore that no finding answers to |
| When | the unresolved ignores are worked out |
| Then | it answers at the line the specification wrote it on, saying what it no longer names |

## `G-011` An ignore missing either half is refused where it is written

| Step | Statement |
| --- | --- |
| Given | a glossary writing an ignore with no place to point, and one with no reason |
| When | the glossary is loaded |
| Then | each is named as one the specification cannot carry |
