require "optparse"
require "pathname"
require "sumitsubo/version"
require "sumitsubo/error"
require "sumitsubo/config"
require "sumitsubo/glossary"

module Sumitsubo
  class CLI
    # Literal rather than rendered by the parser: this text has to read
    # the same under Spinel and under the CRuby run that produces the
    # snapshot.
    HELP = <<~TEXT
      Usage: sumi <command> [options]

      Commands:
          init             Write an empty .spec/glossary.json
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
      # A comparison that cannot be made — an unreadable configuration, no
      # specification, or source the grammar cannot read — is not a difference
      # between the two sides, so it answers differently from having found one.
      puts e.message
      2
    end

    private

    def init(config)
      config.root.mkpath
      path = Glossary.path_in(config.root)
      shown = "#{Pathname.new(path).relative_path_from(Pathname.pwd)}"
      if File.exist?(path)
        puts "exists #{shown}"
      else
        File.write(path, Glossary::EMPTY)
        puts "created #{shown}"
      end
      0
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

      findings = glossary_findings(config)
      findings.each do |f|
        puts "#{f.path}:#{f.line} #{f.term} rejects #{f.used}: #{f.reason}"
      end
      puts "#{findings.length} differences"
      findings.empty? ? 0 : 1
    end

    # A specification the configuration switched off is never read, so the code
    # it covers answers nothing rather than answering clean.
    def glossary_findings(config)
      return [] unless config.verify?("glossary")

      sections = Glossary.load(Glossary.path_in(config.root))
      Glossary.check(Glossary.scope(sections, config.base), config.base)
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
