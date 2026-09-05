module Sumitsubo
  # A comparison that could not be made. Every mechanism raises one of these so
  # the exit code belongs to the tool rather than to whichever mechanism failed.
  class Error < StandardError; end

  # A specification no reading could make sense of: nothing reads the format it
  # is written in, or it is not there to read at all. What has no line to point
  # at answers for the file, so this carries no place.
  class Unreadable < Error; end

  # One way a document is out of shape: what is wrong with it, and the line
  # that broke. The place is what lets a run answer it beside every other
  # finding, in the order a reader walks the file rather than after everything
  # else.
  Refusal = Struct.new(:place, :message)

  # A document its own form refused, in every way it is out of shape rather
  # than the first. A refusal stops the block it was made about and the blocks
  # after it are still read, so a reader is handed the whole of what to fix and
  # makes one pass at it.
  class Misshapen < Unreadable
    attr_reader :refusals

    def initialize(refusals)
      super(refusals[0].message)
      @refusals = refusals
    end
  end
end
