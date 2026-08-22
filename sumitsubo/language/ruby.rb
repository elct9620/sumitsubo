require "sumitsubo/error"
require "sumitsubo/grammar"
require "sumitsubo/definitions"

module Sumitsubo
  module Language
    # Ruby, read through the grammar this build links in. The queries live here
    # rather than beside the registration because they are written against one
    # grammar's node names: another language answers with its own.
    #
    # Reached through `language.rb`, which holds the seam and the shapes a
    # reading answers with, so nothing here requires its way back up.
    class Ruby
      # Comments are the part of a source file a person wrote for another
      # person, which is where a concept is called by name rather than spelled
      # as an identifier.
      COMMENTS = "(comment) @text"

      # A comment with something after it. A behavior is claimed in front of
      # the code that implements it, so a comment nothing follows claims
      # nothing. The anchor only excludes that orphan: a comment followed by
      # another comment is still a match, which is as far as this needs to
      # reach.
      ATTACHED = "((comment) @text . (_))"

      # A constant path, and a method name. A specification naming this
      # language is registering names it spells, so a name of neither shape is
      # one no definition here could carry — a shape judgement, and not a
      # reading of what the specification meant by writing it.
      CONSTANT = /\A[A-Z][A-Za-z0-9_]*(::[A-Z][A-Za-z0-9_]*)*\z/
      METHOD = /\A([A-Za-z_][A-Za-z0-9_]*[?!=]?|\[\]=?|[<>=!+\-*\/%&|^~]+)\z/

      # What a specification calls this language when it names one.
      def named?(name)
        name == Grammar::RUBY
      end

      def reads?(path)
        "#{path}".end_with?(".rb")
      end

      # Whether a definition written here could carry this name. `.` spells a
      # singleton method and `#` an instance one, so a name holding either is
      # a constant path and a method name either side of it.
      def definable?(name)
        at = name.index("#")
        at = name.index(".") if at.nil?
        return spelled?(CONSTANT, name) || spelled?(METHOD, name) if at.nil?

        spelled?(CONSTANT, "#{name[0, at]}") && spelled?(METHOD, "#{name[(at + 1)..-1]}")
      end

      # What a person wrote for another person is the comments and nothing
      # else. An identifier is a spelling of a concept rather than the
      # concept's name, so counting one would answer for every legitimate
      # class in the tree.
      def comments_in(path, where)
        found = []
        captures = TreeSitter.capture(Grammar::RUBY, path.read, COMMENTS, where)
        captures.each { |capture| found.push(Region.new(capture.line, capture.text)) }
        found
      rescue TreeSitter::ParseError => e
        # Source the grammar cannot read is not a difference between the two
        # sides either: half a file yields regions the rest of it never made.
        raise Error, e.message
      end

      # The comments with code after them. A claim sits in front of what
      # implements it, so a comment nothing follows claims nothing.
      def attached_comments_in(path, where)
        found = []
        captures = TreeSitter.capture(Grammar::RUBY, path.read, ATTACHED, where)
        captures.each { |capture| found.push(Region.new(capture.line, capture.text)) }
        found
      rescue TreeSitter::ParseError => e
        raise Error, e.message
      end

      # The names this file declares and the shape each is reached by. Only
      # Ruby answers one here, which is why the shapes stay with the reading
      # that makes them rather than moving up to the seam.
      def declarations_in(path, where)
        Definitions.names_in(path)
      end

      private

      def spelled?(pattern, text)
        !pattern.match(text).nil?
      end
    end
  end
end
