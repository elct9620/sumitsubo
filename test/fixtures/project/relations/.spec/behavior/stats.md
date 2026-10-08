# Stats

What a run counts.

## Includes

- `test/*_test.rb`

## `SA-001` A scenario the center refines

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is asked |
| Then | it answers |

| Attribute | Value |
| --- | --- |
| relates | `IN-004` |

## `SA-002` A scenario refining what the center refines

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is asked |
| Then | it answers |

| Attribute | Value |
| --- | --- |
| refines | `SA-001` |

## `SA-003` A scenario three relations away

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is asked |
| Then | it answers |

| Attribute | Value |
| --- | --- |
| refines | `SA-002` |
