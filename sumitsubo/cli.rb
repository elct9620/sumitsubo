require "optparse"
require "pathname"
require "sumitsubo/version"
require "sumitsubo/error"
require "sumitsubo/config"
require "sumitsubo/glossary"
require "sumitsubo/behavior"
require "sumitsubo/marker"

module Sumitsubo
  class CLI
    # Literal rather than rendered by the parser: this text has to read
    # the same under Spinel and under the CRuby run that produces the
    # snapshot.
    HELP = <<~TEXT
      Usage: sumi <command> [options]

      Commands:
          init             Lay down an empty specification to start from
          verify           Check the source against the specification

      Options:
          -v, --version    Show version
          -h, --help       Show this help
    TEXT

    def run(argv)
      case argv.first
      when "init" then init(Config.load)
      when "verify" then verify(Config.load)
      else flags(argv)
      end
    rescue Sumitsubo::Error => e
      # A comparison that could not be made — whatever had to be read first was
      # absent, unreadable, or ambiguous — is not a difference between the two
      # sides, so it answers differently from having found one. The three words
      # stand in for a list that grows with every mechanism.
      puts e.message
      2
    end

    private

    def init(config)
      config.root.mkpath
      lay_down(Glossary.path_in(config.root)) { |path| File.write(path, Glossary::EMPTY) }
      # A directory rather than a file, because a project keeps one behaviour
      # specification per feature. Git will not carry an empty one, which is
      # why a behaviour directory that is not there declares no scenarios
      # instead of failing the run.
      lay_down(Behavior.path_in(config.root)) { |path| Pathname.new(path).mkpath }
      0
    end

    # Laying down what is already there would overwrite a reference line, so
    # what exists is reported rather than replaced.
    def lay_down(path)
      shown = "#{Pathname.new(path).relative_path_from(Pathname.pwd)}"
      if File.exist?(path)
        puts "exists #{shown}"
      else
        yield path
        puts "created #{shown}"
      end
    end

    # Everything goes to stdout, findings and failures alike: the test
    # harness compares the two streams merged, and they are buffered
    # differently, so splitting them would leave their order unstable.
    def verify(config)
      # With no root there is no reference line at all to verify from, which
      # is not a difference between the two sides either.
      unless config.root.directory?
        puts "no specification at #{config.root.relative_path_from(Pathname.pwd)}"
        return 2
      end

      differences = []
      glossary_findings(config).each do |f|
        differences.push([f.path, f.line, "#{f.term} rejects #{f.used}: #{f.reason}"])
      end

      features = behavior_features(config)
      claims = behavior_claims(features, config)
      Behavior.uncovered(features, claims).each do |f|
        differences.push([f.path, f.line, "#{f.id} is claimed nowhere in #{f.scope.join(", ")}"])
      end

      # A claim resolving to no scenario is not a difference: there is nothing
      # on the specification side to compare it against.
      failures = []
      Behavior.unresolved(features, claims).each do |claim|
        failures.push([claim.path, claim.line, "#{claim.id} resolves to no scenario"])
      end

      report(differences + failures)
      puts "#{differences.length} #{differences.length == 1 ? "difference" : "differences"}"
      return 2 unless failures.empty?

      differences.empty? ? 0 : 1
    end

    # One stream, sorted on a key that leaves no ties. Two mechanisms can now
    # answer about the same line, and the rendered message is what separates
    # them — see the Output section of CLAUDE.md.
    def report(rows)
      rows.sort_by { |row| row }.each { |row| puts "#{row[0]}:#{row[1]} #{row[2]}" }
    end

    # A specification the configuration switched off is never read, so the code
    # it covers answers nothing rather than answering clean.
    def glossary_findings(config)
      return [] unless config.verify?("glossary")

      sections = Glossary.load(Glossary.path_in(config.root))
      Glossary.check(Glossary.scope(sections, config.base), config.base)
    end

    def behavior_features(config)
      return [] unless config.verify?("behavior")

      Behavior.load(Behavior.path_in(config.root))
    end

    # Reading source is the mechanism's other half, and it is the half that
    # needs the grammar — which is why it lives apart from the specification
    # this compares against, and why the two meet here.
    def behavior_claims(features, config)
      claims = []
      Behavior.scope(features, config.base).each do |path|
        claims.concat(Marker.claims_in(path, Behavior::MARKER))
      end
      claims
    end

    def flags(argv)
      show_version = false
      parser = OptionParser.new
      parser.on("-v", "--version") { |_| show_version = true }
      parser.on("-h", "--help") { |_| show_version = false }

      rest = argv.dup
      begin
        parser.parse!(rest)
      rescue OptionParser::ParseError
        show_version = false
      end
      # Unrecognised input means help. CRuby raises and is caught above,
      # Spinel leaves the argument in `rest`, so reaching one answer on
      # both runtimes takes both routes.
      show_version = false unless rest.empty?

      if show_version
        puts Sumitsubo::VERSION
      else
        puts HELP
      end
      0
    end
  end
end
