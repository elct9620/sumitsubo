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

    # The two sides disagree, and the disagreement is about the code.
    def difference(path, line, message)
      @differences.push([path, line, message])
    end

    # The comparison could not be made — whatever had to be read first was
    # absent, unreadable, or ambiguous.
    def failure(path, line, message)
      @failures.push([path, line, message])
    end

    # A mechanism nothing could be read from. It answers at no line: what was
    # absent, unreadable, or ambiguous is named in the message itself.
    def unreadable(message)
      @unreadable.push(message)
    end

    def answer
      rows = @differences + @failures
      rows.sort_by { |row| row }.each { |row| puts "#{row[0]}:#{row[1]} #{row[2]}" }
      @unreadable.sort.each { |message| puts message }
      puts "#{@differences.length} #{@differences.length == 1 ? "difference" : "differences"}"
      return 2 unless @failures.empty? && @unreadable.empty?

      @differences.empty? ? 0 : 1
    end
  end
end
