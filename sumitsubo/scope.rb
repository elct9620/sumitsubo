require "pathname"
require "sumitsubo/exclusion"
require "sumitsubo/locations"
require "sumitsubo/where"

module Sumitsubo
  # The files a specification's `include` globs cover, less what the project
  # excludes. Answered against the base the configuration was found at, so a
  # run from a subdirectory reaches the same files.
  #
  # Shared because every mechanism narrows its search the same way and none of
  # them narrows it differently. What a found path is then called stays with
  # the caller: a glossary keys its vocabulary by the path relative to the
  # base, and a finding answers relative to where the run started.
  #
  # Excluding is filtering rather than pruning: what a scan costs is reading
  # the files, not finding them, so a path taken out here costs nothing more —
  # and neither does asking a second time which patterns reached anything.
  module Scope
    # Every quoted value in a structured specification, so an include can be
    # looked up by what it says. First wins, as it does for every other
    # reading: a glob is distinctive enough that the line carrying it is the
    # line that wrote it.
    SPELLED = /"([^"]*)"/

    # An include covering no file, and the line of the specification that
    # wrote it.
    Barren = Struct.new(:path, :pattern, :line)

    def self.of(base, patterns, exclusion)
      found = []
      patterns.each do |pattern|
        base.glob(pattern).each { |path| found.push(path) }
      end
      found.reject { |path| Exclusion.excludes?(exclusion, path.relative_path_from(base)) }
    end

    # Judged before anything is excluded: a pattern nothing matches is one
    # nobody can have meant, while one whose files the project excludes is the
    # project getting what it asked for.
    def self.barren(base, patterns, path)
      lines = Locations.of(Pathname.new(path).read, SPELLED)
      where = Where.of(path)
      found = []
      patterns.each do |pattern|
        found.push(Barren.new(where, pattern, lines[pattern])) if base.glob(pattern).empty?
      end
      found
    end

    # Nothing was read where the specification says something should have
    # been, and a run that says nothing about it reads exactly like agreement.
    def self.describe(barren)
      "include #{barren.pattern} covers no file; " \
      "the pattern is wrong or what it pointed at is gone"
    end
  end
end
