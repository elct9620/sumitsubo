require "sumitsubo/place"
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
        where = Place.file(seed.path)
        if seed.path.exist?
          puts "exists #{where}"
        else
          create(seed)
          puts "created #{where}"
        end
      end

      def create(seed)
        return seed.path.mkpath if seed.content.nil?

        seed.path.write(seed.content)
      end
    end
  end
end
