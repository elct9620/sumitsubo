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

      # A finding names the check that found it after its place, the way a
      # linter names its rule, so a reader knows what answered and which word in
      # .sumi.json it answers to.
      def lines
        found = said
        found.push(counted)
        found
      end

      # Every finding and what could not be read, without the count: a run that
      # compares nothing has no differences to count.
      def said
        found = @repository.found.map { |one| "#{one.place.spoken}: #{one.check}: #{one.message}" }
        found.concat(@repository.unread)
        found
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
