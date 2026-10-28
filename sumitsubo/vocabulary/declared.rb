require "pathname"
require "sumitsubo/error"
require "sumitsubo/place"
require "sumitsubo/check"
require "sumitsubo/source/scope"

module Sumitsubo
  # What a vocabulary declares, and how it is read.
  #
  # Reading it can fail in a way that is not a difference between the
  # specification and the code: with no file, or an unreadable one, there is
  # no reference line to verify from at all.
  #
  # A module beside Mechanism::Glossary rather than its class methods: Spinel
  # 2026.09.12 cannot type a class method's parameter where another shares its
  # name. Master 7232a802 can, so fold these in once the pin moves past it.
  module Vocabulary
    FILE = "glossary.md"

    # What a project starts a vocabulary from. A title and nothing else is a
    # vocabulary that checks nothing, which is what a root nobody has written
    # words for should say.
    SEED = <<~MARKDOWN
      # Glossary

      The words this project keeps, and the ones it turns down in their place.
    MARKDOWN

    class Error < Sumitsubo::Error; end

    # Where the vocabulary is kept, refused where nobody wrote one. A missing
    # glossary is not a difference between a specification and the code — there
    # is no reference line to verify from — and this is the one place that knows
    # a run without one has something to lay down.
    def self.at(path, from)
      file = Pathname.new(path)
      raise Error, "no glossary at #{Place.file(file, from)}; sumi init lays one down" unless file.exist?

      path
    end

    # One line a rejection does not answer for, as the specification wrote it,
    # with what it takes to say so where it sits.
    Ignore = Data.define(:line, :at, :term, :used)

    # The mechanism names its own file; where the root sits is the tool's to
    # say, so it arrives as an argument.
    def self.path_in(root)
      Pathname.new(root) / FILE
    end

    # A file's effective vocabulary is every section covering it laid over the
    # ones before it, in the order the specification lists them, a later term
    # replacing an earlier one of the same name outright — the words it rejects
    # included, since a term meaning something else here rejects different
    # words. Order is all that decides which way the laying goes, which is why
    # the sections share one specification: the order is written in it.
    #
    # A specification beside the vocabulary is covered wherever a file its own
    # includes reach is, so it speaks the words of the subdomain it answers for
    # without the vocabulary listing it.
    def self.scope(spec, base, exclusion, reached)
      effective = {}
      spec.statements.each do |section|
        covering(section, reached, base, exclusion).each do |path|
          effective[path] = laid_over(effective[path], section.statements)
        end
      end
      effective
    end

    # What one section covers: the files its globs match, and each
    # specification beside it reaching any of them.
    def self.covering(section, reached, base, exclusion)
      found = paths_for(section, base, exclusion)
      matched = {}
      found.each { |path| matched[path] = true }
      reached.keys.each do |file|
        found.push(file) if reached[file].any? { |path| matched[path] }
      end
      found.uniq.sort
    end

    # A path as a section's globs are written, relative to the base, where a
    # specification and the run keep it relative to where the run started.
    def self.from_base(path, base, from)
      "#{(from / path).cleanpath.relative_path_from(Pathname.new(base).expand_path)}"
    end

    # The files each specification beside the vocabulary reaches, read back
    # from the run and held under that specification's own path, both relative
    # to the base the way a section's are.
    def self.reaches(beside, base, relations, from)
      found = {}
      beside.each do |spec|
        reached = relations.reached_from(spec.path).map { |file| from_base(file, base, from) }
        found[from_base(spec.path, base, from)] = reached
      end
      found
    end

    # One section's terms laid over what a path already had, a later term of
    # the same name replacing an earlier one outright.
    def self.laid_over(terms, statements)
      laid = terms.nil? ? {} : terms
      statements.each { |term| laid[term.key] = term }
      laid
    end

    # Every line the specification spells a word on, whether as a term or as
    # one a term rejects. Both spellings declare, and neither uses.
    def self.declared_in(spec)
      spelled = {}
      spec.statements.each { |section| section.statements.each { |term| spells(term, spelled) } }
      spelled
    end

    # The lines one term spells a word on: its own, and each word it rejects.
    def self.spells(term, spelled)
      spelled["#{term.line} #{term.key}"] = true
      term.statements.each { |word| spelled["#{word.line} #{word.key}"] = true }
    end

    # Every mention the specification sets aside by hand, under the key that
    # mention answers at. An ignore names one line and no more: which term is
    # rejecting and which word it rejects come from where it sits, so neither
    # can be written wrong.
    def self.set_aside(spec)
      found = {}
      spec.statements.each { |section| section.statements.each { |term| sets_aside(term, found) } }
      found
    end

    # Every line one term sets aside, under the key the mention it answers to
    # is held by.
    def self.sets_aside(term, found)
      term.statements.each do |entry|
        entry.statements.each do |ignore|
          found["#{term.key} #{entry.key} #{ignore.key}"] =
            Ignore.new(line: ignore.line, at: ignore.key, term: term.key, used: entry.key)
        end
      end
    end

    # Every include the vocabulary writes, asked about at once: they are
    # written in one file, and a pattern two sections share is one mistake
    # rather than two. One section reaching nothing takes its whole vocabulary
    # out of the run, and the words it carries are then checked nowhere.
    def self.covers(spec, path)
      found = []
      seen = {}
      spec.statements.each { |section| found.concat(unseen(section, seen)) }
      [Check::Covers.new(path: path, includes: found)]
    end

    # The includes one section adds that an earlier one has not already named,
    # marking each as seen. A glob two sections share is one mistake, so the
    # first to write it is where a reader is sent.
    def self.unseen(section, seen)
      found = []
      section.includes.each do |one|
        next unless seen[one.key].nil?

        seen[one.key] = true
        found.push(one)
      end
      found
    end

    # A found path is a String relative to the base: these are the keys a
    # file's vocabulary is held under, and check composes each back onto the
    # base to read it.
    #
    # A section's boundary is the section's own, since which vocabulary holds
    # where another says nothing is decided by what each covers.
    def self.paths_for(section, base, exclusion)
      globs = section.includes.map { |one| one.key }
      Source::Scope.of(base, globs, exclusion).uniq.sort
    end
  end
end
