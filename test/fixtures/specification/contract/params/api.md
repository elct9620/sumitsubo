# API

## Includes

- `src/*.rb`

## `Store`

A scope says how the names under it are reached and describes no call.

```ruby
class Store
end
```

## `Store.open`

```ruby
class Store
  def self.open(path, mode = "r")
  end
end
```

## `Store#read`

```ruby
class Store
  def read(key:, &)
  end
end
```

## `Store#write`

```ruby
class Store
  def write
  end
end
```
