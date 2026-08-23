require "pathname"
require "sumitsubo/locations"
require "sumitsubo/patterns"
require "sumitsubo/where"

module Sumitsubo
  # The files a specification's `include` covers, less what the project
  # excludes. Answered against the base the configuration was found at, so a
  # run from a subdirectory reaches the same files.
  #
  # Shared because every mechanism narrows its search the same way and none of
  # them narrows it differently. A found path is a String relative to the
  # base: that is the coordinate an include and an exclusion are both written
  # in, and a caller renders or composes from it.
  #
  # The walk is this tool's rather than the glob's. Two things it needs the
  # glob cannot give: a `*` that matches a directory in the middle of a path,
  # which a workspace is written with, and one traversal answering every
  # pattern rather than one traversal each.
  module Scope
    # Every quoted value in a structured specification, so an include can be
    # looked up by what it says. First wins, as it does for every other
    # reading: a glob is distinctive enough that the line carrying it is the
    # line that wrote it.
    SPELLED = /"([^"]*)"/

    # An include covering no file, and the line of the specification that
    # wrote it.
    Barren = Struct.new(:path, :pattern, :line)

    def self.of(base, patterns, exclusion)
      candidates = candidates_in(base, patterns)
      found = []
      patterns.each do |pattern|
        selected(pattern, candidates).each { |path| found.push(path) }
      end
      found.reject { |path| Patterns.excludes?(exclusion, path) }
    end

    # Judged before anything is excluded: a pattern nothing matches is one
    # nobody can have meant, while one whose files the project excludes is the
    # project getting what it asked for.
    def self.barren(base, patterns, path)
      lines = Locations.of(Pathname.new(path).read, SPELLED)
      where = Where.of(path)
      candidates = candidates_in(base, patterns)
      found = []
      patterns.each do |pattern|
        found.push(Barren.new(where, pattern, lines[pattern])) if selected(pattern, candidates).empty?
      end
      found
    end

    # Nothing was read where the specification says something should have
    # been, and a run that says nothing about it reads exactly like agreement.
    def self.describe(barren)
      "include #{barren.pattern} covers no file; " \
      "the pattern is wrong or what it pointed at is gone"
    end

    # Every file these patterns could reach. A pattern with no wildcard names
    # one file and is answered by asking whether it is there; the rest are
    # answered by walking, and only from the directory each names before its
    # first wildcard.
    def self.candidates_in(base, patterns)
      found = []
      patterns.each do |pattern|
        found.push(pattern) if literal?(pattern) && (base / pattern).file?
      end
      roots_in(patterns).each do |root|
        under(base, root).each { |path| found.push(path) }
      end
      found.uniq
    end

    def self.selected(pattern, candidates)
      rule = Patterns.read([pattern])[0]
      candidates.select { |path| Patterns.selects?(rule, path) }
    end

    def self.literal?(pattern)
      !pattern.include?("*") && !pattern.include?("?")
    end

    # The outermost directories the walk has to start from. One root under
    # another is reached by walking that one, so only the outermost are kept
    # and a file is met once however many patterns reach it.
    def self.roots_in(patterns)
      named = []
      patterns.each { |pattern| named.push(root_of(pattern)) unless literal?(pattern) }
      outermost(named.uniq.sort)
    end

    # Everything before the first segment carrying a wildcard: the deepest
    # directory a match could sit under. A pattern beginning with one names
    # the base itself.
    def self.root_of(pattern)
      segments = pattern.split("/")
      taken = []
      index = 0
      while index < segments.length
        break unless literal?(segments[index])

        taken.push(segments[index])
        index += 1
      end
      taken.join("/")
    end

    def self.outermost(roots)
      found = []
      index = 0
      while index < roots.length
        found.push(roots[index]) unless held?(found, roots[index])
        index += 1
      end
      found
    end

    def self.held?(roots, path)
      index = 0
      while index < roots.length
        root = roots[index]
        return true if root == "" || path == root || path.start_with?("#{root}/")

        index += 1
      end
      false
    end

    # Every file under +root+, relative to the base. A hidden entry is passed
    # over and a symlinked directory is not descended: the first is what the
    # glob this replaces did, the second is what keeps a link back up the tree
    # from looping. A root nothing wrote answers empty rather than raising,
    # the way an include reaching nothing has always answered.
    #
    # Written against an explicit stack rather than recursing, the way
    # Pathname#find is: a method that both yields and calls itself through a
    # block is one Spinel has emitted as a walk that never descended.
    def self.under(base, root)
      start = root == "" ? base : base / root
      found = []
      return found unless start.directory?

      stack = [start]
      until stack.empty?
        here = stack.pop
        kids = here.children
        index = 0
        while index < kids.length
          child = kids[index]
          index += 1
          next if "#{child.basename}".start_with?(".")

          if child.directory?
            stack.push(child) unless child.symlink?
          else
            found.push("#{child.relative_path_from(base)}")
          end
        end
      end
      found
    end
  end
end
