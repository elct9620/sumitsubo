# Unreached

A feature whose include covers no file, so nothing can witness it.

## Includes

- `nowhere/*.rb`

## `M-002` A scenario compared against nothing

| Step | Statement |
| --- | --- |
| Given | a feature whose include covers no file |
| When | `sumi verify` runs |
| Then | the include is reported at the line that wrote it |
