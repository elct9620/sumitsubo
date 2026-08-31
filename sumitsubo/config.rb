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
  # Nothing here names a mechanism: this is what a run is handed rather than a
  # stage that decides anything, so a name it switches by arrives from the
  # caller that knows one.
  class Config
    FILE = ".sumi.json"
    GITIGNORE = ".gitignore"
    DEFAULT_ROOT = ".spec"

    # What a configuration says, and what each of them takes. Held in order
    # rather than by name because it is also the order a refusal answers in,
    # and one configuration read twice should answer alike however its keys
    # were written down.
    KEYS = [["root", "a path"],
            ["exclude", "a list of paths"],
            ["gitignore", "true or false"],
            ["specifications", "the specifications to switch"]]

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
      refuse(faults_in(base, document))
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

    # Everything wrong with a configuration, answered at once. The file is
    # small and a person who mistyped three keys should not find them one run
    # at a time, which is what a walk that stops at the first would make them
    # do.
    #
    # What the file reads comes first, in the order it reads them, and what it
    # cannot place follows sorted: a document's own order decides neither, so
    # one configuration answers alike however it was written down.
    def faults_in(base, document)
      where = Place.file(base / FILE)
      said = []
      KEYS.each do |key|
        written = document[key[0]]
        next if written.nil? || takes?(key[0], written)

        said.push("#{where} writes #{key[0]} as #{JSON.generate(written)}, where it takes #{key[1]}")
      end
      said.concat(unread(where, document))
    end

    # A key nothing here reads. The set is closed because reading is what makes
    # a setting honoured: one nobody reads is a project asking for something
    # and being answered as though it had asked for nothing.
    def unread(where, document)
      known = KEYS.map { |key| key[0] }
      document.keys.select { |key| !known.include?(key) }.sort
              .map { |key| "#{where} writes #{key}, which is not something a configuration says" }
    end

    # Whether one key was given what it takes. A value of another shape is not
    # read as something else: `"gitignore": "no"` means what it says, and
    # reading it as true is the tool deciding what a project meant.
    def takes?(key, written)
      case key
      when "root" then written.is_a?(String)
      when "exclude" then written.is_a?(Array) && written.all? { |one| one.is_a?(String) }
      when "gitignore" then written == true || written == false
      when "specifications" then written.is_a?(Hash)
      end
    end

    # A configuration nothing could be read from stops the run, the way one
    # that will not parse does: with a setting nobody honours, what a run
    # touches is not what the project asked for.
    def refuse(said)
      raise Error, said.join("\n") unless said.empty?
    end

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
