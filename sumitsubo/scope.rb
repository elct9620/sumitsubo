require "sumitsubo/exclusion"

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
  # the files, not finding them, so a path taken out here costs nothing more.
  module Scope
    def self.of(base, patterns, exclusion)
      found = []
      patterns.each do |pattern|
        base.glob(pattern).each { |path| found.push(path) }
      end
      found.reject { |path| Exclusion.excludes?(exclusion, path.relative_path_from(base)) }
    end
  end
end
