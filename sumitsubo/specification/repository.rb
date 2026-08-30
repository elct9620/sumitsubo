require "pathname"
require "sumitsubo/specification"
require "sumitsubo/specification/parser"

module Sumitsubo
  class Specification
    # Every specification a run has read, and the one place any of them is read
    # from. Which format a file is written in is the parsers' to say, and what
    # to make of the file is the mechanism's, so this holds neither: it finds
    # the files, keeps what came back, and hands the reading to the two that
    # know.
    #
    # A mechanism reads its own when it runs rather than all of them up front,
    # because a specification switched off is never read and one that cannot be
    # read leaves the others still answering.
    class Repository
      def initialize(parsers, source)
        @parsers = parsers
        @source = source
        @directories = {}
        @files = {}
      end

      # Every specification a directory holds. A directory nobody wrote
      # declares nothing, and a project that has said nothing is not
      # misconfigured, so that answers empty rather than failing.
      def all(directory, mechanism)
        held = @directories[directory]
        return held unless held.nil?

        path = Pathname.new(directory)
        found = path.directory? ? files_in(path).map { |file| reading(file, mechanism) } : []
        @directories[directory] = found
        found
      end

      # The one specification a file holds, for a mechanism keeping one.
      def one(path, mechanism)
        said = "#{path}"
        held = @files[said]
        return held unless held.nil?

        @files[said] = reading(said, mechanism)
      end

      private

      # The source goes with the parser because a contract's signature is read
      # by the very reading that reads the source it describes.
      def reading(path, mechanism)
        mechanism.read(Parser.of(path, @parsers), path, @source)
      end

      # Which files are specifications is the parsers' to say rather than an
      # extension written here: a project writes one per file and this build
      # reads whichever formats it was built with. What no parser answers for
      # is passed over, so a directory is still the project's to keep other
      # things in.
      #
      # A found path is a String: it is what a specification answers with, and
      # what a finding about one of its statements points at.
      def files_in(path)
        path.glob("*").select { |file| file.file? && Parser.reads?(file, @parsers) }
            .map { |file| "#{file}" }.sort
      end
    end
  end
end
