require "sumitsubo/error"
require "sumitsubo/where"

module Sumitsubo
  # How a specification file is read into the shapes a mechanism judges
  # against. A mechanism puts its question to whichever reading answers for the
  # file rather than to a format, which is what keeps what a build can read in
  # one place instead of in each mechanism that wanted to read something.
  #
  # The readings a build carries arrive as an argument, the way the languages
  # do: nothing here names one, so a reading that reaches a grammar is named
  # only where a build says what it carries.
  module Reading
    # The reading answering for this file, which is the first one that says it
    # reads it. A file no reading answers for is a comparison that cannot be
    # made rather than a specification read as something it is not.
    def self.of(path, readings)
      index = 0
      while index < readings.length
        reading = readings[index]
        return reading if reading.reads?(path)

        index += 1
      end
      raise Unreadable, "#{Where.of(path)} is not a specification this sumi can read"
    end
  end
end
