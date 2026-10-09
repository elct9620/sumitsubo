require "sumitsubo/check"
require "sumitsubo/place"
require "sumitsubo/relation"
require "sumitsubo/source/scope"

module Sumitsubo
  # The files each specification reaches: what its includes cover, less what
  # the project excludes. An include is the boundary of what a specification
  # answers for, so a statement is witnessed or implemented only by the files
  # its own specification reaches. Worked out once for every mechanism and kept
  # as relations, so whoever asks after reads the same answer.
  module Reach
    def self.keep(specifications, base, exclusion, relations)
      specifications.each do |spec|
        globs = spec.includes.map { |one| one.key }
        Source::Scope.of(base, globs, exclusion).each do |path|
          relations.add(Relation.reach(spec.path, Place.file(base / path)))
        end
      end
    end

    # Each specification's files as a set, read back from the run: what is
    # asked of a claim is whether it sits in there, once per claim.
    def self.of(specifications, relations)
      found = {}
      specifications.each do |spec|
        files = {}
        relations.reached_from(spec.path).each { |file| files[file] = true }
        found[spec.path] = files
      end
      found
    end

    # Every file any of them reaches, which is what gets read. One file
    # answering for two specifications is read once and asked about twice.
    def self.files(reach)
      found = []
      reach.keys.each { |spec| found.concat(reach[spec].keys) }
      found.uniq.sort
    end

    # What each specification's includes cover, each answering at the
    # specification that wrote them.
    def self.covers(specifications)
      specifications.map { |one| Check::Covers.new(path: one.path, includes: one.includes) }
    end
  end
end
