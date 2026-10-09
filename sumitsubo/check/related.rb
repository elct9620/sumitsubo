require "sumitsubo/finding"
require "sumitsubo/place"

module Sumitsubo
  module Check
    # What a statement's relates and refines name, against what the
    # specifications declare. Both are answered at the statement writing the
    # relation, under the word of the mechanism keeping it, and both are a
    # comparison that could not be made rather than a difference: nothing on
    # the other side says which statement was meant.
    module Related
      UNRESOLVED = "unresolved"
      AMBIGUOUS = "ambiguous"

      # A relation naming a statement nobody declares.
      def self.unresolved(relation, writer)
        Finding.new(
          check: "#{relation.subject.mechanism}/#{UNRESOLVED}", difference: false,
          place: Place.of(writer.path, writer.line),
          message: "#{written(relation)}, which no #{relation.object.mechanism} specification declares"
        )
      end

      # A relation naming a key more than one statement answers to.
      def self.ambiguous(relation, writer, found)
        places = found.map { |one| Place.of(one.path, one.line).spoken }
        Finding.new(
          check: "#{relation.subject.mechanism}/#{AMBIGUOUS}", difference: false,
          place: Place.of(writer.path, writer.line),
          message: "#{written(relation)}, which #{relation.object.mechanism} declares at #{places.join(" and ")}"
        )
      end

      def self.written(relation)
        "#{relation.subject.key} #{relation.kind} #{relation.object.mechanism} #{relation.object.key}"
      end
    end
  end
end
