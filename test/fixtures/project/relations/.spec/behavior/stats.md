# Stats

What a run counts.

## Includes

- `test/*_test.rb`

## `SA-001` A scenario the center refines

| Attribute | Value |
| --- | --- |
| relates | `IN-004` |

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is asked |
| Then | it answers |

## `SA-002` A scenario refining what the center refines

| Attribute | Value |
| --- | --- |
| refines | `SA-001` |

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is asked |
| Then | it answers |

## `SA-003` A scenario three relations away

| Attribute | Value |
| --- | --- |
| refines | `SA-002` |

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is asked |
| Then | it answers |
