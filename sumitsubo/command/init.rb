require "pathname"
require "sumitsubo/where"
require "sumitsubo/mechanism"

module Sumitsubo
  module Command
    # Lay down an empty specification to start a reference line from.
    # @command init
    class Init
      def run(config)
        config.root.mkpath
        Mechanism::ALL.each { |mechanism| lay_down(mechanism.seed(config.root)) }
        0
      end

      private

      # Laying down what is already there would overwrite a reference line, so
      # what exists is reported rather than replaced.
      def lay_down(seed)
        where = Where.of(seed.path)
        if File.exist?(seed.path)
          puts "exists #{where}"
        else
          create(seed)
          puts "created #{where}"
        end
      end

      def create(seed)
        return Pathname.new(seed.path).mkpath if seed.content.nil?

        File.write(seed.path, seed.content)
      end
    end
  end
end
