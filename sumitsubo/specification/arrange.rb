# `Specification` is assigned rather than declared, so a file reopening it
# before that assignment runs loses what it added. Nothing here calls into it —
# the require is the order.
require "sumitsubo/specification"

module Sumitsubo
  class Specification
    # A statement's attributes written right above what they sit above, or last
    # in the statement where nothing is, so a reader finds every statement's
    # parts in one order. Only the table moves: prose stays where its writer
    # put it, since a sentence leaning on the one above it reads wrong moved.
    module Arrange
      # The statements whose attributes stand anywhere else.
      def self.misplaced(statements, lines)
        statements.select { |one| !one.arrangement.nil? && !one.arrangement.from.nil? && !arranged?(one.arrangement, lines) }
      end

      # The document's lines with each of the statements handed over writing
      # its table where it belongs. A table takes one blank line with it and
      # leaves one where it lands, so the document keeps its length and every
      # heading its line.
      def self.written(statements, lines)
        written = lines.dup
        statements.each { |one| moved(written, one) }
        written
      end

      # Whether only blank lines stand between the table and where it belongs.
      def self.arranged?(arrangement, lines)
        target = arrangement.above.nil? ? last_of(arrangement, lines) + 1 : arrangement.above
        return false if target <= arrangement.from

        between = lines[arrangement.to, target - 1 - arrangement.to]
        between.all? { |line| line.strip.empty? }
      end

      # The last line a statement holds that is not blank.
      def self.last_of(arrangement, lines)
        last = arrangement.ends.nil? ? lines.length : arrangement.ends
        last -= 1 while last > arrangement.to && lines[last - 1].strip.empty?
        last
      end

      # One statement's lines, its table taken out and put back where it
      # belongs, written over the lines it held.
      def self.moved(written, statement)
        arrangement = statement.arrangement
        start = statement.line
        finish = arrangement.ends.nil? ? written.length : arrangement.ends
        region = written[start - 1, finish - start + 1]
        from = arrangement.from - start
        table = region[from, arrangement.to - arrangement.from + 1]
        cut = from
        taken = table.length
        if from + taken < region.length && region[from + taken].strip.empty?
          taken += 1
        elsif from > 0 && region[from - 1].strip.empty?
          cut -= 1
          taken += 1
        end
        rest = region[0, cut] + region[cut + taken, region.length - cut - taken]
        landed = landed(rest, table, taken > table.length ? [""] : [], arrangement, start, taken)
        landed.each_with_index { |line, index| written[start - 1 + index] = line }
      end

      # The table put back into what is left: right above what it sits above,
      # or after the last line the statement holds that is not blank. The gap
      # is the blank line it took when it left.
      def self.landed(rest, table, gap, arrangement, start, taken)
        if arrangement.above.nil?
          at = rest.length
          at -= 1 while at > 0 && rest[at - 1].strip.empty?
          return rest[0, at] + gap + table + rest[at, rest.length - at]
        end

        at = arrangement.above - start
        at -= taken if arrangement.above > arrangement.to
        rest[0, at] + table + gap + rest[at, rest.length - at]
      end
    end
  end
end
