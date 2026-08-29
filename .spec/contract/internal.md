# Internal seams

The places this project keeps to one implementation, and means to go on keeping.

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

## `Sumitsubo::Locations.of` `internal`

Where a name first appears, for a key that names one kind of thing.

```ruby
module Sumitsubo::Locations
  def self.of(text, pattern)
  end
end
```

## `Sumitsubo::Locations.all_in` `internal`

The one scan of a structured specification for where its names appear.

```ruby
module Sumitsubo::Locations
  def self.all_in(text, pattern)
  end
end
```

## `Sumitsubo::Locations::Cursor#line_of` `internal`

Taking each name in the order it was written, for a key that names more than one kind of thing.

```ruby
class Sumitsubo::Locations::Cursor
  def line_of(value)
  end
end
```

## `Sumitsubo::Parser.of`

The one place a file is matched to the parser that answers for it.

```ruby
module Sumitsubo::Parser
  def self.of(path, parsers)
  end
end
```

## `Sumitsubo::Parser.reads?`

The one place a run answers whether this build reads the format a file is written in.

```ruby
module Sumitsubo::Parser
  def self.reads?(path, parsers)
  end
end
```

## `Sumitsubo::Language.comments_in` `internal`

The reading of what a person wrote for another person, whatever the file is written in.

```ruby
module Sumitsubo::Language
  def self.comments_in(path, where)
  end
end
```

## `Sumitsubo::Language.attached_comments_in` `internal`

The reading of where a claim could sit, for a file whose language has code for a comment to sit in front of.

```ruby
module Sumitsubo::Language
  def self.attached_comments_in(path, where)
  end
end
```

## `Sumitsubo::Language.declarations_in` `internal`

The reading of what a piece of source declares, as the language a specification named.

```ruby
module Sumitsubo::Language
  def self.declarations_in(path, where, language)
  end
end
```

## `Sumitsubo::Language.declarations_of` `internal`

The reading of what a piece of text declares, for a shape a specification wrote rather than a file.

```ruby
module Sumitsubo::Language
  def self.declarations_of(source, where, language)
  end
end
```

## `Sumitsubo::Language.carries?` `internal`

The one place a run answers whether this build reads the language a specification named.

```ruby
module Sumitsubo::Language
  def self.carries?(language)
  end
end
```

## `Sumitsubo::Language.definable?` `internal`

The one place a name is judged against how a language spells what it defines.

```ruby
module Sumitsubo::Language
  def self.definable?(language, name)
  end
end
```

## `Sumitsubo::Marker.claims_in` `internal`

The reading of what a piece of source claims, for an interface no construct of the language points at.

```ruby
module Sumitsubo::Marker
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

## `Sumitsubo::Definitions.matches_in` `internal`

The one place a reading's captures are grouped by the match they came from.

```ruby
module Sumitsubo::Definitions
  def self.matches_in(captures)
  end
end
```

## `Sumitsubo::Definitions.nodes_in` `internal`

The one place matches become the nodes a file declares.

```ruby
module Sumitsubo::Definitions
  def self.nodes_in(matches)
  end
end
```

## `Sumitsubo::Definitions.enclosing` `internal`

The one place nesting is recovered from where the nodes sit.

```ruby
module Sumitsubo::Definitions
  def self.enclosing(scopes, node)
  end
end
```
