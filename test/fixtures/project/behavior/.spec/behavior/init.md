# Init

What init lays down to start a reference line from.

## Includes

- `test/init_test.rb`

## `I-001` The first run lays down an empty glossary

| Step | Statement |
| --- | --- |
| Given | a directory with no specification |
| When | `sumi init` runs |
| Then | an empty glossary specification is written at the configured root |

## `I-002` A second run leaves what is there alone

| Step | Statement |
| --- | --- |
| Given | a directory init has already run in |
| When | `sumi init` runs |
| Then | the existing specification is reported as already there |

## `I-003` A configured root is created however deep it is

| Step | Statement |
| --- | --- |
| Given | a .sumi.json naming a root two levels down |
| When | `sumi init` runs |
| Then | every directory on the way to that root is created |
