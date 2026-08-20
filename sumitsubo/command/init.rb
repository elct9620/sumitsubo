require "pathname"
require "sumitsubo/mechanism"

module Sumitsubo
  module Command
    # Lay down an empty specification to start a reference line from.
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
        shown = "#{Pathname.new(seed.path).relative_path_from(Pathname.pwd)}"
        if File.exist?(seed.path)
          puts "exists #{shown}"
        else
          create(seed)
          puts "created #{shown}"
        end
      end

      def create(seed)
        return Pathname.new(seed.path).mkpath if seed.content.nil?

        File.write(seed.path, seed.content)
      end
    end
  end
end
