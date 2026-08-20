require "pathname"

module Sumitsubo
  # Where a run sends a reader: relative to where it started, so they can go
  # straight to it — see the Output section of CLAUDE.md.
  #
  # A path is absolute as often as not, since the root is composed from the
  # base the configuration was found at, so every message about one is built
  # from this rather than from the path itself.
  module Where
    def self.of(path)
      "#{Pathname.new(path).expand_path.relative_path_from(Pathname.pwd)}"
    end
  end
end
