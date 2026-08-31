# Internal seams

The places this project keeps to one implementation.

## Includes

- `sumitsubo/**/*.rb`

## `Sumitsubo::Where.of`

The one place a path a reader is handed is made.

| Attribute | Value |
| --- | --- |
| internal | yes |

```ruby
module Sumitsubo::Where
  def self.of(path)
  end
end
```

## `store::Handle`

A handle a second language spells its own way.

| Attribute | Value |
| --- | --- |
| internal | yes |

```rust
mod store {
    pub struct Handle;
}
```
