module Sumitsubo
  module Source
    # Which paths a run reads and which it leaves alone. A pattern takes the
    # form a `.gitignore` line takes, so a project writes the exclusion it
    # already knows how to write and the `.gitignore` itself reads into the
    # same rules.
    #
    # The two sides read one rule differently, and they sit together so that
    # difference is readable: an exclusion reaches a name at any depth, an
    # include is anchored to the base.
    #
    # Character classes and escapes are not read: a pattern carrying a bracket
    # matches the bracket.
    module Patterns
      # A pattern split into what it matches and what its punctuation said.
      # Everything but the segments is the exclusion reading's: a separator at
      # the start or the middle anchors the pattern, and without one it reaches a
      # name at any depth, which is what lets `target/` reach a build directory
      # wherever it sits. An include is anchored whatever the punctuation says.
      Rule = Struct.new(:segments, :anchored, :directory, :negated)

      def self.read(patterns)
        patterns.map { |pattern| rule_from(pattern) }
      end

      # The patterns a `.gitignore` holds, less what it wrote for a reader. A
      # rule there is written against the directory the file sits in, which is
      # the base a run reads everything else against.
      def self.patterns_in(text)
        text.split("\n").map { |line| line.strip }.reject { |line| line.empty? || line.start_with?("#") }
      end

      # The last rule to match decides, so a `!` line written after one puts a
      # path back.
      def self.excludes?(rules, path)
        decided(rules, "#{path}".split("/"), false)
      end

      # The same question about a directory, which a rule naming one answers
      # differently: `target/` is the directory itself here, where against a
      # file it can only be one the file sits under. Asked while walking, so a
      # directory left out is never looked inside.
      def self.excludes_directory?(rules, path)
        decided(rules, "#{path}".split("/"), true)
      end

      def self.decided(rules, segments, directory)
        matched = rules.select { |rule| covers?(rule, segments, directory) }
        return false if matched.empty?

        !matched.last.negated
      end

      # Whether an include reaches this path. An include is anchored to the base
      # and names files, so the whole path has to match and a rule with no
      # separator reaches the base and no deeper — where the same rule read as an
      # exclusion reaches a name at any depth. The two sides differ here because
      # a .gitignore and a glob differ here, and both are what they say they are.
      #
      # What a rule says about directories, and about putting a path back, is
      # exclusion's and says nothing on this side.
      def self.selects?(rule, path)
        walks?(rule.segments, "#{path}".split("/"), 0, 0)
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
      def self.covers?(rule, segments, directory)
        # A rule ending in a separator names a directory, which a file never is.
        deepest = rule.directory && !directory ? segments.length - 1 : segments.length
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
            # The run a star stands for may be empty, so every tail from here on
            # is tried — the one past the last character included, which is what
            # lets a star at the end of a pattern match nothing at all.
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
end
