require "sumitsubo/finding/repository"

module Sumitsubo
  class Finding
    # What a run says, in the words it says it in. The lines are answered rather
    # than written, because where they go is the command's to decide and the
    # test harness compares one stream.
    class Report
      def initialize(repository)
        @repository = repository
      end

      def lines
        said = @repository.found.map { |one| "#{one.place.spoken} #{one.message}" }
        said.concat(@repository.unread)
        said.push(counted)
        said
      end

      private

      # A run always says how many, so a clean one says so rather than saying
      # nothing at all.
      def counted
        many = @repository.differences.length
        "#{many} #{many == 1 ? "difference" : "differences"}"
      end
    end
  end
end
