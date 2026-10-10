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
    # and the statement naming it still depends on it. So a mechanism may be
    # first read here, and whatever it could not read is answered here too,
    # the once.
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
          @specifications.refuse(mechanism, e.refusals)
          nil
        rescue Sumitsubo::Error => e
          @specifications.unreadable(mechanism, e.message)
          nil
        end
      end

      # A mechanism's statements whether or not it is switched on, with
      # whatever it could not read answered as an answer names it. A command
      # may have run no stage for it, so this is not left to the stages.
      def statements_named(mechanism)
        named = statements_of(mechanism)
        @specifications.tell(mechanism, @findings)
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
        return if named.nil? || @specifications.unreadable?(target)

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
