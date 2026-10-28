require "sumitsubo/relation"
require "sumitsubo/check/reference"

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
      end

      # What the specifications these mechanisms keep say of one another.
      def keep(mechanisms)
        names = @mechanisms.map { |one| one.specification }
        mechanisms.each do |mechanism|
          statements = @specifications.statements(mechanism, @config)
          Written.keep(mechanism.specification, statements, names, @relations) unless statements.nil?
        end
      end

      # Every relation a specification wrote that names nothing, or more than
      # one statement, answered at the statement that wrote it.
      def resolve
        [RELATES, REFINES].each do |kind|
          @relations.of(kind).each { |relation| check(relation) }
        end
      end

      private

      # One relation, answered where what it names is not one statement. Which
      # statements a key finds is the mechanism keeping them's to say. Where
      # any of a mechanism's documents was refused, what it names may stand in
      # that one, so the refusal answers for it instead.
      def check(relation)
        target = mechanism_of(relation.object.mechanism)
        named = @specifications.statements(target, @config)
        @specifications.tell(target, @findings)
        return if named.nil? || @specifications.unreadable?(target)

        writing = @specifications.statements(mechanism_of(relation.subject.mechanism), @config)
        writer = writing.find { |one| one.key == relation.subject.key }
        found = target.find(relation.object.key, writer, @config, @specifications, @relations, named)
        return if found.length == 1

        @findings.add(found.empty? ? Check::Reference.unresolved(relation, writer) : Check::Reference.ambiguous(relation, writer, found))
      end

      def mechanism_of(name)
        @mechanisms.find { |one| one.specification == name }
      end
    end
  end
end
