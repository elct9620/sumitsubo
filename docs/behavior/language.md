# Language

Which reading answers for a file, and what a build carries at all.

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

What each reading then makes of what it was handed is a feature of its own,
one per language, beside that language's own material under
`test/fixtures/source/`. A language this build gains brings one, and the
questions it has to answer are the ones its neighbours already did.

## Includes

- `test/language_test.rb`

## `L-002` A file no language claims

| Step | Statement |
| --- | --- |
| Given | a prose file |
| When | the file is read for what a person wrote |
| Then | every line of it answers |

## `L-004` The language a specification named is the one that reads it

| Step | Statement |
| --- | --- |
| Given | a source file |
| Given | a specification naming the language it is written in |
| When | the file is read for what it declares |
| Then | that language answers, rather than the one the filename implies |

## `L-008` A language this build was not given

| Step | Statement |
| --- | --- |
| Given | a name no language this executable carries answers to |
| When | the build is asked whether it carries that language |
| Then | it answers that it does not, rather than reading the file some other way |

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
