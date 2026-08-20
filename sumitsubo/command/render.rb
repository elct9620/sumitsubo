require "pathname"
require "sumitsubo/where"
require "sumitsubo/mechanism"

module Sumitsubo
  module Command
    # Render the structured specification to the markdown specification.
    #
    # A document is derived, so a run replaces what the last one wrote. What
    # Init refuses to overwrite is a reference line; this is not one.
    class Render
      def run(config)
        failures = []
        Mechanism::ALL.each do |mechanism|
          next unless config.render?(mechanism.specification)

          # One mechanism that cannot be read leaves the others still able to
          # write, the way a linter reports every file it managed to parse.
          begin
            mechanism.documents(config).each { |document| write(document) }
          rescue Sumitsubo::Error => e
            failures.push(e.message)
          end
        end
        failures.sort.each { |message| puts message }
        failures.empty? ? 0 : 2
      end

      private

      def write(document)
        path = Pathname.new(document.path)
        path.dirname.mkpath
        File.write(path.to_s, document.content)
        puts "rendered #{Where.of(path.to_s)}"
      end
    end
  end
end
