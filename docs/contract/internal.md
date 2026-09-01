# Internal seams

The places this project keeps to one implementation, and means to go on keeping.

## Includes

- `sumitsubo/**/*.rb`

## `Sumitsubo::Place.file`

The one place a path a reader is handed is made.

| Attribute | Value |
| --- | --- |
| internal | yes |

```ruby
class Sumitsubo::Place
  def self.file(path)
  end
end
```

## `Sumitsubo::Place.of`

The one place a place in a file is made, for a finding to answer at.

| Attribute | Value |
| --- | --- |
| internal | yes |

```ruby
class Sumitsubo::Place
  def self.of(path, line)
  end
end
```

## `Sumitsubo::Specification::Parser.of`

The one place a file is matched to the parser that answers for it.

```ruby
module Sumitsubo::Specification::Parser
  def self.of(path, parsers)
  end
end
```

## `Sumitsubo::Specification::Parser.reads?`

The one place a run answers whether this build reads the format a file is written in.

```ruby
module Sumitsubo::Specification::Parser
  def self.reads?(path, parsers)
  end
end
```

## `Sumitsubo::Source::Language#comments_in`

The reading of what a person wrote for another person, whatever the file is written in.

| Attribute | Value |
| --- | --- |
| internal | yes |

```ruby
class Sumitsubo::Source::Language
  def comments_in(path, where)
  end
end
```

## `Sumitsubo::Source::Language#declarations_in`

The reading of what a piece of source declares, as the language a specification named.

| Attribute | Value |
| --- | --- |
| internal | yes |

```ruby
class Sumitsubo::Source::Language
  def declarations_in(path, where, language)
  end
end
```

## `Sumitsubo::Source::Language#declarations_of`

The reading of what a piece of text declares, for a shape a specification wrote rather than a file.

| Attribute | Value |
| --- | --- |
| internal | yes |

```ruby
class Sumitsubo::Source::Language
  def declarations_of(source, where, language)
  end
end
```

## `Sumitsubo::Source::Language#carries?`

The one place a run answers whether this build reads the language a specification named.

| Attribute | Value |
| --- | --- |
| internal | yes |

```ruby
class Sumitsubo::Source::Language
  def carries?(language)
  end
end
```

## `Sumitsubo::Source::Marker.claims_in`

The reading of what a piece of source claims, for an interface no construct of the language points at.

| Attribute | Value |
| --- | --- |
| internal | yes |

```ruby
module Sumitsubo::Source::Marker
  def self.claims_in(path, keywords, languages)
  end
end
```

## `Sumitsubo::Grammar.captures_in`

The one place a query is put to a grammar for what a file holds.

```ruby
module Sumitsubo::Grammar
  def self.captures_in(grammar, path, query, where)
  end
end
```

## `Sumitsubo::Grammar.captures_of`

The one place a query is put to a grammar for a piece of text no file holds.

```ruby
module Sumitsubo::Grammar
  def self.captures_of(grammar, source, query, where)
  end
end
```

## `Sumitsubo::Source::Language::Nodes.matches_in`

The one place a reading's captures are grouped by the match they came from.

| Attribute | Value |
| --- | --- |
| internal | yes |

```ruby
module Sumitsubo::Source::Language::Nodes
  def self.matches_in(captures)
  end
end
```

## `Sumitsubo::Source::Language::Nodes.nodes_in`

The one place matches become the nodes a file declares.

| Attribute | Value |
| --- | --- |
| internal | yes |

```ruby
module Sumitsubo::Source::Language::Nodes
  def self.nodes_in(matches)
  end
end
```

## `Sumitsubo::Source::Language::Nodes.enclosing`

The one place nesting is recovered from where the nodes sit.

| Attribute | Value |
| --- | --- |
| internal | yes |

```ruby
module Sumitsubo::Source::Language::Nodes
  def self.enclosing(scopes, node)
  end
end
```
