require "pathname"
require "sumitsubo/place"
require "sumitsubo/finding"
require "sumitsubo/finding/repository"
require "sumitsubo/finding/report"
require "sumitsubo/mechanism"
require "sumitsubo/specification/repository"
require "sumitsubo/source/repository"

module Sumitsubo
  module Command
    # Write a specification the way a reference line is written, and say what
    # cannot be written that way without asking what the source does.
    #
    # It answers the half of a run that is about the specification alone, so a
    # reference line can be got right before anything is held to it. Nothing
    # here reaches the source tree: a signature is still read as the language
    # it names, because that is what says how the name is spelled, but no file
    # a specification covers is opened.
    #
    # A document is rewritten in place, which is the reference line itself, so
    # `--check` is what a run says the same thing with and changes nothing.
    # @command fmt
    class Fmt
      CHECK = "--check"

      def run(config, languages, parsers, checking)
        # With no root there is no reference line to check the shape of, which
        # is not a document written the wrong way either.
        unless config.root.directory?
          puts "no specification at #{Place.file(config.root)}; sumi init lays one down"
          return 2
        end

        findings = Finding::Repository.new
        specifications = Specification::Repository.new(parsers, Source::Repository.new(languages))
        Mechanism::ALL.each { |mechanism| asked(mechanism, config, findings, specifications, checking) }
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
      def asked(mechanism, config, findings, specifications, checking)
        # A specification the configuration switched off is one the project
        # does not keep, and a reference line nobody keeps is not one to hold
        # to a form.
        return unless config.verify?(mechanism.specification)

        mechanism.declared(config, specifications).each do |document|
          written(mechanism, document, findings, checking)
        end
      rescue Sumitsubo::Misshapen => e
        e.refusals.each { |one| findings.add(mechanism.refused(one)) }
      rescue Sumitsubo::Error => e
        findings.unreadable(e.message)
      end

      # What one document writes otherwise than a reference line is written,
      # answered as findings where the run is only to say so, and put in the
      # document's stead where it is to write it. A run that rewrote something
      # says which file, the way `init` says what it laid down.
      def written(mechanism, document, findings, checking)
        path = Pathname.new(document.path)
        lines = path.read.split("\n", -1)
        rewrites = mechanism.rewrites(document, lines)
        return if rewrites.empty?

        if checking
          rewrites.each { |one| findings.add(one.finding) }
        else
          rewrites.each { |one| lines[one.line - 1] = one.text }
          path.write(lines.join("\n"))
          puts "wrote #{Place.file(path)}"
        end
      end
    end
  end
end
