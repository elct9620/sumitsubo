require "optparse"
require "sumitsubo/version"
require "sumitsubo/error"
require "sumitsubo/config"
require "sumitsubo/command/init"
require "sumitsubo/command/render"
require "sumitsubo/command/verify"

module Sumitsubo
  class CLI
    # Literal rather than rendered by the parser: this text has to read
    # the same under Spinel and under the CRuby run that produces the
    # snapshot.
    HELP = <<~TEXT
      Usage: sumi <command> [options]

      Commands:
          init             Lay down an empty specification to start from
          render           Render the specification to markdown
          verify           Check the source against the specification

      Options:
          -v, --version    Show version
          -h, --help       Show this help
    TEXT

    # The revision is handed in rather than read, because the stamped value
    # lives on the executable side and `spin test` never compiles bin/. The
    # default is what every tree that reached here without a stamp answers.
    def initialize(build_rev = Sumitsubo::BUILD_REV)
      @build_rev = build_rev
    end

    def run(argv)
      case argv.first
      when "init" then Command::Init.new.run(Config.load)
      when "render" then Command::Render.new.run(Config.load)
      when "verify" then Command::Verify.new.run(Config.load)
      else flags(argv)
      end
    rescue Sumitsubo::Error => e
      # What a mechanism could not read is its own to report, so what reaches
      # here is the configuration itself: with nothing to say where the
      # specifications live, no comparison was ever started.
      puts e.message
      2
    end

    private

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
        puts "#{Sumitsubo::VERSION} (#{@build_rev})"
      else
        puts HELP
      end
      0
    end
  end
end
