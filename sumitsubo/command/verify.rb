require "pathname"
require "sumitsubo/report"
require "sumitsubo/mechanism"

module Sumitsubo
  module Command
    # Verify the source code is aligned with the verifiable specification.
    #
    # Everything goes to stdout, findings and failures alike: the test harness
    # compares the two streams merged, and they are buffered differently, so
    # splitting them would leave their order unstable.
    class Verify
      def run(config)
        # With no root there is no reference line at all to verify from, which
        # is not a difference between the two sides either.
        unless config.root.directory?
          puts "no specification at #{config.root.relative_path_from(Pathname.pwd)}"
          return 2
        end

        report = Report.new
        Mechanism::ALL.each do |mechanism|
          # A specification the configuration switched off is never read, so the
          # code it covers answers nothing rather than answering clean.
          next unless config.verify?(mechanism.specification)

          mechanism.verify(config, report)
        end
        report.answer
      end
    end
  end
end
