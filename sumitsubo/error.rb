module Sumitsubo
  # A comparison that could not be made. Every mechanism raises one of these so
  # the exit code belongs to the tool rather than to whichever mechanism failed.
  class Error < StandardError; end

  # A specification no reading could make sense of. It is raised by the reading
  # and answered by the mechanism that asked for it, which is what leaves the
  # message saying what was wrong with the document while the exception still
  # belongs to whichever mechanism could not be read.
  class Unreadable < Error; end
end
