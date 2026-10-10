# Inspect

What a run answers about one place.

## Includes

- `test/*_test.rb`

## `X-001` A scenario relating to one declared beside it

| Attribute | Value |
| --- | --- |
| relates | `X-002` |

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is inspected |
| Then | it answers |

## `X-002` A scenario relating to one nobody declares

| Attribute | Value |
| --- | --- |
| relates | `X-404` |

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is inspected |
| Then | it answers |

## `X-003` A scenario relating to a declared contract

| Attribute | Value |
| --- | --- |
| relates | `contract inspect` |

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is inspected |
| Then | it answers |

## `X-004` A scenario refining a contract nobody declares

| Attribute | Value |
| --- | --- |
| refines | `contract render` |

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is inspected |
| Then | it answers |
