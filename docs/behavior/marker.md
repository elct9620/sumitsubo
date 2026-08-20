# Marker

What a piece of source claims to implement, read from the comment in front of it.

## M-001 — A claim attaches to whatever statement follows it

| Step | Statement |
| --- | --- |
| Given | a linear script whose claims sit in front of statements rather than methods |
| When | the file is scanned for claims |
| Then | each claim answers at the line its comment sits on |

## M-002 — Depth is not a barrier

| Step | Statement |
| --- | --- |
| Given | claims inside a class body and inside a method body |
| When | the file is scanned for claims |
| Then | both are read, at whatever depth they sit |

## M-003 — A claim in a block comment

| Step | Statement |
| --- | --- |
| Given | a claim on the second line of a =begin block |
| When | the file is scanned for claims |
| Then | the claim answers at the line its keyword is on rather than where the block began |

## M-004 — A comment nothing follows

| Step | Statement |
| --- | --- |
| Given | a claim at the end of a file with no code after it |
| When | the file is scanned for claims |
| Then | nothing is claimed |

## M-005 — Several ids on one line

| Step | Statement |
| --- | --- |
| Given | a comment naming more than one id after the keyword |
| When | the file is scanned for claims |
| Then | each id is read as its own claim |

## M-006 — A file that is not Ruby

| Step | Statement |
| --- | --- |
| Given | a prose file in scope carrying the keyword |
| When | the file is scanned for claims |
| Then | nothing is claimed |

## M-007 — Source the grammar cannot read

| Step | Statement |
| --- | --- |
| Given | a Ruby file the grammar cannot parse |
| When | the file is scanned for claims |
| Then | the file is named as unreadable rather than answering with the claims it recovered |

## M-008 — The path arrives absolute

| Step | Statement |
| --- | --- |
| Given | a Ruby file named by an absolute path |
| When | the file is scanned for claims |
| Then | each claim answers relative to where the run started |
