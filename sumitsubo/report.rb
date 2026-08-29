require "sumitsubo/finding"

module Sumitsubo
  # What a run has to say and the answer it leaves with, kept in one place
  # rather than spread across the commands. Two mechanisms can answer about the
  # same line, so the message is part of the sort key: it is what separates
  # them.
  class Report
    def initialize
      @differences = []
      @failures = []
      @unreadable = []
    end

    # A finding says which of the two it is, so nothing here decides: the rule
    # that found it is the one that knew whether a comparison was made.
    def add(finding)
      return @differences.push(finding) if finding.difference?

      @failures.push(finding)
    end

    # A mechanism nothing could be read from. It answers at no line: what was
    # absent, unreadable, or ambiguous is named in the message itself.
    def unreadable(message)
      @unreadable.push(message)
    end

    def answer
      found = @differences + @failures
      found.sort_by { |one| [one.path, one.line, one.message] }
           .each { |one| puts "#{one.path}:#{one.line} #{one.message}" }
      @unreadable.sort.each { |message| puts message }
      puts "#{@differences.length} #{@differences.length == 1 ? "difference" : "differences"}"
      return 2 unless @failures.empty? && @unreadable.empty?

      @differences.empty? ? 0 : 1
    end
  end
end
