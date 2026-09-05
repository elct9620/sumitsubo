# Fmt

Checking that a specification is written the way a reference line is written,
without asking what the source does.

A run has two halves, and only one of them is about the code. This is the
other: every document read as its form reads it, and everything that can be
said about them before a line of source is opened. What it finds is worded and
ordered the way `verify` words and orders a finding, since a reader walks the
same files either way.

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
| When | `sumi fmt` runs |
| Then | nothing is reported, because the drift is not about how the specification is written |

## `FM-002` A document its form refused, beside one that reads

| Step | Statement |
| --- | --- |
| Given | a directory holding a feature whose scenario opens with no id, and one that reads |
| When | `sumi fmt` runs |
| Then | the refusal answers at the line that broke it, and the run leaves the code a comparison could not be made |

## `FM-003` One name declared twice

| Step | Statement |
| --- | --- |
| Given | two features declaring one id, and two definitions registering one name under one marker |
| When | `sumi fmt` runs |
| Then | each is refused naming both places, the way `verify` refuses them |

## `FM-004` No specification to check

| Step | Statement |
| --- | --- |
| Given | a directory with no specification root |
| When | `sumi fmt` runs |
| Then | the missing root is named |

## `FM-005` A specification the configuration switched off

| Step | Statement |
| --- | --- |
| Given | a project that switched the glossary off and keeps no glossary file |
| When | `sumi fmt` runs |
| Then | the missing glossary is not named, because a specification nobody keeps is not read |
