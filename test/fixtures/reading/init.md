# Init

Laying down an empty specification to start a reference line from.

## Includes

- `test/init_test.rb`

## `I-001` The first run lays down what a reference line starts from

| Step | Statement |
| --- | --- |
| Given | a directory with no specification |
| When | `sumi init` runs |
| Then | an empty glossary specification is created at the configured root |

## `I-002` A second run leaves the reference line alone

| Step | Statement |
| --- | --- |
| Given | a directory `sumi init` has already run in |
| When | `sumi init` runs again |
| Then | each specification is reported as already there rather than replaced |

## `I-003` A configured root is created however deep it is

| Step | Statement |
| --- | --- |
| Given | a .sumi.json naming a root two directories down |
| When | `sumi init` runs |
| Then | every directory on the way to that root is created |

## `I-004` The first run lays down somewhere for behaviors to go

| Step | Statement |
| --- | --- |
| Given | a directory with no specification |
| When | `sumi init` runs |
| Then | a behavior directory is created at the configured root |

## `I-005` The first run lays down somewhere for contracts to go

| Step | Statement |
| --- | --- |
| Given | a directory with no specification |
| When | `sumi init` runs |
| Then | a contract directory is created at the configured root |

