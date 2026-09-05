# Command

How the executable answers what it is asked to do.

## Includes

- `test/help_test.rb`
- `test/version_test.rb`

## `S-001` The version is asked for

| Step | Statement |
| --- | --- |
| Given | the executable |
| When | it is run with -v or --version |
| Then | the version is answered |

## `S-002` Nothing is asked for

| Step | Statement |
| --- | --- |
| Given | the executable |
| When | it is run with no arguments |
| Then | the help is answered |

## `S-003` Something unrecognised is asked for

| Step | Statement |
| --- | --- |
| Given | the executable |
| When | it is run with a flag it does not know |
| Then | the help is answered rather than the version |

## `S-004` A word that is no command

| Step | Statement |
| --- | --- |
| Given | the executable |
| When | it is run with a word it does not answer |
| Then | the word is named back and the help is answered |

## `S-005` A topic is asked for

| Step | Statement |
| --- | --- |
| Given | the executable |
| When | it is run with `help` and a topic it explains |
| Then | that topic is answered |

## `S-006` A word that is no topic

| Step | Statement |
| --- | --- |
| Given | the executable |
| When | it is run with `help` and a word no topic is named by |
| Then | the word is named back and the usage is answered |

## `S-007` A command given a word it does not take

| Step | Statement |
| --- | --- |
| Given | the executable |
| When | it is run with a command and a word that command does not take |
| Then | the word is named back and the usage is answered, and the command never runs |
