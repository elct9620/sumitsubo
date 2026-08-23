module Sumitsubo
  # The files a specification's `include` globs cover. Answered against the
  # base the configuration was found at, so a run from a subdirectory reaches
  # the same files.
  #
  # Shared because every mechanism narrows its search the same way and none of
  # them narrows it differently. What a found path is then called stays with
  # the caller: a glossary keys its vocabulary by the path relative to the
  # base, and a finding answers relative to where the run started.
  module Scope
    def self.of(base, patterns)
      found = []
      patterns.each do |pattern|
        base.glob(pattern).each { |path| found.push(path) }
      end
      found
    end
  end
end
