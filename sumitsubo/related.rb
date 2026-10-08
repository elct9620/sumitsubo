require "sumitsubo/relation"

module Sumitsubo
  # What specifications say of one another: a statement names, among its
  # attributes, the statements it relates to and the ones it refines. Each is
  # kept as a relation from the statement writing it, the way a claim is kept
  # from the place in source writing it.
  module Related
    # Every relation the statements one mechanism keeps write, from each of
    # them to every key it names.
    def self.relate(mechanism, statements, names, relations)
      statements.each do |statement|
        subject = Relation::Reference.new(mechanism: mechanism, key: statement.key)
        written(statement, Relation::RELATES).each do |said|
          relations.add(Relation.relates(subject, reference(said, mechanism, names)))
        end
        written(statement, Relation::REFINES).each do |said|
          relations.add(Relation.refines(subject, reference(said, mechanism, names)))
        end
      end
    end

    def self.written(statement, kind)
      said = statement.attributes[kind]
      said.nil? ? [] : said
    end

    # A key as it was written. One opening with a mechanism's name and a space
    # is that mechanism's; any other is kept by the mechanism writing it, so a
    # scenario names another scenario by its id alone.
    def self.reference(said, own, names)
      at = said.index(" ")
      unless at.nil?
        named = said[0, at]
        return Relation::Reference.new(mechanism: named, key: said[at + 1, said.length - at - 1]) if names.include?(named)
      end
      Relation::Reference.new(mechanism: own, key: said)
    end
  end
end
