module Sumitsubo
  # Which paths a run leaves alone wherever it reads source. A pattern takes
  # the form a `.gitignore` line takes, so a project writes the exclusion it
  # already knows how to write and the `.gitignore` itself reads into the
  # same rules.
  #
  # Character classes and escapes are not read: a pattern carrying a bracket
  # matches the bracket.
  module Exclusion
    # A pattern split into what it matches and what its punctuation said. A
    # separator at the start or the middle anchors the pattern to the base;
    # without one it matches a name at any depth, which is what lets `target/`
    # reach a build directory wherever it sits.
    Rule = Struct.new(:segments, :anchored, :directory, :negated)

    def self.read(patterns)
      patterns.map { |pattern| rule_from(pattern) }
    end

    # The last rule to match decides, so a `!` line written after one puts a
    # path back.
    def self.excludes?(rules, path)
      segments = "#{path}".split("/")
      matched = rules.select { |rule| covers?(rule, segments) }
      return false if matched.empty?

      !matched.last.negated
    end

    def self.rule_from(pattern)
      text = "#{pattern}"
      negated = text.start_with?("!")
      text = "#{text[1..-1]}" if negated
      directory = text.end_with?("/")
      text = "#{text[0..-2]}" if directory
      anchored = text.start_with?("/")
      text = "#{text[1..-1]}" if anchored
      segments = text.split("/")
      Rule.new(segments, anchored || segments.length > 1, directory, negated)
    end

    # A rule covers a path when it matches the path itself or a directory
    # above it: excluding a directory is excluding everything it holds, and
    # what a scope holds is files rather than the directories they sit in.
    def self.covers?(rule, segments)
      # A rule ending in a separator names a directory, which the whole path
      # never is.
      deepest = rule.directory ? segments.length - 1 : segments.length
      depth = 1
      while depth <= deepest
        return true if matches?(rule, segments[0, depth])
        depth += 1
      end
      false
    end

    def self.matches?(rule, prefix)
      return walks?(rule.segments, prefix, 0, 0) if rule.anchored

      spells?(rule.segments[0], prefix.last, 0, 0)
    end

    # Segment against segment, where `**` stands for however many of them,
    # none included.
    def self.walks?(patterns, segments, first, at)
      while first < patterns.length
        return deeper?(patterns, segments, first + 1, at) if patterns[first] == "**"
        return false if at >= segments.length
        return false unless spells?(patterns[first], segments[at], 0, 0)

        first += 1
        at += 1
      end
      at == segments.length
    end

    def self.deeper?(patterns, segments, first, at)
      while at <= segments.length
        return true if walks?(patterns, segments, first, at)

        at += 1
      end
      false
    end

    # One segment, where `*` stands for any run of characters and `?` for one.
    # Neither reaches past the segment it was written in, which is what the
    # caller splitting on the separator has already arranged.
    def self.spells?(pattern, text, first, at)
      while first < pattern.length
        if pattern[first] == "*"
          while at <= text.length
            return true if spells?(pattern, text, first + 1, at)

            at += 1
          end
          return false
        end
        return false if at >= text.length
        return false unless pattern[first] == "?" || pattern[first] == text[at]

        first += 1
        at += 1
      end
      at == text.length
    end
  end
end
