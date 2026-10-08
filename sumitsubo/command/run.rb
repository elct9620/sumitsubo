require "sumitsubo/place"
require "sumitsubo/error"
require "sumitsubo/finding/repository"
require "sumitsubo/finding/report"
require "sumitsubo/mechanism"
require "sumitsubo/specification/repository"
require "sumitsubo/source/repository"
require "sumitsubo/relation/repository"
require "sumitsubo/related"

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
        @statements = {}
        @refused = {}
        @failed = {}
        @told = {}
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

      # Every relation the switched-on mechanisms keep, for a command that asks
      # of them rather than comparing.
      def relate
        each_mechanism { |mechanism| mechanism.relate(@config, @specifications, @source, @relations) }
      end

      # The mechanisms the configuration switched on, which are the ones whose
      # specifications are compared.
      def switched_on
        Mechanism::ALL.select { |mechanism| @config.verify?(mechanism.specification) }
      end

      # What the specifications these mechanisms keep say of one another.
      def declare(mechanisms)
        names = Mechanism::ALL.map { |one| one.specification }
        mechanisms.each do |mechanism|
          statements = statements_of(mechanism)
          Related.relate(mechanism.specification, statements, names, @relations) unless statements.nil?
        end
      end

      # Every relation a specification wrote that names nothing, answered at
      # the statement that wrote it. What it names is looked up whether or not
      # its mechanism is switched on: switching one off holds back comparing
      # the code against it, and the statement naming it still depends on it.
      def resolve
        [Relation::RELATES, Relation::REFINES].each do |kind|
          @relations.of(kind).each { |relation| resolved(relation) }
        end
      end

      # Every statement this mechanism declares, or nil where its
      # specifications cannot be read. Read once, since what a relation names
      # is looked up as often as relations name it.
      def statements_of(mechanism)
        name = mechanism.specification
        return @statements[name] if @statements.key?(name)

        @statements[name] = begin
          mechanism.statements(@config, @specifications)
        rescue Sumitsubo::Misshapen => e
          @refused[name] = e.refusals.map { |one| mechanism.refused(one) }
          nil
        rescue Sumitsubo::Error => e
          @failed[name] = e.message
          nil
        end
      end

      # One relation, answered where what it names is not declared. A
      # mechanism switched off is first read here, so whatever it could not
      # read is answered here too, the once. Where any of a mechanism's
      # documents was refused, what it names may stand in that one, so the
      # refusal answers for it instead.
      def resolved(relation)
        target = Mechanism.named(relation.object.mechanism)
        named = statements_named(target)
        return if named.nil? || refused?(target)
        return if named.any? { |one| one.key == relation.object.key }

        writing = statements_of(Mechanism.named(relation.subject.mechanism))
        @findings.add(Related.unresolved(relation, writing.find { |one| one.key == relation.subject.key }))
      end

      # Whether any of this mechanism's documents was refused, which is where
      # a key looked for and not found may stand.
      def refused?(mechanism)
        prefix = "#{mechanism.specification}/"
        !@refused[mechanism.specification].nil? || @specifications.unread.any? { |one| one.check.start_with?(prefix) }
      end

      # A mechanism's statements whether or not it is switched on. Whatever a
      # switched-off one refused is answered as it is first read; a switched-on
      # one has answered for itself already.
      def statements_named(mechanism)
        name = mechanism.specification
        named = statements_of(mechanism)
        return named if @config.verify?(name) || !@told[name].nil?

        @told[name] = true
        @specifications.unread.each { |one| @findings.add(one) if one.check.start_with?("#{name}/") }
        (@refused[name] || []).each { |one| @findings.add(one) }
        @findings.unreadable(@failed[name]) unless @failed[name].nil?
        named
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
