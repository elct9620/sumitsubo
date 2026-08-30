require "sumitsubo/finding"

module Sumitsubo
  class Finding
    # Everything a run found, and the answer it leaves with. Two mechanisms can
    # answer about the same line, so the message is part of the order: it is
    # what separates them.
    class Repository
      def initialize
        @differences = []
        @failures = []
        @unread = []
      end

      # A finding says which of the two it is, so nothing here decides: the
      # check that found it is the one that knew whether a comparison was made.
      def add(finding)
        return @differences.push(finding) if finding.difference?

        @failures.push(finding)
      end

      # A mechanism nothing could be read from. It answers at no place: what was
      # absent, unreadable, or ambiguous is named in the message itself.
      def unreadable(message)
        @unread.push(message)
      end

      # Every finding in the order a run answers them, differences and failures
      # alike: which of the two a finding is decides the exit code and not where
      # it is printed.
      def found
        (@differences + @failures).sort_by { |one| [one.place.path, one.place.line, one.message] }
      end

      def unread
        @unread.sort
      end

      def differences
        @differences
      end

      def code
        return 2 unless @failures.empty? && @unread.empty?

        @differences.empty? ? 0 : 1
      end
    end
  end
end
