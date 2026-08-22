# Language

How a file is read for what a person put in it.

Which language answers for a file is the same question as which files a reading reaches, so it is asked once: a mechanism scans everything its globs cover, and a language claiming nothing is how a file is passed over.

No mechanism names a language. The one answering owns the shapes it hands back — those more than one language would answer with — which is why a region of prose lives here and a name's parameters stay with the reading that makes them.

## L-001 — What a person wrote in a source file

| Step | Statement |
| --- | --- |
| Given | a Ruby file carrying comments and identifiers |
| When | the file is read for what a person wrote |
| Then | the comments answer and nothing else does |

## L-002 — A file no language claims

| Step | Statement |
| --- | --- |
| Given | a prose file |
| When | the file is read for what a person wrote |
| Then | every line of it answers |

## L-003 — Nowhere for a claim to sit

| Step | Statement |
| --- | --- |
| Given | a prose file |
| When | the file is read for where a claim could sit |
| Then | nothing answers |

## L-004 — A file that declares nothing

| Step | Statement |
| --- | --- |
| Given | a prose file |
| When | the file is read for what it declares |
| Then | nothing answers |

## L-005 — Depth is not a barrier

| Step | Statement |
| --- | --- |
| Given | a Ruby file whose claims sit in a class body, a method body and a block comment |
| When | the file is read for where a claim could sit |
| Then | all of them answer, at whatever depth they sit |

## L-006 — A comment nothing follows

| Step | Statement |
| --- | --- |
| Given | a Ruby file whose last line is a comment |
| When | the file is read for where a claim could sit |
| Then | that comment does not answer |

## L-007 — Source the grammar cannot read

| Step | Statement |
| --- | --- |
| Given | a Ruby file the grammar cannot parse |
| When | the file is read for where a claim could sit |
| Then | the file is named as unreadable rather than answering with what it recovered |
