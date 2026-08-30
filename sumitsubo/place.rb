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
  # A message about a whole document answers with the file rather than with a
  # place carrying no line. An absent line would be nil, and this compiler
  # holds a member to one type across the program: the same member cannot be a
  # line here and nothing there.
  class Place < Data.define(:path, :line)
    def self.of(path, line)
      new(path: file(path), line: line)
    end

    # The file alone, for a message with no line to point at.
    def self.file(path)
      "#{Pathname.new(path).expand_path.relative_path_from(Pathname.pwd)}"
    end

    # Said to a reader. Built rather than handed back, because a member is not
    # a string this compiler will pass on as one.
    def spoken
      "#{path}:#{line}"
    end
  end
end
