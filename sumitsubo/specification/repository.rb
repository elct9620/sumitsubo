require "pathname"
require "sumitsubo/finding"
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
      def initialize(parsers, languages)
        @parsers = parsers
        @languages = languages
        @directories = {}
        @files = {}
        @unread = {}
        @broken = {}
        @failed = {}
        @told = {}
        @said = {}
      end

      # Everything this mechanism's form refused, each answered at the line that
      # broke it. They are collected rather than raised, so a run answers for
      # every specification it managed to read the way a linter answers for
      # every file it managed to parse.
      def unread(mechanism)
        @unread[mechanism.specification] || []
      end

      # Whether anything of this mechanism was refused, which is where a key
      # looked for and not found may stand.
      def refused?(mechanism)
        !unread(mechanism).empty?
      end

      # Whether this mechanism can be asked anything more: one that could not
      # be read as a whole answers the first time and is passed over after.
      def broken?(mechanism)
        !@broken[mechanism.specification].nil?
      end

      # A mechanism whose specifications were refused as a whole. Only the
      # first answer is kept, since asking again reads the same documents.
      def refuse(mechanism, refusals)
        return if broken?(mechanism)

        @broken[mechanism.specification] = true
        refusals.each { |one| kept(mechanism).push(mechanism.refused(one)) }
      end

      # A mechanism nothing could be read from at all, worded by the error.
      def unreadable(mechanism, message)
        return if broken?(mechanism)

        @broken[mechanism.specification] = true
        @failed[mechanism.specification] = message
      end

      # What this mechanism could not read, added to the findings once however
      # often it is asked: whatever was refused since it was last asked, and
      # the failure the first time.
      def tell(mechanism, findings)
        name = mechanism.specification
        held = unread(mechanism)
        told = @told[name] || 0
        held[told, held.length - told].each { |one| findings.add(one) }
        @told[name] = held.length
        return if @failed[name].nil? || !@said[name].nil?

        @said[name] = true
        findings.unreadable(@failed[name])
      end

      # Every specification a directory holds. A directory nobody wrote
      # declares nothing, and a project that has said nothing is not
      # misconfigured, so that answers empty rather than failing.
      def all(directory, mechanism)
        held = @directories[directory]
        return held unless held.nil?

        path = Pathname.new(directory)
        # Two statements rather than a ternary: Spinel has no boxed form for an
        # Array of objects yet, and pairing one with an empty literal asks for it.
        found = []
        found = read_apart(files_in(path), mechanism) if path.directory?
        @directories[directory] = found
        found
      end

      # The one specification a file holds, for a mechanism keeping one.
      def one(path, mechanism)
        held = "#{path}"
        found = @files[held]
        return found unless found.nil?

        @files[held] = read_one(held, mechanism)
      end

      # Every file's blocks at once, of the kinds the asker reads. A parser is
      # asked for all of them before any is built, so it puts one question to
      # each grammar rather than two by turns — which is the difference between
      # compiling a query once and compiling it for every file.
      #
      # A mechanism asks this before building what it keeps, and whatever
      # measures a document without reading it into a form asks it alone.
      def blocks_of(paths, asking)
        paths.each { |path| Parser.of(path, @parsers) }
        answered = {}
        @parsers.each { |parser| claimed(parser, paths, asking, answered) }
        answered
      end

      private

      # The one specification a file holds. A mechanism keeping one has nothing
      # left to compare where it cannot be read, so the refusal is raised rather
      # than kept and the mechanism that asked for it answers.
      #
      # The languages go with the reading because a contract's signature is read
      # by the very reading that reads the source it describes.
      def read_one(path, mechanism)
        mechanism.read(blocks_of([path], mechanism)[path], path, @languages)
      end

      # Every specification a directory holds, each answering for itself.
      def read_apart(paths, mechanism)
        answered = blocks_of(paths, mechanism)
        found = []
        paths.each { |path| read_into(found, answered[path], path, mechanism) }
        found
      end

      # One document read into the specifications beside it, or the refusal
      # kept instead. A specification nobody could read is not the rest of them
      # to lose, so nothing is pushed and the walk carries on.
      #
      # Only a form's own refusal is kept: it says where it was refused, which
      # is what a run needs to answer it. A document no reading answers for at
      # all is raised before any of them is built.
      def read_into(found, blocks, path, mechanism)
        found.push(mechanism.read(blocks, path, @languages))
      rescue Sumitsubo::Misshapen => e
        e.refusals.each { |one| kept(mechanism).push(mechanism.refused(one)) }
      end

      def kept(mechanism)
        name = mechanism.specification
        @unread[name] = [] if @unread[name].nil?
        @unread[name]
      end

      # What one parser answers for, asked of it in one go. A file the parsers
      # before it claimed is not offered again, the way `Parser.of` answers with
      # the first that reads it.
      def claimed(parser, paths, asking, answered)
        group = paths.select { |path| answered[path].nil? && parser.reads?(path) }
        return if group.empty?

        found = parser.blocks(group, asking.kinds)
        group.each { |path| answered[path] = found[path] }
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
