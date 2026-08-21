# Command

How the executable answers what it is asked to do.

## S-001 — The version is asked for

| Step | Statement |
| --- | --- |
| Given | the executable |
| When | it is run with -v or --version |
| Then | the version is answered |

## S-002 — Nothing is asked for

| Step | Statement |
| --- | --- |
| Given | the executable |
| When | it is run with no arguments |
| Then | the help is answered |

## S-003 — Something unrecognised is asked for

| Step | Statement |
| --- | --- |
| Given | the executable |
| When | it is run with a flag it does not know |
| Then | the help is answered rather than the version |

## S-004 — A word that is no command

| Step | Statement |
| --- | --- |
| Given | the executable |
| When | it is run with a word it does not answer |
| Then | the word is named back and the help is answered |
