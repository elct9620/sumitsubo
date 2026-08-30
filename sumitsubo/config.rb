require "json"
require "pathname"
require "sumitsubo/error"
require "sumitsubo/source/patterns"
require "sumitsubo/place"

module Sumitsubo
  # What the project says about where its specifications live and which of them
  # a run verifies. A project that has said nothing is not misconfigured, so an
  # absent file answers the defaults rather than failing.
  #
  # Nothing here names a mechanism, which is what keeps this file's test on the
  # side that --regen can still write a snapshot for.
  class Config
    FILE = ".sumi.json"
    GITIGNORE = ".gitignore"
    DEFAULT_ROOT = ".spec"

    attr_reader :base, :root, :exclusion

    # The directory a run is configured from: the nearest one at or above the
    # starting point holding a .sumi.json, else the repository it sits in, else
    # where it started. What the file says is read against wherever it was
    # found, which is the convention tsc and RuboCop both follow.
    def self.discover(from = Pathname.pwd)
      start = Pathname.new(from).expand_path
      # A .git is a directory in a plain clone and a file in a worktree or a
      # submodule, so only its presence is asked about.
      nearest(start, FILE) || nearest(start, ".git") || start
    end

    # The closest directory at or above +start+ that holds +name+.
    def self.nearest(start, name)
      start.ascend.find { |directory| (directory / name).exist? }
    end

    def self.load(base = discover)
      directory = Pathname.new(base)
      path = directory / FILE
      new(directory, path.exist? ? read(path) : {})
    end

    def self.read(path)
      JSON.parse(path.read)
    rescue JSON::ParserError
      # The parser's own wording is Spinel's rather than CRuby's, so it stays
      # out of a message a snapshot has to match on both. The path is answered
      # the way a finding is, relative to where the run started.
      raise Error, "#{Place.file(path)} is not readable JSON"
    end

    def initialize(base, document)
      @base = base
      @root = (base / (document["root"] || DEFAULT_ROOT)).cleanpath
      # What every mechanism leaves alone. A build directory belongs to the
      # project rather than to any one specification, so it is said once here
      # instead of beside each `include`.
      #
      # A project keeping a .gitignore has already said which paths are not
      # its source, and being made to say it twice is the drift this tool
      # exists to catch. What .sumi.json says is read after it, so a `!` line
      # there puts back a path git leaves out.
      patterns = []
      patterns.concat(gitignored_in(base)) unless document["gitignore"] == false
      patterns.concat(document["exclude"] || [])
      @exclusion = Source::Patterns.read(patterns)
      @specifications = document["specifications"] || {}
    end

    # Only the exceptions are listed, so a specification nobody mentioned is
    # verified once its file is there. `verify: false` keeps a specification
    # the project means to hold without a run being checked against it yet.
    def verify?(name)
      entry = @specifications[name]
      entry.nil? || entry["verify"] != false
    end

    private

    # Only the one beside the .sumi.json, whose rules are written against the
    # same directory this run reads everything else against. What git reads
    # besides — the ones deeper in the tree, the user's own, and the rule that
    # a tracked file is never left out — this does not.
    def gitignored_in(base)
      path = base / GITIGNORE
      path.exist? ? Source::Patterns.patterns_in(path.read) : []
    end
  end
end
