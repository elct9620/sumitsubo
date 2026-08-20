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
    # The first line each captured value appears on. First wins because a
    # declaration is where a reader goes, and anything later is a reference to
    # it.
    def self.of(text, pattern)
      found = {}
      line = 0
      text.split("\n").each do |content|
        line += 1
        # Every match on the line, not just the first: a declaration written on
        # one line carries its own name ahead of what it declares, and stopping
        # at that one leaves the rest with nowhere to answer.
        rest = content
        match = pattern.match(rest)
        until match.nil?
          found[match[1]] = line if found[match[1]].nil?
          at = rest.index(match[0])
          rest = "#{rest[(at + match[0].length)..-1]}"
          match = pattern.match(rest)
        end
      end
      found
    end
  end
end
