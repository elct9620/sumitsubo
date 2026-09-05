module Sumitsubo
  # A comparison that could not be made. Every mechanism raises one of these so
  # the exit code belongs to the tool rather than to whichever mechanism failed.
  class Error < StandardError; end

  # A specification no reading could make sense of: nothing reads the format it
  # is written in, or it is not there to read at all. What has no line to point
  # at answers for the file, so this carries no place.
  class Unreadable < Error; end

  # A document its own form refused, at the line that broke it. The place is
  # what lets a run answer it beside every other finding, in the order a reader
  # walks the file rather than after everything else.
  class Misshapen < Unreadable
    attr_reader :place

    def initialize(message, place)
      super(message)
      @place = place
    end
  end
end
