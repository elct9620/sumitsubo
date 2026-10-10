# Inspect

What a run answers about one place.

## Includes

- `test/*_test.rb`

## `X-001` A scenario relating to one declared beside it

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is inspected |
| Then | it answers |

| Attribute | Value |
| --- | --- |
| relates | `X-002` |

## `X-002` A scenario relating to one nobody declares

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is inspected |
| Then | it answers |

| Attribute | Value |
| --- | --- |
| relates | `X-404` |

## `X-003` A scenario relating to a declared contract

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is inspected |
| Then | it answers |

| Attribute | Value |
| --- | --- |
| relates | `contract inspect` |

## `X-004` A scenario refining a contract nobody declares

| Step | Statement |
| --- | --- |
| Given | a project |
| When | it is inspected |
| Then | it answers |

| Attribute | Value |
| --- | --- |
| refines | `contract render` |
