require "sumitsubo/where"
require "sumitsubo/report"
require "sumitsubo/mechanism"

module Sumitsubo
  module Command
    # Verify the source code is aligned with the verifiable specification.
    #
    # Everything goes to stdout, findings and failures alike: the test harness
    # compares the two streams merged, and they are buffered differently, so
    # splitting them would leave their order unstable.
    # @command verify
    class Verify
      def run(config, languages, parsers)
        # With no root there is no reference line at all to verify from, which
        # is not a difference between the two sides either.
        unless config.root.directory?
          puts "no specification at #{Where.of(config.root)}; sumi init lays one down"
          return 2
        end

        report = Report.new
        Mechanism::ALL.each do |mechanism|
          # A specification the configuration switched off is never read, so the
          # code it covers answers nothing rather than answering clean.
          next unless config.verify?(mechanism.specification)

          # One mechanism that cannot be read leaves the others still able to
          # answer, the way a linter reports every file it managed to parse.
          # What it compares is its own, so what it could not compare is too.
          begin
            mechanism.verify(config, report, languages, parsers)
          rescue Sumitsubo::Error => e
            report.unreadable(e.message)
          end
        end
        report.answer
      end
    end
  end
end
