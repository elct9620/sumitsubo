require "sumitsubo/patterns"

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
  # The walk is this tool's rather than the glob's: one traversal answers
  # every pattern rather than one traversal each, and a directory the project
  # excluded is never looked inside.
  #
  # This compiler's glob would not have served either — a `*` between two
  # separators, which a workspace pattern is written with, answers nothing and
  # raises nothing. That is a defect rather than what a glob is, so it is a
  # sentence to drop once it answers, not a second reason for the walk.
  module Scope
    # An include covering no file, and the line of the specification that
    # wrote it. Built by the mechanism rather than here: how a format spells
    # an include is the parser's to answer, and the walk reads no
    # specification.
    Barren = Struct.new(:path, :pattern, :line)

    def self.of(base, patterns, exclusion)
      found = []
      candidates = walk(base, patterns, exclusion).paths
      patterns.each do |pattern|
        selected(pattern, candidates).each { |path| found.push(path) }
      end
      found
    end

    # Which of these patterns covers no file. Only the patterns: where one was
    # written is the specification's to answer, and the walk never opens one.
    #
    # An excluded directory is never walked into, so a pattern reaching only
    # what the project excluded reaches nothing here. What tells the two apart
    # is whether any directory the walk refused stands on the pattern's own
    # path: a pattern nothing matches is one nobody can have meant, while one
    # whose files the project took away is the project getting what it asked
    # for.
    def self.barren(base, patterns, exclusion)
      walked = walk(base, patterns, exclusion)
      found = []
      patterns.each do |pattern|
        next unless selected(pattern, walked.paths).empty?
        next if refused?(walked.pruned, root_of(pattern))

        found.push(pattern)
      end
      found
    end

    # Whether any directory the walk refused stands on this pattern's path,
    # either above its root or under it.
    def self.refused?(pruned, root)
      pruned.any? do |gone|
        root == "" || root == gone || root.start_with?("#{gone}/") || gone.start_with?("#{root}/")
      end
    end

    # Nothing was read where the specification says something should have
    # been, and a run that says nothing about it reads exactly like agreement.
    def self.describe(barren)
      "include #{barren.pattern} covers no file; " \
      "the pattern is wrong or what it pointed at is gone"
    end

    # What the walk found and what it refused to look inside. A pattern with
    # no wildcard names one file and is answered by asking whether it is
    # there; the rest are answered by walking, and only from the directory
    # each names before its first wildcard.
    Found = Struct.new(:paths, :pruned)

    def self.walk(base, patterns, exclusion)
      paths = []
      patterns.each do |pattern|
        next unless literal?(pattern) && (base / pattern).file?

        paths.push(pattern) unless Patterns.excludes?(exclusion, pattern)
      end
      pruned = []
      roots_in(patterns).each do |root|
        found = under(base, root, exclusion, pruned)
        found.each { |path| paths.push(path) }
      end
      Found.new(paths.uniq, pruned)
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
      pattern.split("/").take_while { |segment| literal?(segment) }.join("/")
    end

    # Answered against what has been kept rather than against every root, so
    # a root under one already taken is passed over. The roots arrive sorted,
    # which is what puts the one holding another ahead of it.
    def self.outermost(roots)
      found = []
      roots.each { |root| found.push(root) unless held?(found, root) }
      found
    end

    def self.held?(roots, path)
      roots.any? { |root| root == "" || path == root || path.start_with?("#{root}/") }
    end

    # Every file under +root+, relative to the base. A hidden entry is passed
    # over and a symlinked directory is not descended: the first is what the
    # glob this replaces did, the second is what keeps a link back up the tree
    # from looping. A root nothing wrote answers empty rather than raising,
    # the way an include reaching nothing has always answered.
    def self.under(base, root, exclusion, pruned)
      start = root == "" ? base : base / root
      found = []
      return found unless start.directory?

      start.children.each do |child|
        next if "#{child.basename}".start_with?(".")

        where = "#{child.relative_path_from(base)}"
        if child.directory?
          # Refusing the directory rather than its files is the whole of why
          # this is cheap: a build tree is not walked at all rather than
          # walked and then thrown away.
          if Patterns.excludes_directory?(exclusion, where)
            pruned.push(where)
          elsif !child.symlink?
            found.concat(under(base, where, exclusion, pruned))
          end
        elsif !Patterns.excludes?(exclusion, where)
          found.push(where)
        end
      end
      found
    end
  end
end
