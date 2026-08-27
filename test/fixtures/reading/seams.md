# Internal seams

The places this project keeps to one implementation.

## Includes

- `sumitsubo/**/*.rb`

## `Sumitsubo::Where.of` `internal`

The one place a path a reader is handed is made.

```ruby
def self.of(path)
```

## `Store::Handle` `internal`

A handle a second language spells its own way.

```rust
fn of(path: &str) -> String;
```
