require "sumitsubo/place"
require "sumitsubo/error"
require "sumitsubo/finding/repository"
require "sumitsubo/mechanism"
require "sumitsubo/specification/repository"
require "sumitsubo/source/repository"
require "sumitsubo/relation/repository"

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
        @specifications = Specification::Repository.new(parsers, @source)
        @relations = Relation::Repository.new
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
      def each_mechanism
        Mechanism::ALL.each do |mechanism|
          next unless @config.verify?(mechanism.specification)

          begin
            yield mechanism
          rescue Sumitsubo::Misshapen => e
            e.refusals.each { |one| @findings.add(mechanism.refused(one)) }
          rescue Sumitsubo::Error => e
            @findings.unreadable(e.message)
          end
        end
        # A document read beside others never reached the mechanism that asked
        # for it, so its refusal is answered here rather than there.
        @specifications.unread.each { |one| @findings.add(one) }
      end
    end
  end
end
