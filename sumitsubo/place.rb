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
  class Place < Data.define(:path, :line)
    def self.of(path, line)
      new(path: file(path), line: line)
    end

    # The file alone, for a message with no line to point at.
    def self.file(path)
      "#{Pathname.new(path).expand_path.relative_path_from(Pathname.pwd)}"
    end

    # Said to a reader.
    def spoken
      "#{path}:#{line}"
    end
  end
end
