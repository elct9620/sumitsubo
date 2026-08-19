require "optparse"
require "sumitsubo/version"

module Sumitsubo
  class CLI
    SPEC_DIR = ".spec"
    GLOSSARY_PATH = ".spec/glossary.json"

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

    # An empty glossary declares nothing, so verify reads it and reports
    # nothing. That is the reference line a project starts from.
    SKELETON = <<~JSON
      {
        "glossary": []
      }
    JSON

    def run(argv)
      case argv.first
      when "init" then init
      else flags(argv)
      end
    end

    private

    def init
      Dir.mkdir(SPEC_DIR) unless Dir.exist?(SPEC_DIR)
      if File.exist?(GLOSSARY_PATH)
        puts "exists #{GLOSSARY_PATH}"
      else
        File.write(GLOSSARY_PATH, SKELETON)
        puts "created #{GLOSSARY_PATH}"
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
