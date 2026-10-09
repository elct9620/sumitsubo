require "sumitsubo/error"
require "sumitsubo/relation"
require "sumitsubo/check/related"

module Sumitsubo
  class Relation
    # What specifications say of one another: a statement names, among its
    # attributes, the statements it relates to and the ones it refines. Each
    # is kept as a relation from the statement writing it, the way a claim is
    # kept from the marker the source made.
    #
    # What a relation names is looked up whether or not its mechanism is
    # switched on: switching one off holds back comparing the code against it,
    # and the statement naming it still depends on it. So a switched-off
    # mechanism is first read here, and whatever it could not read is answered
    # here too, the once.
    #
    # The mechanisms arrive with the run rather than being named here, so what
    # a specification writes of another is kept without reaching every
    # mechanism there is.
    class Written
      # Every relation the statements one mechanism keeps write, from each of
      # them to every key it names.
      def self.keep(mechanism, statements, names, relations)
        statements.each do |statement|
          subject = Reference.new(mechanism: mechanism, key: statement.key)
          said(statement, RELATES).each do |one|
            relations.add(Relation.relates(subject, Reference.written(one, mechanism, names)))
          end
          said(statement, REFINES).each do |one|
            relations.add(Relation.refines(subject, Reference.written(one, mechanism, names)))
          end
        end
      end

      def self.said(statement, kind)
        held = statement.attributes[kind]
        held.nil? ? [] : held
      end

      def initialize(config, specifications, relations, findings, mechanisms)
        @config = config
        @mechanisms = mechanisms
        @specifications = specifications
        @relations = relations
        @findings = findings
        @statements = {}
        @refused = {}
        @failed = {}
        @told = {}
      end

      # What the specifications these mechanisms keep say of one another.
      def keep(mechanisms)
        names = @mechanisms.map { |one| one.specification }
        mechanisms.each do |mechanism|
          statements = statements_of(mechanism)
          Written.keep(mechanism.specification, statements, names, @relations) unless statements.nil?
        end
      end

      # Every relation a specification wrote that names nothing, or more than
      # one statement, answered at the statement that wrote it.
      def resolve
        [RELATES, REFINES].each do |kind|
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

      private

      # One relation, answered where what it names is not one statement. Which
      # statements a key finds is the mechanism keeping them's to say. Where
      # any of a mechanism's documents was refused, what it names may stand in
      # that one, so the refusal answers for it instead.
      def resolved(relation)
        target = named(relation.object.mechanism)
        named = statements_named(target)
        return if named.nil? || refused?(target)

        writing = statements_of(named(relation.subject.mechanism))
        writer = writing.find { |one| one.key == relation.subject.key }
        found = target.find(relation.object.key, writer, @config, @specifications, @relations, named)
        return if found.length == 1

        @findings.add(found.empty? ? Check::Related.unresolved(relation, writer) : Check::Related.ambiguous(relation, writer, found))
      end

      def named(name)
        @mechanisms.find { |one| one.specification == name }
      end
    end
  end
end
