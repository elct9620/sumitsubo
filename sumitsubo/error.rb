module Sumitsubo
  # A comparison that could not be made. Every mechanism raises one of these so
  # the exit code belongs to the tool rather than to whichever mechanism failed
  # — see the Output section of CLAUDE.md for what that answer means.
  class Error < StandardError; end
end
