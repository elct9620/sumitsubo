require "optparse"
require "sumitsubo/version"
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
      when "init" then init
      when "verify" then verify
      else flags(argv)
      end
    end

    private

    def init
      Dir.mkdir(Glossary::DIR) unless Dir.exist?(Glossary::DIR)
      if File.exist?(Glossary::PATH)
        puts "exists #{Glossary::PATH}"
      else
        File.write(Glossary::PATH, Glossary::EMPTY)
        puts "created #{Glossary::PATH}"
      end
      0
    end

    # Everything goes to stdout, findings and failures alike: the test
    # harness compares the two streams merged, and they are buffered
    # differently, so splitting them would leave their order unstable.
    def verify
      findings = Glossary.check(Glossary.scope(Glossary.load))
      findings.each do |f|
        puts "#{f.path}:#{f.line}:#{f.column} #{f.term} rejects #{f.used}: #{f.reason}"
      end
      puts "#{findings.length} differences"
      findings.empty? ? 0 : 1
    rescue Glossary::Error => e
      # A specification that cannot be read is not a difference between the
      # two sides, so it answers differently from having found one.
      puts e.message
      2
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
