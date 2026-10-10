# Fmt

Writing a specification the way a reference line is written, and saying what
cannot be written that way, without asking what the source does.

A run has two halves, and only one of them is about the code. This is the
other. It reads every document as its form reads it, and says everything that
can be said about them before a line of source is opened. What it finds is
worded and ordered the way `verify` words and orders a finding, since a reader
walks the same files either way.

A document is rewritten in place, and in place is the reference line itself,
so `--check` is what says the same thing and changes nothing. What each form
has to say about how its own documents are written is that form's own. How long
the prose of any of them may run is the budget's.

A signature is still read as the language it names, since that is what says how
a name is spelled. A definition registering a name no reading can find is not
written the way a reference line is written. No file a specification covers is
opened.

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
| Given | a rejected word and the line it sets aside, set off with wide dashes |
| Given | a wide dash in the word's reason and in the definition above it |
| When | `sumi fmt --check` runs |
| Then | both lines are answered as written otherwise than a reference line is, and the file is left alone |

## `FM-007` A word set off with a wide dash, and the run that writes it

| Step | Statement |
| --- | --- |
| Given | a rejected word and the line it sets aside, set off with wide dashes |
| Given | a wide dash in the word's reason and in the definition above it |
| When | `sumi fmt` runs |
| Then | the file is named as written, both dashes are the plain one, and a second run has nothing to say |

## `FM-008` A vocabulary refused in two places

| Step | Statement |
| --- | --- |
| Given | a vocabulary writing two titles and its section's include heading twice |
| When | `sumi fmt --check` runs |
| Then | each refusal answers at its own line |

## `FM-009` A refused vocabulary leaves the check unable to compare

| Step | Statement |
| --- | --- |
| Given | a vocabulary writing two titles and its section's include heading twice |
| When | `sumi fmt --check` runs |
| Then | the run leaves the code a comparison could not be made |

## `FM-010` The run that writes it leaves the prose alone

| Step | Statement |
| --- | --- |
| Given | a rejected word and the line it sets aside, set off with wide dashes |
| Given | a wide dash in the word's reason and in the definition above it |
| When | `sumi fmt` runs |
| Then | both dashes in the prose stand, because what sets a word off is where it sits |

## `FM-011` A scenario written before a lower id

| Step | Statement |
| --- | --- |
| Given | a feature writing `O-10` between `O-1` and `O-2` |
| When | `sumi fmt --check` runs |
| Then | `O-10` answers at its heading, naming `O-2`, and the file is left alone |

## `FM-012` The run that puts scenarios in order

| Step | Statement |
| --- | --- |
| Given | a feature writing `O-10` between `O-1` and `O-2`, and `O-9` last |
| When | `sumi fmt` runs |
| Then | the scenarios read `O-1`, `O-2`, `O-9`, `O-10`, and a second run has nothing to say |

## `FM-013` A project that switched order off

| Step | Statement |
| --- | --- |
| Given | a feature writing `O-10` between `O-1` and `O-2`, and `order: false` on behavior |
| When | `sumi fmt` runs |
| Then | the file is left as written |

## `FM-014` Two ids of one value

| Step | Statement |
| --- | --- |
| Given | a feature writing `P-1` before `P-01` |
| When | `sumi fmt --check` runs |
| Then | `P-1` answers as written before `P-01`, the letters deciding between them |

## `FM-015` A scenario writing its attributes under its steps

| Step | Statement |
| --- | --- |
| Given | a scenario whose attributes table follows its steps |
| When | `sumi fmt --check` runs |
| Then | the scenario answers at the table's first row, and the file is left alone |

## `FM-016` The run that writes a scenario's attributes above its steps

| Step | Statement |
| --- | --- |
| Given | a scenario whose attributes table follows its steps |
| When | `sumi fmt` runs |
| Then | the attributes read right above the steps, and a second run has nothing to say |

## `FM-017` A contract writing its attributes under its signature

| Step | Statement |
| --- | --- |
| Given | a contract whose attributes table follows its signature |
| When | `sumi fmt --check` runs |
| Then | the contract answers at the table's first row, and the file is left alone |

## `FM-018` The run that writes a contract's attributes above its signature

| Step | Statement |
| --- | --- |
| Given | a contract writing prose, its signature, a note after it, and then its attributes |
| When | `sumi fmt` runs |
| Then | the attributes read between the prose and the signature, and the note stays after the signature |

## `FM-019` A contract with no signature writes its attributes last

| Step | Statement |
| --- | --- |
| Given | a contract under a marker writing its attributes above its prose |
| When | `sumi fmt` runs |
| Then | the attributes read after the prose |

## `FM-020` A project that switched arrange off

| Step | Statement |
| --- | --- |
| Given | a scenario and a contract writing their attributes after their steps and signature, and `arrange: false` on both |
| When | `sumi fmt` runs |
| Then | both files are left as written |

## `FM-021` A scenario out of order whose attributes are under its steps

| Step | Statement |
| --- | --- |
| Given | a feature writing `A-2` before `A-1`, with `A-2`'s attributes under its steps |
| When | `sumi fmt` runs |
| Then | `A-1` reads first and `A-2` reads its attributes above its steps |
