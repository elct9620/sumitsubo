require "pathname"
require "sumitsubo/error"
require "sumitsubo/place"
require "sumitsubo/finding"
require "sumitsubo/check"
require "sumitsubo/reach"
require "sumitsubo/source/repository"
require "sumitsubo/relation"
require "sumitsubo/feature/declared"

module Sumitsubo
  # What the Behavior mechanism keeps from the source for a feature, and reads back.
  module Feature
    # The mechanism names its own marker, as it names its own directory. A
    # later mechanism claims its own word rather than sharing this one.
    MARKER = "@behavior"

    # A feature is a Specification and its scenarios are Statements: an id is
    # the key a claim names, and the title is what the scenario says. Its steps
    # are Statements under it, each keyed by the word it is spelled with.

    # A claim as this mechanism reads it. Marker hands back what follows the
    # keyword unread, so what counts as an id is this mechanism's to say.
    class Claim < Data.define(:path, :line, :comment_line, :id)
      def key
        id
      end

      def place
        Place.new(path: path, line: line)
      end

      # A claim with no id says the marker instead: what a reader has to be
      # told is that the word was written with nothing behind it.
      def said
        id.empty? ? MARKER : id
      end
    end

    # The ids one marker line carries. A claim is data rather than prose, so a
    # trailing remark becomes an id resolving to nothing, which the run reports
    # rather than quietly accepting.
    def self.ids_in(text)
      text.split(" ")
    end

    # Every marker left in the files the features reach, kept as relations
    # under the mechanism's name: a claim where code stands below it, dangling
    # where nothing does. Marker finds the word and hands back the rest of the
    # line; splitting that into ids is this mechanism's, which is what lets
    # Contract read the same line as one name.
    def self.keep(reach, source, relations, mechanism)
      marked = source.marked(Reach.files(reach), [MARKER])
      marked.claims.each do |claim|
        referred(claim, mechanism).each { |one| relations.add(Relation.claim(claim, one)) }
      end
      marked.dangling.each do |claim|
        referred(claim, mechanism).each { |one| relations.add(Relation.dangling(claim, one)) }
      end
    end

    # The statements one marker names, one for each id.
    def self.referred(claim, mechanism)
      named_in(claim).map { |id| Relation::Reference.new(mechanism: mechanism, key: id) }
    end

    # The claims the run kept for this mechanism, read back as it compares them.
    def self.claimed_in(relations, mechanism)
      read(relations.naming(Relation::CLAIM, mechanism))
    end

    # The markers the run kept for this mechanism with no code below them.
    def self.dangling_in(relations, mechanism)
      read(relations.naming(Relation::DANGLING, mechanism))
    end

    def self.read(relations)
      found = []
      relations.each do |one|
        found.push(Claim.new(
          path: one.subject.path, line: one.subject.line, comment_line: one.subject.comment_line, id: one.object.key
        ))
      end
      found
    end

    # The ids one claim carries, or the empty one where it carries none. A
    # marker written with nothing behind it still claims: dropping it would be
    # this mechanism deciding nobody meant to write the word.
    def self.named_in(claim)
      found = ids_in(claim.text)
      found.empty? ? [""] : found
    end
  end
end
