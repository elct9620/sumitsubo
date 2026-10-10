require "sumitsubo/place"
require "sumitsubo/error"
require "sumitsubo/finding/repository"
require "sumitsubo/finding/report"
require "sumitsubo/mechanism"
require "sumitsubo/specification/repository"
require "sumitsubo/source/repository"
require "sumitsubo/relation/repository"
require "sumitsubo/relation/written"

module Sumitsubo
  module Command
    # What every command reading a specification holds while it runs, and the
    # one way it reaches the mechanisms: only those the configuration switched
    # on, each answering for itself where it cannot be read. What a command
    # does with each is its own, handed in as a block.
    class Run
      def initialize(config, languages, parsers)
        @config = config
        @findings = Finding::Repository.new
        @source = Source::Repository.new(languages)
        @specifications = Specification::Repository.new(parsers, languages)
        @relations = Relation::Repository.new
        @written = Relation::Written.new(config, @specifications, @relations, @findings, Mechanism::ALL)
      end

      def findings
        @findings
      end

      def source
        @source
      end

      def specifications
        @specifications
      end

      def relations
        @relations
      end

      # What the specifications say of one another, and what of that names
      # no statement, or more than one.
      def written
        @written
      end

      # With no root there is no reference line to read at all, which is not a
      # difference between the two sides either. Says so where it is the case.
      def rootless?
        return false if @config.root.directory?

        puts "no specification at #{Place.file(@config.root)}; sumi init lays one down"
        true
      end

      # A specification the configuration switched off is never read, so the
      # code it covers answers nothing rather than answering clean. One
      # mechanism that cannot be read leaves the others still able to answer,
      # the way a linter reports every file it managed to parse.
      #
      # A run walks the mechanisms once per stage, so one that could not be read
      # answers the first time and is passed over after.
      def each_mechanism
        Mechanism::ALL.each do |mechanism|
          next unless @config.verify?(mechanism.specification)
          next if @specifications.broken?(mechanism)

          begin
            yield mechanism
          rescue Sumitsubo::Misshapen => e
            @specifications.refuse(mechanism, e.refusals)
          rescue Sumitsubo::Error => e
            @specifications.unreadable(mechanism, e.message)
          end
          @specifications.tell(mechanism, @findings)
        end
      end

      # Every relation the switched-on mechanisms among these keep: what each
      # specification reaches first, since what the source says is read in the
      # files reached, and a vocabulary covers what the others reach. A command
      # that only looks names the ones it asks about, so a mechanism it does not
      # count is neither read nor answered for.
      def keep(mechanisms)
        each_mechanism do |mechanism|
          mechanism.reach(@config, @specifications, @relations) if mechanisms.include?(mechanism)
        end
        each_mechanism do |mechanism|
          mechanism.keep(@config, @specifications, @source, @relations) if mechanisms.include?(mechanism)
        end
      end

      # The mechanisms the configuration switched on, which are the ones whose
      # specifications are compared.
      def switched_on
        Mechanism::ALL.select { |mechanism| @config.verify?(mechanism.specification) }
      end

      # What could not be read, said where there is any. A command that only
      # counts or looks has nothing else to say about it.
      def unread?
        return false if @findings.code == 0

        Finding::Report.new(@findings).said.each { |line| puts line }
        true
      end
    end
  end
end
