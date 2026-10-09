require "sumitsubo/finding/report"
require "sumitsubo/command/run"

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
        current = Run.new(config, languages, parsers)
        return 2 if current.rootless?

        # Every relation is kept before any check reads one: a vocabulary
        # covers what the specifications beside it reach.
        current.relate(Mechanism::ALL)
        current.each_mechanism do |mechanism|
          mechanism.verify(config, current.findings, current.specifications, current.source, current.relations)
        end
        current.declare(current.switched_on)
        current.resolve
        Finding::Report.new(current.findings).lines.each { |line| puts line }
        current.findings.code
      end
    end
  end
end
