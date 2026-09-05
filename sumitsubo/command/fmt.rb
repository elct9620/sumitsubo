require "sumitsubo/place"
require "sumitsubo/finding"
require "sumitsubo/finding/repository"
require "sumitsubo/finding/report"
require "sumitsubo/mechanism"
require "sumitsubo/specification/repository"
require "sumitsubo/source/repository"

module Sumitsubo
  module Command
    # Check that a specification is written the way a reference line is
    # written, without asking what the source does.
    #
    # It answers the half of a run that is about the specification alone, so a
    # reference line can be got right before anything is held to it. Nothing
    # here reaches the source tree: a signature is still read as the language
    # it names, because that is what says how the name is spelled, but no file
    # a specification covers is opened.
    # @command fmt
    class Fmt
      def run(config, languages, parsers)
        # With no root there is no reference line to check the shape of, which
        # is not a document written the wrong way either.
        unless config.root.directory?
          puts "no specification at #{Place.file(config.root)}; sumi init lays one down"
          return 2
        end

        findings = Finding::Repository.new
        specifications = Specification::Repository.new(parsers, Source::Repository.new(languages))
        Mechanism::ALL.each { |mechanism| asked(mechanism, config, findings, specifications) }
        # A document read beside others never reached the mechanism that asked
        # for it, so its refusal is answered here rather than there.
        specifications.unread.each { |one| findings.add(one) }
        Finding::Report.new(findings).lines.each { |line| puts line }
        findings.code
      end

      private

      # What one mechanism says about its own specification. One that cannot be
      # read leaves the others still able to answer, the way a linter reports
      # every file it managed to parse.
      #
      # The two refusals are named apart because Spinel gives one name one type
      # across both clauses, and `refused` would arrive as the wider of them
      # with no place to answer at. Reported 2026-09-05.
      def asked(mechanism, config, findings, specifications)
        # A specification the configuration switched off is one the project
        # does not keep, and a reference line nobody keeps is not one to hold
        # to a form.
        return unless config.verify?(mechanism.specification)

        mechanism.declared(config, specifications)
      rescue Sumitsubo::Misshapen => refused
        findings.add(mechanism.refused(refused))
      rescue Sumitsubo::Error => unread
        findings.unreadable(unread.message)
      end
    end
  end
end
