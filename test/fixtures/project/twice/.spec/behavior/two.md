# two

A feature declaring an id the one beside it declares as well.

## Includes

- `test/*_test.rb`

## `B-001` A scenario an id stands for twice

| Step | Statement |
| --- | --- |
| Given | two features declaring one id |
| When | `sumi verify` runs |
| Then | the id is refused, because a claim naming it resolves to neither |
