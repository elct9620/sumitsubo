# Internal seams

The places this project keeps to one implementation.

## Includes

- `sumitsubo/**/*.rb`

## `Sumitsubo::Where.of` `internal`

The one place a path a reader is handed is made.

```ruby
module Sumitsubo::Where
  def self.of(path)
  end
end
```

## `store::Handle` `internal`

A handle a second language spells its own way.

```rust
mod store {
    pub struct Handle;
}
```
