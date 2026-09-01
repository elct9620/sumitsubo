# Marker

What a piece of source claims to implement, read out of the comments a
language offers.

A contract is named by the interface itself — `GET /users/:id` — rather than
by a handle standing in for it, which is why what follows the marker is read
whole. Behavior's ids are handles and read as a list.

Marker hands back the line either way. How it is read belongs to the mechanism
that named the word.

Where a keyword begins is the comment's business rather than this reading's: a
language writes `//` or `#` against the marker with nothing between, and so does
the `*` down the side of a block comment. Anything but a letter may stand in
front of it, which is what keeps an address out of the claims.

## Includes

- `test/marker_test.rb`

## `M-001` A claim attaches to whatever statement follows it

| Step | Statement |
| --- | --- |
| Given | a linear script whose claims sit in front of statements rather than methods |
| When | the file is scanned for claims |
| Then | each claim answers at the line its comment sits on |

## `M-003` A claim in a block comment

| Step | Statement |
| --- | --- |
| Given | a claim on the second line of a =begin block |
| When | the file is scanned for claims |
| Then | the claim answers at the line its keyword is on rather than where the block began |

## `M-005` What follows the keyword is handed back unread

| Step | Statement |
| --- | --- |
| Given | a comment naming more than one word after the keyword |
| When | the file is scanned for claims |
| Then | the whole of the line after the keyword arrives as one claim |

## `M-008` The path arrives absolute

| Step | Statement |
| --- | --- |
| Given | a Ruby file named by an absolute path |
| When | the file is scanned for claims |
| Then | each claim answers relative to where the run started |

## `M-009` Two keywords in one pass

| Step | Statement |
| --- | --- |
| Given | a file carrying claims under two different keywords |
| When | the file is scanned for both keywords at once |
| Then | each claim names the keyword it was found under |

## `M-010` A keyword with nothing after it

| Step | Statement |
| --- | --- |
| Given | a comment carrying the keyword and nothing else |
| When | the file is scanned for claims |
| Then | the claim arrives carrying no text rather than being dropped |

## `M-011` A keyword the comment is written against

| Step | Statement |
| --- | --- |
| Given | comments writing the marker against `#`, `/*`, `*` and a character outside ASCII |
| Given | one carrying the keyword after a letter |
| When | the file is scanned for claims |
| Then | the first four answer claims and the last answers none |

## `M-012` A claim reaching the code it names, and one reaching none

| Step | Statement |
| --- | --- |
| Given | a run of comments standing in front of code, and a run standing in front of nothing |
| When | the file is scanned for claims |
| Then | every claim in the first run answers as reaching code and every claim in the second as reaching none |
