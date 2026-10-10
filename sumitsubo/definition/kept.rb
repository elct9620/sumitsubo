require "sumitsubo/check"
require "sumitsubo/place"
require "sumitsubo/reach"
require "sumitsubo/relation"
require "sumitsubo/source"
require "sumitsubo/definition/declared"

module Sumitsubo
  # What the Contract mechanism keeps from the source for a definition, and reads back.
  module Definition
    # Every file to read and the language to read it as. A definition
    # registering contracts in two languages reaches files of both, and each is
    # read as the one that claims it — a file no reading claims for a language
    # holds no name spelled that way, and reading it as that language is a
    # parse that fails rather than an answer.
    Reading = Data.define(:path, :language)

    def self.readings_in(definitions, reach, source)
      found = []
      asked = {}
      defined(definitions).each do |definition|
        paths = reached(reach, definition)
        languages_of(definition).each do |language|
          spelled(source, unasked(asked, paths, language), language).each { |one| found.push(one) }
        end
      end
      found
    end

    # The files among these not yet asked about in this language. Two
    # definitions reaching one file ask it the same question, so it is read
    # once for each language rather than once for each definition.
    def self.unasked(asked, paths, language)
      found = []
      paths.each do |path|
        key = "#{language} #{path}"
        next unless asked[key].nil?

        asked[key] = true
        found.push(path)
      end
      found
    end

    # The files one definition reached, in a fixed order.
    def self.reached(reach, definition)
      reach[definition.path].keys.sort
    end

    # The files among these that could carry a name spelled as this language
    # spells it. Which files a definition reaches is its include's to say, and
    # which of them a language could have written is the file's own.
    def self.spelled(source, paths, language)
      found = []
      paths.each do |path|
        found.push(Reading.new(path, language)) if source.spelled_in?(path, language)
      end
      found
    end

    # The definitions whose interfaces source claims in a comment, and the ones
    # read from the syntax tree. Each reading searches only its own files: a
    # marker nobody wrote is not worth parsing for, and a definition nobody
    # claims is not worth reading comments for.
    # Every word every definition claims, and every one it leaves dangling.
    def self.marked_in(definitions, reach, source)
      source.marked(Reach.files(reach), keywords(definitions))
    end

    # Every claim and dangling marker in the files the claimed definitions
    # reach, and every declaration in the files the others reach, kept under
    # this mechanism's name. A contract is named by the interface itself, so
    # the whole of what follows the marker is the key a claim names.
    def self.keep(definitions, source, relations, mechanism)
      marked = marked_in(definitions, Reach.of(claimed(definitions), relations), source)
      marked.claims.each { |one| relations.add(Relation.claim(one, Relation::Reference.new(mechanism: mechanism, key: one.text))) }
      marked.dangling.each { |one| relations.add(Relation.dangling(one, Relation::Reference.new(mechanism: mechanism, key: one.text))) }
      declared = defined_in(definitions, Reach.of(defined(definitions), relations), source)
      declared.keys.each do |language|
        declared[language].each do |one|
          spelled = Source::Spelled.new(declaration: one, language: language)
          relations.add(Relation.declares(spelled, Relation::Reference.new(mechanism: mechanism, key: one.name)))
        end
      end
    end

    # The claims of one kind the run kept, read as the checks compare them:
    # under the marker the claim was written with, as the interface it names.
    def self.read(relations)
      found = []
      relations.each do |one|
        name = Name.new(one.subject.keyword, one.subject.text)
        found.push(Check::Made.new(key: name, place: Place.new(path: one.subject.path, line: one.subject.line), said: name.spoken))
      end
      found
    end

    # What the run kept as declared, held again under the language that read
    # each, in the order it was read.
    def self.declared_from(relations)
      found = {}
      relations.each do |one|
        holding = found[one.subject.language]
        if holding.nil?
          holding = []
          found[one.subject.language] = holding
        end
        holding.push(one.subject.declaration)
      end
      found
    end

    # What the source in scope defines, held under the language it was read as.
    # A definition registering contracts in two languages has its files read
    # once per language, and one file read twice answers twice: which reading
    # each came back from is what tells the two apart, so it is the answers
    # that are held apart rather than each answer that says which.
    def self.defined_in(definitions, reach, source)
      found = {}
      readings_in(definitions, reach, source).each do |reading|
        holding = found[reading.language]
        if holding.nil?
          holding = []
          found[reading.language] = holding
        end
        source.declarations(reading.path, reading.language).each { |name| holding.push(name) }
      end
      found
    end
  end
end
