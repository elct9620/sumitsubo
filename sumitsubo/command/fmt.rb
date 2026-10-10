require "pathname"
require "sumitsubo/budget"
require "sumitsubo/finding/report"
require "sumitsubo/command/run"

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
        current = Run.new(config, languages, parsers)
        return 2 if current.rootless?

        measured = []
        current.each_mechanism do |mechanism|
          mechanism.declared(config, current.specifications).each do |document|
            written(config, mechanism, document, current.findings, checking)
            measured.push(document.path)
          end
        end
        budget = Budget.new(config.limit("sentence"), config.limit("paragraph"))
        measure(budget, current, measured) if budget.measures?
        Finding::Report.new(current.findings).lines.each { |line| puts line }
        current.findings.code
      end

      private

      # Every document a mechanism kept, measured as it now stands. Nothing a
      # budget finds can be written for a person, so the run that writes
      # answers it as the run that only says so does.
      def measure(budget, current, paths)
        answered = current.specifications.blocks_of(paths, budget)
        paths.each do |path|
          budget.over(path, answered[path]).each { |one| current.findings.add(one) }
        end
      end

      # What one document writes otherwise than a reference line is written,
      # answered as findings where the run is only to say so, and put in the
      # document's stead where it is to write it. A run that rewrote something
      # says which file, the way `init` says what it laid down.
      def written(config, mechanism, document, findings, checking)
        path = Pathname.new(document.path)
        lines = path.read.split("\n", -1)
        rewrites = mechanism.rewrites(config, document, lines)
        return if rewrites.empty?

        if checking
          rewrites.each { |one| findings.add(one.finding) unless one.finding.nil? }
        else
          rewrites.each { |one| lines[one.line - 1] = one.text }
          path.write(lines.join("\n"))
          puts "wrote #{path}"
        end
      end
    end
  end
end
