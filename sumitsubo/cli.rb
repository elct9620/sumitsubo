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

      Options:
          -v, --version    Show version
          -h, --help       Show this help
    TEXT

    def run(argv)
      case argv.first
      when "init" then init
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
