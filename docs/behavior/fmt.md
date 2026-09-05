# Fmt

Writing a specification the way a reference line is written, and saying what
cannot be written that way, without asking what the source does.

A run has two halves, and only one of them is about the code. This is the
other: every document read as its form reads it, and everything that can be
said about them before a line of source is opened. What it finds is worded and
ordered the way `verify` words and orders a finding, since a reader walks the
same files either way.

A document is rewritten in place, and in place is the reference line itself,
so `--check` is what says the same thing and changes nothing. What each form
has to say about how its own documents are written is that form's own; today
only the vocabulary has anything to say.

A signature is still read as the language it names — that is what says how a
name is spelled, and a definition registering a name no reading can find is
not written the way a reference line is written. No file a specification
covers is opened.

## Includes

- `test/fmt_test.rb`

## `FM-001` Source that drifted says nothing here

| Step | Statement |
| --- | --- |
| Given | a project whose source has drifted from its glossary |
| When | `sumi fmt --check` runs |
| Then | nothing is reported, because the drift is not about how the specification is written |

## `FM-002` A document its form refused, beside one that reads

| Step | Statement |
| --- | --- |
| Given | a directory holding a feature whose scenario opens with no id, and one that reads |
| When | `sumi fmt --check` runs |
| Then | the refusal answers at the line that broke it, and the run leaves the code a comparison could not be made |

## `FM-003` One name declared twice

| Step | Statement |
| --- | --- |
| Given | two features declaring one id, and two definitions registering one name under one marker |
| When | `sumi fmt --check` runs |
| Then | each is refused naming both places, the way `verify` refuses them |

## `FM-004` No specification to check

| Step | Statement |
| --- | --- |
| Given | a directory with no specification root |
| When | `sumi fmt --check` runs |
| Then | the missing root is named |

## `FM-005` A specification the configuration switched off

| Step | Statement |
| --- | --- |
| Given | a project that switched the glossary off and keeps no glossary file |
| When | `sumi fmt --check` runs |
| Then | the missing glossary is not named, because a specification nobody keeps is not read |

## `FM-006` A word set off with a wide dash, and the run that only says so

| Step | Statement |
| --- | --- |
| Given | a vocabulary setting a rejected word and the line it sets aside off with a wide dash |
| Given | a wide dash in the reason that word carries, and one in the definition above it |
| When | `sumi fmt --check` runs |
| Then | both lines are answered as written otherwise than a reference line is, and the file is left alone |

## `FM-007` And the run that writes it

| Step | Statement |
| --- | --- |
| Given | the same vocabulary |
| When | `sumi fmt` runs |
| Then | the file is named as written, both dashes are the plain one, and a second run has nothing to say |
| Then | both dashes in the prose stand, because what sets a word off is where it sits |
