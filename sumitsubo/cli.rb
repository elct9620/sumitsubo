require "optparse"
require "sumitsubo/version"
require "sumitsubo/error"
require "sumitsubo/config"
require "sumitsubo/command/help"
require "sumitsubo/command/init"
require "sumitsubo/command/verify"

module Sumitsubo
  class CLI
    # The revision, the languages and the parsers are handed in rather than
    # read, because all three are what a build says of itself and `spin test`
    # never compiles bin/. The revision defaults to what a tree that reached
    # here without a stamp answers; the other two have none, since reaching for
    # one would name a grammar or a format in every run that reads neither.
    def initialize(build_rev = Sumitsubo::BUILD_REV, languages = nil, parsers = nil)
      @build_rev = build_rev
      @languages = languages
      @parsers = parsers
    end

    def run(argv)
      case argv.first
      when "init" then Command::Init.new.run(Config.load)
      when "verify" then Command::Verify.new.run(Config.load, @languages, @parsers)
      when "help" then Command::Help.new.run(argv[1])
      else unknown?(argv.first) ? refuse(argv.first) : flags(argv)
      end
    rescue Sumitsubo::Error => e
      # What a mechanism could not read is its own to report, so what reaches
      # here is the configuration itself: with nothing to say where the
      # specifications live, no comparison was ever started.
      puts e.message
      2
    end

    private

    # A first word that is neither a command nor a flag. Only this one is named
    # back: optparse leaves it standing on both runtimes, while an unknown flag
    # is raised on one and passed through on the other, and a message a
    # snapshot has to match cannot depend on which.
    def unknown?(word)
      !word.nil? && !word.start_with?("-")
    end

    def refuse(word)
      puts "#{word} is not something sumi answers"
      puts Command::Help::USAGE
      2
    end

    def flags(argv)
      show_version = false
      understood = true
      parser = OptionParser.new
      parser.on("-v", "--version") { |_| show_version = true }
      parser.on("-h", "--help") { |_| show_version = false }

      rest = argv.dup
      begin
        parser.parse!(rest)
      rescue OptionParser::ParseError
        understood = false
      end
      # Unrecognised input means help. CRuby raises and is caught above,
      # Spinel leaves the argument in `rest`, so reaching one answer on
      # both runtimes takes both routes.
      understood = false unless rest.empty?

      if show_version && understood
        puts "#{Sumitsubo::VERSION} (#{@build_rev})"
        return 0
      end

      # Help asked for is answered; help nobody asked for stands in for what
      # the run could not make of what it was given.
      puts Command::Help::USAGE
      understood ? 0 : 2
    end
  end
end
