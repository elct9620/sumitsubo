require "optparse"
require "sumitsubo/version"

module Sumitsubo
  class CLI
    # Written out rather than derived from the parser: Spinel's optparse is a
    # subset that drops option descriptions from `to_s`, so a generated help
    # text would differ between the compiled binary and the CRuby run that
    # produces the snapshot.
    HELP = <<~TEXT
      Usage: sumi [options]

      Options:
          -v, --version    Show version
          -h, --help       Show this help
    TEXT

    def run(argv)
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
      # Anything the parser did not consume falls back to help. CRuby arrives
      # here through the rescue above; Spinel's optparse never raises and
      # leaves the argument in `rest` instead, so both routes are needed.
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
