module Sumitsubo
  # Where a name sits in the raw text of a structured specification. JSON
  # carries no line numbers, and a finding about something the specification
  # declares has to answer somewhere a reader can go and look — the line that
  # declares it.
  #
  # Shared because every mechanism reading a structured specification needs it
  # and none of them needs it differently: the pattern says which key to follow
  # and the rest is the same reading. Nothing here reaches the grammar, so a
  # mechanism using it keeps a snapshot that can be regenerated.
  module Locations
    # One appearance of a captured value, and the line it was on.
    At = Struct.new(:text, :line)

    # Every appearance, in the order the file wrote them. A specification using
    # one key at more than one depth — a contract's name, and its parameters' —
    # puts several values in one namespace, so a caller that knows the order it
    # wrote them in walks this and takes each in turn.
    def self.all_in(text, pattern)
      found = []
      line = 0
      text.split("\n").each do |content|
        line += 1
        # Every match on the line, not just the first: a declaration written on
        # one line carries its own name ahead of what it declares, and stopping
        # at that one leaves the rest with nowhere to answer.
        rest = content
        match = pattern.match(rest)
        until match.nil?
          found.push(At.new(match[1], line))
          past = rest.index(match[0])
          rest = "#{rest[(past + match[0].length)..-1]}"
          match = pattern.match(rest)
        end
      end
      found
    end

    # The first line each captured value appears on. First wins because a
    # declaration is where a reader goes, and anything later is a reference to
    # it — which holds only where the key names one kind of thing.
    def self.of(text, pattern)
      found = {}
      all_in(text, pattern).each do |at|
        found[at.text] = at.line if found[at.text].nil?
      end
      found
    end

    # Reads the appearances in the order they were written, taking each value
    # from the ones not yet passed. The next appearance is the one wanted in a
    # well-formed specification; searching on from there is what keeps a stray
    # appearance from shifting every line after it.
    class Cursor
      def initialize(found)
        @found = found
        @at = 0
      end

      # The line this value sits on, or none where nothing ahead carries it.
      # A value the specification never spelled — a parameter the language let
      # go unnamed — passes nothing and moves nowhere.
      def line_of(value)
        return nil if value.nil?

        index = @at
        while index < @found.length
          if @found[index].text == value
            @at = index + 1
            return @found[index].line
          end

          index += 1
        end
        nil
      end
    end
  end
end
