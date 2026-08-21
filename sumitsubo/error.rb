module Sumitsubo
  # A comparison that could not be made. Every mechanism raises one of these so
  # the exit code belongs to the tool rather than to whichever mechanism failed.
  class Error < StandardError; end
end
