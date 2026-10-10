require "pathname"

module Sumitsubo
  # Where a run sends a reader: the file, and the line in it a finding answers
  # at. Answered relative to where the run started, so a reader can go straight
  # there.
  #
  # A path is absolute as often as not, since the root is composed from the
  # base the configuration was found at, which is why this file is the one
  # place a path a reader is handed is made — `of` for a place in a file,
  # `file` for the file alone, and `new` where the path is rendered already.
  #
  # A place always carries a line, so a message about a whole document asks for
  # the file rather than for a place standing in for one: what has no line to
  # point at is a path, not a place.
  #
  # Where the run started arrives from the run rather than being asked of the
  # system, which on macOS opens and closes a directory each time it is asked.
  class Place < Data.define(:path, :line)
    def self.of(path, line, from)
      new(path: file(path, from), line: line)
    end

    # The file alone, for a message with no line to point at.
    def self.file(path, from)
      "#{(from / path).cleanpath.relative_path_from(from)}"
    end

    # Said to a reader.
    def spoken
      "#{path}:#{line}"
    end
  end
end
